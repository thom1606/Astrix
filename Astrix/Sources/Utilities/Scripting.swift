//
//  Scripting.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import Foundation
import Carbon
import Cocoa

class Scripting {
    public static let shared = Scripting()

    private func getFinderExScriptPath() throws -> URL {
        guard var scriptFolderPath = try? FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            throw NSError(domain: "AstrixScriptingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Scripts folder couldn't be created!"])
        }
        scriptFolderPath.deleteLastPathComponent()
        let finderExScriptPath = scriptFolderPath.appendingPathComponent(Constants.Id.FinderExtension)
        if !FileManager.default.fileExists(atPath: finderExScriptPath.path) {
            try FileManager.default.createDirectory(atPath: finderExScriptPath.path, withIntermediateDirectories: true, attributes: nil)
        }
        return finderExScriptPath
    }

    public func updateSystemScripts() throws {
        // Write the script if it doesn't exist or when is not the same content as we wan't it to be
        func writeScriptIfNeeded(at path: URL, with script: String) throws {
            if FileManager.default.fileExists(atPath: path.path) {
                // Check if the existing file's content is the same as the given script
                let existingScript = try String(contentsOf: path, encoding: String.Encoding.utf8)
                if existingScript == script {
                    // Don't need to write again
                    return
                }
            }
            try script.write(to: path, atomically: true, encoding: String.Encoding.utf8)
        }

        // Get the scripting path
        let scriptsFolderPath = try getFinderExScriptPath()

        // write system scripts
        let toolsPath = scriptsFolderPath
            .appendingPathComponent(Constants.Scripting.ToolsFileName)
            .appendingPathExtension(Constants.Scripting.ToolsFileExtension)
        let toolsScript = """
            on runCommand(command)
                tell application "Finder"
                    activate
                    do shell script command
                end tell
            end runCommand
            """
        try writeScriptIfNeeded(at: toolsPath, with: toolsScript)
    }

    public func getScriptURL(name: String) -> URL? {
        let scriptFolderURL = try? FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        guard let url = scriptFolderURL else { return nil }
        let fileURL = url
            .appendingPathComponent(name)
            .appendingPathExtension(Constants.Scripting.ToolsFileExtension)
        return fileURL
    }

    public func getScriptEvent(functionName: String, _ parameter: String) -> NSAppleEventDescriptor {
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

    private func isAppInstalled(bundleIdentifier: String) -> Bool {
        let workspace = NSWorkspace.shared
        return workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }

    public func getFirstInstalledEditor() -> SupportedApps {
        let editors: [SupportedApps] = [.cursor, .vsCodeInsiders, .vsCode, .atom, .sublime, .intelliJ, .phpStorm, .pyCharm, .rubyMine, .webStorm, .xcode]
        for editor in editors where isAppInstalled(bundleIdentifier: editor.rawValue) {
            return editor
        }
        return .none
    }
    public func getFirstInstalledTerminal() -> SupportedApps {
        let terminals: [SupportedApps] = [.iTerm, .hyper, .terminal]
        for terminal in terminals where isAppInstalled(bundleIdentifier: terminal.rawValue) {
            return terminal
        }
        return .terminal
    }
}
