//
//  ManagedProcess.swift
//  Astrix
//
//  One tracked workspace process. Astrix spawns the command in its OWN Unix process
//  group (via posix_spawn + POSIX_SPAWN_SETPGROUP) so it can later kill the entire
//  tree — `bin/dev` → foreman → ruby/node — with a single `kill(-pgid, …)`, which is
//  what actually frees the port. Foundation's `Process` can't do this (it has no
//  process-group API and `terminate()` only signals the direct child), so we drive
//  posix_spawn directly.
//
//  Output is streamed to a per-run log file. Exit is observed via a kqueue process
//  source; the zombie is reaped with `waitpid`. Main app only (non-sandboxed).
//

import Foundation
import Observation
import Darwin

@MainActor
@Observable
final class ManagedProcess: Identifiable {
    enum Status: Equatable {
        case running
        case stopping
        case exited(Int32)   // exit code (128 + signal when killed)
        case failed(String)  // never started
    }

    enum LaunchError: LocalizedError {
        case missingDirectory(String)
        case spawnFailed(Int32)

        var errorDescription: String? {
            switch self {
            case .missingDirectory(let dir): return "Working directory doesn't exist: \(dir)"
            case .spawnFailed(let code):      return "Couldn't start the process (error \(code))."
            }
        }
    }

    let id = UUID()
    /// The workspace action that started this process — lets the runner avoid
    /// double-starting a service that's already running (the idempotent port fix).
    let actionID: UUID
    /// Friendly name shown in the menu bar submenu.
    let label: String
    /// Owning workspace's name, for readable crash notifications.
    let workspaceName: String
    let command: String
    let workingDirectory: String
    /// The file this process's stdout/stderr is streamed to.
    let logURL: URL

    private(set) var startedAt = Date()
    private(set) var status: Status = .running
    /// Process-group id (== leader pid). Negated to signal the whole group.
    private(set) var pid: pid_t = -1

    /// Called on the main actor when the process exits. `userInitiated` is `true` for a
    /// user Stop, `false` for an unexpected exit (drives the crash notification).
    @ObservationIgnored var onExit: ((_ userInitiated: Bool, _ status: Status) -> Void)?

    @ObservationIgnored private var exitSource: DispatchSourceProcess?
    @ObservationIgnored private var outputPipe: Pipe?
    @ObservationIgnored private var userInitiatedStop = false
    @ObservationIgnored private var hasExited = false
    @ObservationIgnored private var exitWaiters: [CheckedContinuation<Void, Never>] = []
    /// Keeps the instance alive from launch until exit, even when nothing else holds it
    /// (fire-and-forget tasks). Cleared on exit to break the cycle.
    @ObservationIgnored private var selfRetain: ManagedProcess?

    init(
        actionID: UUID,
        label: String,
        workspaceName: String,
        command: String,
        workingDirectory: String,
        logURL: URL
    ) {
        self.actionID = actionID
        self.label = label
        self.workspaceName = workspaceName
        self.command = command
        self.workingDirectory = workingDirectory
        self.logURL = logURL
    }

    // MARK: - Launch

    /// Spawn the command in a new process group with stdout/stderr streamed to the log
    /// file. Throws before any process exists if the working directory is invalid or
    /// the spawn fails.
    func start() throws {
        let dir = (workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).expandingTildeInPath
        try validate(directory: dir)

        // Prepare the log file and a writer the reader queue appends to.
        try FileManager.default.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        let sink = try FileHandle(forWritingTo: logURL)

        // Run the login shell in the right directory. `cd` (rather than a spawn chdir
        // file-action) keeps us off the macOS-26-deprecated `_np` API.
        let fullCommand = dir.isEmpty ? command : "cd \(Self.shellQuoted(dir)) && \(command)"

        let pipe = Pipe()
        do {
            pid = try Self.spawnGroup(shellCommand: fullCommand, pipe: pipe)
        } catch {
            try? sink.close()
            throw error
        }

        startedAt = Date()
        status = .running
        outputPipe = pipe
        selfRetain = self

        // The parent must close its write end so EOF arrives when the child group dies.
        try? pipe.fileHandleForWriting.close()
        beginLogging(reading: pipe, into: sink)
        observeExit(of: pid)
    }

    private func validate(directory dir: String) throws {
        guard !dir.isEmpty else { return }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw LaunchError.missingDirectory(dir)
        }
    }

    /// posix_spawn the user's login shell as `-i -l -c <command>` in a NEW process group
    /// (so the whole tree can later be killed via the negated pgid), with stdin detached
    /// and stdout+stderr wired into `pipe`. Returns the leader pid (== group id).
    ///
    /// Runs the user's actual login shell (zsh or bash) interactive + login, so it
    /// sources the same files their terminal does — crucially `~/.zshrc` / `~/.bashrc`,
    /// where version managers (mise/rbenv/nvm) activate. `-i` is the key flag: a
    /// non-interactive `-lc` shell skips the rc file, so commands fall back to system
    /// Ruby/Node and fail (e.g. `bin/dev` hitting gem-install permission errors).
    private static func spawnGroup(shellCommand: String, pipe: Pipe) throws -> pid_t {
        let writeFD = pipe.fileHandleForWriting.fileDescriptor
        let readFD = pipe.fileHandleForReading.fileDescriptor

        var attributes = posix_spawnattr_t(nil as OpaquePointer?)
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP))
        posix_spawnattr_setpgroup(&attributes, 0)   // leader pid == group id

        var fileActions = posix_spawn_file_actions_t(nil as OpaquePointer?)
        posix_spawn_file_actions_init(&fileActions)
        defer { posix_spawn_file_actions_destroy(&fileActions) }
        // Detach stdin from the GUI app; merge stdout+stderr into the pipe.
        posix_spawn_file_actions_addopen(&fileActions, 0, "/dev/null", O_RDONLY, 0)
        posix_spawn_file_actions_adddup2(&fileActions, writeFD, 1)
        posix_spawn_file_actions_adddup2(&fileActions, writeFD, 2)
        posix_spawn_file_actions_addclose(&fileActions, writeFD)
        posix_spawn_file_actions_addclose(&fileActions, readFD)

        let shell = Self.loginShell
        let arguments = [shell, "-i", "-l", "-c", shellCommand]
        var argv: [UnsafeMutablePointer<CChar>?] = arguments.map { strdup($0) }
        argv.append(nil)
        defer { for pointer in argv where pointer != nil { free(pointer) } }

        var spawnedPID: pid_t = 0
        let result = posix_spawn(&spawnedPID, shell, &fileActions, &attributes, argv, environ)
        guard result == 0 else { throw LaunchError.spawnFailed(result) }
        return spawnedPID
    }

    /// The user's login shell from the password database — what `chsh` sets and what
    /// Terminal launches, so a zsh user gets `~/.zshrc` and a bash user gets `~/.bashrc`.
    /// Falls back to `$SHELL`, then `/bin/zsh`.
    private static var loginShell: String {
        if let entry = getpwuid(getuid()), let shellPath = entry.pointee.pw_shell {
            let path = String(cString: shellPath)
            if !path.isEmpty { return path }
        }
        if let envShell = ProcessInfo.processInfo.environment["SHELL"], !envShell.isEmpty {
            return envShell
        }
        return "/bin/zsh"
    }

    /// Drain output into the log on a background queue (never leave a pipe unread — a
    /// full buffer would deadlock a chatty server).
    private func beginLogging(reading pipe: Pipe, into sink: FileHandle) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                try? sink.close()
            } else {
                try? sink.write(contentsOf: data)
            }
        }
    }

    /// Watch for exit, reap the zombie with `waitpid`, then report on the main actor.
    private func observeExit(of processID: pid_t) {
        let source = DispatchSource.makeProcessSource(identifier: processID, eventMask: .exit, queue: .global())
        source.setEventHandler { [weak self] in
            var rawStatus: Int32 = 0
            waitpid(processID, &rawStatus, 0)
            let code = Self.exitCode(from: rawStatus)
            source.cancel()
            Task { @MainActor in self?.handleExit(code: code) }
        }
        exitSource = source
        source.resume()
    }

    // MARK: - Stop

    /// Gracefully stop the whole process group (SIGTERM), escalating to SIGKILL if it
    /// hasn't exited after a grace period.
    func stop() {
        guard pid > 0, status == .running else {
            if status == .stopping { return }
            return
        }
        userInitiatedStop = true
        status = .stopping
        signalGroup(SIGTERM)

        let groupPID = pid
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, self.status == .stopping else { return }   // already exited → don't risk PID reuse
            kill(-groupPID, SIGKILL)
        }
    }

    /// Send a signal to the entire process group. Used by the app-quit teardown.
    func signalGroup(_ signal: Int32) {
        guard pid > 0 else { return }
        kill(-pid, signal)
    }

    /// Suspend until the process exits (used by `.task` actions with "wait for exit").
    func waitUntilExit() async {
        if hasExited { return }
        await withCheckedContinuation { continuation in
            exitWaiters.append(continuation)
        }
    }

    // MARK: - Exit handling

    private func handleExit(code: Int32) {
        guard !hasExited else { return }
        hasExited = true
        let wasUserInitiated = userInitiatedStop
        status = .exited(code)
        exitSource = nil
        // Leave `outputPipe` alone — the reader drains the last bytes and closes on EOF.
        // It's released when this instance deallocs (after `selfRetain` is cleared).

        let waiters = exitWaiters
        exitWaiters.removeAll()
        for waiter in waiters { waiter.resume() }

        onExit?(wasUserInitiated, status)
        selfRetain = nil
    }

    // MARK: - Helpers

    /// Single-quote a path for safe interpolation into the shell command.
    private static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Translate a `waitpid` raw status into a display exit code (mirrors the
    /// `WIFEXITED`/`WEXITSTATUS`/`WTERMSIG` macros, which aren't exposed to Swift).
    private static func exitCode(from rawStatus: Int32) -> Int32 {
        if (rawStatus & 0x7f) == 0 {
            return (rawStatus >> 8) & 0xff   // normal exit
        }
        return 128 + (rawStatus & 0x7f)      // terminated by signal
    }
}
