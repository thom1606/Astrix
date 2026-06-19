//
//  Scripting.swift
//  Astrix
//
//  Sandboxed Finder extensions can't launch other apps directly (NSWorkspace is
//  blocked). Astrix uses the Application Scripts escape hatch: the containing app
//  installs a small AppleScript into the extension's `Application Scripts`
//  directory, and the extension runs it via `NSUserAppleScriptTask` to execute
//  shell commands (e.g. `open -b <bundle-id> <path>`) outside the sandbox.
//

import Foundation
import Carbon

final class Scripting {
    static let shared = Scripting()

    // MARK: - Containing app side

    /// The Finder extension's `Application Scripts` directory. Reachable from the
    /// containing app because it embeds the extension. Created if missing.
    private func finderExtensionScriptsURL() throws -> URL {
        guard var dir = try? FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            throw NSError(domain: "AstrixScripting", code: 1, userInfo: [NSLocalizedDescriptionKey: "Scripts folder couldn't be created."])
        }
        // Up from this app's own scripts dir to the shared `Application Scripts`
        // root, then into the extension's directory.
        dir.deleteLastPathComponent()
        let extensionDir = dir.appendingPathComponent(Constants.BundleID.finderExtension)
        if !FileManager.default.fileExists(atPath: extensionDir.path) {
            try FileManager.default.createDirectory(at: extensionDir, withIntermediateDirectories: true)
        }
        return extensionDir
    }

    /// Install or refresh the helper script. Call from the main (containing) app on
    /// launch. Only rewrites when the contents differ.
    func updateSystemScripts() throws {
        let toolsURL = try finderExtensionScriptsURL()
            .appendingPathComponent(Constants.Scripting.toolsFileName)
            .appendingPathExtension(Constants.Scripting.toolsFileExtension)
        let script = """
            on runCommand(command)
                do shell script command
            end runCommand
            """
        if let existing = try? String(contentsOf: toolsURL, encoding: .utf8), existing == script {
            return
        }
        try script.write(to: toolsURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Extension side

    /// The helper script URL inside this process's own `Application Scripts`
    /// directory. Call from the extension.
    func scriptURL(name: String) -> URL? {
        guard let dir = try? FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            return nil
        }
        return dir.appendingPathComponent(name).appendingPathExtension(Constants.Scripting.toolsFileExtension)
    }

    /// Build the AppleEvent that invokes a script handler with a single string arg.
    func scriptEvent(functionName: String, _ parameter: String) -> NSAppleEventDescriptor {
        let parameters = NSAppleEventDescriptor.list()
        parameters.insert(NSAppleEventDescriptor(string: parameter), at: 0)

        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kASAppleScriptSuite),
            eventID: AEEventID(kASSubroutineEvent),
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        event.setDescriptor(NSAppleEventDescriptor(string: functionName), forKeyword: AEKeyword(keyASSubroutineName))
        event.setDescriptor(parameters, forKeyword: AEKeyword(keyDirectObject))
        return event
    }
}
