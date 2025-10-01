//
//  Constants.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import Foundation

struct Constants {
    struct Id {
        static let teamIdentifier: String = {
            guard let identifier = Bundle.main.object(forInfoDictionaryKey: "TEAM_IDENTIFIER") as? String else {
                fatalError("TEAM_IDENTIFIER not set in xcconfig")
            }
            return identifier
        }()
        #if DEBUG
        static let FinderExtension = "com.thom1606.Astrix.FinderTools.Dev"
        #else
        static let FinderExtension = "com.thom1606.Astrix.FinderTools"
        #endif
        static let DefaultsDomain = "\(Constants.Id.teamIdentifier).com.thom1606.Astrix"
        static let DefaultTerminalKey = "defaultTerminal"
        static let DefaultEditorKey = "defaultEditor"
    }

    struct Scripting {
        static let ToolsFileName = "tools"
        static let ToolsFileExtension = "scpt"
        static let SupportedEditorApplications: [(SupportedApps, String)] = [
            (.none, "None"),
            (.zed, "Zed"),
            (.xcode, "XCode"),
            (.vsCode, "Visual Studio Code"),
            (.vsCodeInsiders, "Visual Studio Code (Insiders)"),
            (.atom, "Atom"),
            (.sublime4, "Sublime Text 4"),
            (.sublime3, "Sublime Text 3"),
            (.cursor, "Cursor"),
            (.intelliJ, "IntelliJ IDEA"),
            (.phpStorm, "PhpStorm"),
            (.pyCharm, "PyCharm"),
            (.rubyMine, "RubyMine"),
            (.webStorm, "WebStorm"),
            (.androidStudio, "Android Studio")
        ]
        static let SupportedTerminalApplications: [(SupportedApps, String)] = [
            (.none, "None"),
            (.terminal, "Terminal"),
            (.iTerm, "iTerm"),
            (.hyper, "Hyper"),
            (.ghostty, "Ghostty"),
            (.warp, "Warp"),
            (.kitty, "Kitty"),
            (.alacritty, "Alacritty"),
            (.wezTerm, "WezTerm")
        ]
    }
}

public enum SupportedApps: String, CaseIterable {
    // MARK: - Terminals
    case terminal = "com.apple.Terminal"
    case iTerm = "com.googlecode.iterm2"
    case hyper = "co.zeit.hyper"
    case ghostty = "com.mitchellh.ghostty"
    case warp = "dev.warp.Warp-Stable"
    case kitty = "net.kovidgoyal.kitty"
    case alacritty = "org.alacritty"
    case wezTerm = "com.github.wez.wezterm"
    // MARK: - Editors
    case none = "NONE"
    case zed = "dev.zed.Zed"
    case xcode = "com.apple.dt.Xcode"
    case vsCode = "com.microsoft.VSCode"
    case vsCodeInsiders = "com.microsoft.VSCodeInsiders"
    case atom = "com.github.atom"
    case sublime4 = "com.sublimetext.4"
    case sublime3 = "com.sublimetext.3"
    case cursor = "com.todesktop.230313mzl4w4u92"
    case intelliJ = "com.jetbrains.intellij"
    case phpStorm = "com.jetbrains.PhpStorm"
    case pyCharm = "com.jetbrains.pycharm"
    case rubyMine = "com.jetbrains.rubymine"
    case webStorm = "com.jetbrains.webstorm"
    case androidStudio = "com.google.android.studio"
}
