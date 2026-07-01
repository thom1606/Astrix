//
//  SupportedApps.swift
//  Astrix
//
//  The catalog of editors and terminals Astrix knows how to open a workspace in.
//  Shared across targets so the Settings app, menu bar app, and Finder extension
//  all agree on the exact same set of apps and their bundle identifiers.
//

import Foundation
import AppKit

/// Every editor and terminal Astrix can open a workspace in.
///
/// The raw value is the app's bundle identifier — that's what we persist in the
/// shared defaults and what the Finder extension uses to launch the app, so it
/// must stay stable. Add new apps here and to the relevant catalog below.
enum SupportedApps: String, CaseIterable, Identifiable {
    /// Sentinel for "no app selected".
    case none = "NONE"

    // MARK: - Terminals
    case terminal = "com.apple.Terminal"
    case iTerm = "com.googlecode.iterm2"
    case hyper = "co.zeit.hyper"
    case ghostty = "com.mitchellh.ghostty"
    case warp = "dev.warp.Warp-Stable"
    case kitty = "net.kovidgoyal.kitty"
    case alacritty = "org.alacritty"
    case wezTerm = "com.github.wez.wezterm"
    case cmux = "com.cmuxterm.app"

    // MARK: - Editors
    case zed = "dev.zed.Zed"
    case zedPreview = "dev.zed.Zed-Preview"
    case xcode = "com.apple.dt.Xcode"
    case vsCode = "com.microsoft.VSCode"
    case vsCodeInsiders = "com.microsoft.VSCodeInsiders"
    case antigravity = "com.google.antigravity"
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

    var id: String { rawValue }

    /// Human-readable name shown in the UI.
    var displayName: String {
        switch self {
        case .none: return "None"
        case .terminal: return "Terminal"
        case .iTerm: return "iTerm"
        case .hyper: return "Hyper"
        case .ghostty: return "Ghostty"
        case .warp: return "Warp"
        case .kitty: return "Kitty"
        case .alacritty: return "Alacritty"
        case .wezTerm: return "WezTerm"
        case .cmux: return "Cmux"
        case .zed: return "Zed"
        case .zedPreview: return "Zed (Preview)"
        case .xcode: return "Xcode"
        case .vsCode: return "Visual Studio Code"
        case .vsCodeInsiders: return "Visual Studio Code (Insiders)"
        case .antigravity: return "Antigravity"
        case .atom: return "Atom"
        case .sublime4: return "Sublime Text 4"
        case .sublime3: return "Sublime Text 3"
        case .cursor: return "Cursor"
        case .intelliJ: return "IntelliJ IDEA"
        case .phpStorm: return "PhpStorm"
        case .pyCharm: return "PyCharm"
        case .rubyMine: return "RubyMine"
        case .webStorm: return "WebStorm"
        case .androidStudio: return "Android Studio"
        }
    }

    /// Whether the app is currently installed, resolved via Launch Services.
    var isInstalled: Bool {
        guard self != .none else { return false }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: rawValue) != nil
    }

    /// Absolute path to a command-line tool bundled inside the app that should be
    /// used to open a path instead of Launch Services (`open -b`), or `nil` when the
    /// app has no such CLI or isn't installed. cmux's CLI opens a folder as a
    /// workspace in the running cmux window (launching cmux if needed) — the right
    /// behaviour for a terminal, which `open -b` doesn't give us.
    var bundledCLIPath: String? {
        switch self {
        case .cmux:
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: rawValue) else { return nil }
            return appURL.appendingPathComponent("Contents/Resources/bin/cmux").path
        default:
            return nil
        }
    }

    // MARK: - Catalogs

    /// All supported editors, sorted by display name for presentation.
    static let editors: [SupportedApps] = [
        .zed, .zedPreview, .xcode, .vsCode, .vsCodeInsiders, .antigravity, .atom,
        .sublime4, .sublime3, .cursor, .intelliJ, .phpStorm, .pyCharm,
        .rubyMine, .webStorm, .androidStudio
    ].sorted { $0.displayName < $1.displayName }

    /// All supported terminals, sorted by display name for presentation.
    static let terminals: [SupportedApps] = [
        .terminal, .iTerm, .hyper, .ghostty, .warp, .kitty, .alacritty, .wezTerm, .cmux
    ].sorted { $0.displayName < $1.displayName }

    /// The first installed editor, used as a sensible default. Falls back to `.none`.
    static var firstInstalledEditor: SupportedApps {
        let preference: [SupportedApps] = [
            .cursor, .zedPreview, .zed, .vsCodeInsiders, .vsCode, .atom, .sublime4, .sublime3,
            .intelliJ, .phpStorm, .pyCharm, .rubyMine, .webStorm, .xcode, .androidStudio
        ]
        return preference.first(where: \.isInstalled) ?? .none
    }

    /// The first installed terminal, used as a sensible default. Falls back to `.terminal`.
    static var firstInstalledTerminal: SupportedApps {
        let preference: [SupportedApps] = [
            .ghostty, .warp, .kitty, .alacritty, .wezTerm, .cmux, .iTerm, .hyper, .terminal
        ]
        return preference.first(where: \.isInstalled) ?? .terminal
    }
}
