//
//  Constants.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import Foundation

struct Constants {
    struct Id {
        static let FinderExtension = "com.thom1606.Astrix.FinderTools";
    }

    struct Scripting {
        static let ToolsFileName = "tools";
        static let ToolsFileExtension = "scpt";
        static let SupportedEditorApplications: [(SupportedApps, String)] = [
            (.textEdit, "TextEdit"),
            (.xcode, "XCode"),
            (.vsCode, "Visual Studio Code"),
            (.vsCodeInsiders, "Visual Studio Code (Insiders)"),
            (.cursor, "Cursor")
        ]
        static let SupportedTerminalApplications: [(SupportedApps, String)] = [
            (.terminal, "Terminal"),
            (.iTerm, "iTerm")
        ]
    }
}

public enum SupportedApps: String, CaseIterable {
    // MARK: - Terminals
    case terminal = "com.apple.Terminal"
    case iTerm = "com.googlecode.iterm2"
    // MARK: - Editors
    case textEdit = "com.apple.TextEdit"
    case xcode = "com.apple.Xcode"
    case vsCode = "com.microsoft.VSCode"
    case vsCodeInsiders = "com.microsoft.VSCodeInsiders"
    case cursor = "com.todesktop.230313mzl4w4u92"
}
