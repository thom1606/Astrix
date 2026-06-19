//
//  PortUtilities.swift
//  Astrix
//
//  TCP readiness probe used by the launch sequencer: "wait until this port accepts
//  connections before running the next action" — a more reliable gate than a fixed
//  delay (e.g. wait for the database before starting the app server).
//

import Foundation
import Darwin

enum PortUtilities {
    /// Whether something is accepting TCP connections for `localhost:port`.
    ///
    /// Resolves `localhost` the way a browser does — to both `127.0.0.1` (IPv4) and `::1`
    /// (IPv6) — and tries each. This matters because dev servers (Vite, Node, …) often
    /// bind `localhost` to **IPv6 `::1` only**, so an IPv4-only probe would miss them and
    /// the readiness gate would wrongly time out. Localhost refuses instantly when nothing
    /// is listening, so this stays fast.
    static func isPortOpen(_ port: Int) -> Bool {
        guard port > 0, port <= 65535 else { return false }

        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC        // IPv4 and IPv6
        hints.ai_socktype = SOCK_STREAM

        var resolved: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo("localhost", String(port), &hints, &resolved) == 0 else { return false }
        defer { freeaddrinfo(resolved) }

        var candidate = resolved
        while let address = candidate {
            let socketFD = socket(address.pointee.ai_family, address.pointee.ai_socktype, address.pointee.ai_protocol)
            if socketFD >= 0 {
                let connected = connect(socketFD, address.pointee.ai_addr, address.pointee.ai_addrlen) == 0
                close(socketFD)
                if connected { return true }
            }
            candidate = address.pointee.ai_next
        }
        return false
    }

    /// Poll until the port is open or `timeout` elapses. Returns `true` if it opened.
    /// Runs off the main thread (called from the launch `Task`).
    static func waitUntilOpen(_ port: Int, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isPortOpen(port) { return true }
            try? await Task.sleep(for: .milliseconds(250))
        }
        return isPortOpen(port)
    }

    /// Force-free a TCP port by terminating whatever is listening on it — for the
    /// "Kill Port" action and recovering from a server left running outside Astrix.
    /// SIGTERMs the holders, then SIGKILLs any that linger. A no-op (silently) when the
    /// port is already free.
    static func killProcesses(onPort port: Int) {
        guard port > 0, port <= 65535 else { return }
        let pids = listeningPIDs(onPort: port)
        guard !pids.isEmpty else { return }
        for pid in pids { kill(pid, SIGTERM) }
        usleep(300_000)
        for pid in listeningPIDs(onPort: port) { kill(pid, SIGKILL) }
    }

    /// PIDs with a TCP socket bound to `port`, found via the `libproc` API.
    ///
    /// Deliberately not `lsof`: `lsof` scans every process and attempts `task_for_pid`
    /// on each, logging noisy "Unable to obtain a task name port right" warnings for
    /// system processes it can't inspect. `libproc` just returns an error for those
    /// (which we skip), so it's silent, faster, and needs no subprocess.
    private static func listeningPIDs(onPort port: Int) -> [pid_t] {
        let targetPort = in_port_t(port).bigEndian   // sockets store the port network-order

        let probe = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard probe > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(probe) / MemoryLayout<pid_t>.size + 16)
        let listed = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard listed > 0 else { return [] }
        let pidCount = Int(listed) / MemoryLayout<pid_t>.size

        var result = Set<pid_t>()
        for index in 0..<pidCount where pids[index] > 0 {
            if processHoldsPort(pids[index], port: targetPort) { result.insert(pids[index]) }
        }
        return Array(result)
    }

    /// Whether `pid` owns a TCP socket whose local port matches `targetPort` (already in
    /// network byte order). Returns `false` for processes we can't inspect.
    private static func processHoldsPort(_ pid: pid_t, port targetPort: in_port_t) -> Bool {
        let bufferSize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        guard bufferSize > 0 else { return false }
        var fds = [proc_fdinfo](repeating: proc_fdinfo(), count: Int(bufferSize) / MemoryLayout<proc_fdinfo>.size + 8)
        let got = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, &fds, Int32(fds.count * MemoryLayout<proc_fdinfo>.size))
        guard got > 0 else { return false }
        let fdCount = Int(got) / MemoryLayout<proc_fdinfo>.size

        for index in 0..<fdCount where fds[index].proc_fdtype == UInt32(PROX_FDTYPE_SOCKET) {
            var info = socket_fdinfo()
            let size = proc_pidfdinfo(pid, fds[index].proc_fd, PROC_PIDFDSOCKETINFO, &info, Int32(MemoryLayout<socket_fdinfo>.size))
            guard size > 0, info.psi.soi_kind == SOCKINFO_TCP else { continue }
            if UInt16(truncatingIfNeeded: info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport) == targetPort {
                return true
            }
        }
        return false
    }
}
