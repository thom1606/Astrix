//
//  Workspace.swift
//  Astrix
//
//  A user-defined workspace: a project folder plus one or more named launch
//  configurations, surfaced as a submenu in the menu bar.
//

import Foundation

/// A project grouped in the menu bar: its folder (openable in the editor, terminal,
/// Finder…) and the named launches you can start from it — "Dev Server", "Storybook",
/// each with its own ordered action list.
///
/// `Codable` so the whole list can be JSON-encoded into the shared App Group and
/// read back by any target. The Settings app writes these; the menu bar app reads
/// them to build its menu and run them.
struct Workspace: Codable, Identifiable, Hashable {
    var id: UUID
    /// User-facing name shown in the menu bar.
    var name: String
    /// SF Symbol name shown alongside the workspace in the menu bar.
    var icon: String
    /// The project folder. Actions that leave their path empty fall back to it, and it
    /// backs the menu's Open in Editor / Terminal / Finder entries. Optional.
    var folder: String
    /// The launch configurations this workspace offers, in menu order.
    var launches: [Launch]

    init(
        id: UUID = UUID(),
        name: String = "",
        icon: String = Workspace.defaultIcon,
        folder: String = "",
        launches: [Launch] = [Launch(name: "Launch")]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.folder = folder
        self.launches = launches
    }

    /// Fallback name for a workspace the user hasn't named yet.
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Workspace" : name
    }

    /// The expanded project folder, or `nil` when the user hasn't picked one.
    var folderURL: URL? {
        let trimmed = folder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(fileURLWithPath: (trimmed as NSString).expandingTildeInPath)
    }

    // MARK: - Migration

    private enum CodingKeys: String, CodingKey { case id, name, icon, folder, launches }

    /// Pre-2.1 workspaces stored one flat action list instead of named launches. Kept in
    /// its own key set so `Encodable` stays synthesized (and never writes the old shape).
    private enum LegacyKeys: String, CodingKey { case actions }

    /// Decodes both the current shape and the pre-2.1 one, where a workspace was a
    /// single flat `actions` array. Those are folded into one launch named after the
    /// workspace, so existing setups keep working untouched.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? Workspace.defaultIcon
        folder = try container.decodeIfPresent(String.self, forKey: .folder) ?? ""
        if let launches = try container.decodeIfPresent([Launch].self, forKey: .launches) {
            self.launches = launches
        } else {
            let legacy = try decoder.container(keyedBy: LegacyKeys.self)
            let actions = try legacy.decodeIfPresent([WorkspaceAction].self, forKey: .actions) ?? []
            self.launches = [Launch(name: "Launch", actions: actions)]
        }
    }

    /// The default SF Symbol for a freshly created workspace.
    static let defaultIcon = "square.grid.2x2"

    /// A large curated set of SF Symbols offered in the icon picker, grouped by theme.
    /// Every name is verified to exist on the deployment target.
    static let iconChoices = [
        // Dev & code
        "chevron.left.forwardslash.chevron.right", "curlybraces", "curlybraces.square",
        "terminal", "apple.terminal", "hammer", "wrench.and.screwdriver", "wrench.adjustable",
        "screwdriver", "gearshape", "gearshape.2", "gear", "cpu", "memorychip", "server.rack",
        "barcode", "qrcode",
        // Storage & files
        "externaldrive", "internaldrive", "opticaldiscdrive", "folder", "folder.fill", "doc",
        "doc.text", "doc.on.doc", "doc.richtext", "doc.plaintext", "tray", "tray.full", "tray.2",
        "archivebox", "shippingbox", "shippingbox.fill", "cube", "cube.transparent", "latch.2.case",
        // Web & network
        "globe", "globe.americas", "globe.europe.africa", "globe.asia.australia",
        "globe.central.south.asia", "cloud", "cloud.fill", "link", "safari", "wifi",
        "antenna.radiowaves.left.and.right", "dot.radiowaves.left.and.right",
        "point.3.connected.trianglepath.dotted", "network",
        // Data
        "cylinder", "cylinder.split.1x2", "chart.bar", "chart.bar.xaxis", "chart.pie",
        "chart.line.uptrend.xyaxis", "tablecells", "list.bullet", "list.bullet.rectangle",
        "function", "sum", "percent", "x.squareroot",
        // Layout & shapes
        "square.grid.2x2", "square.grid.3x3", "square.grid.3x2", "square.stack",
        "square.stack.3d.up", "square.stack.3d.up.fill", "rectangle.3.group", "circle.grid.2x2",
        "circle.grid.3x3", "squareshape.split.3x3", "circle.hexagongrid", "hexagon", "octagon",
        "seal",
        // Design & media
        "paintbrush", "paintbrush.pointed", "paintbrush.pointed.fill", "paintpalette",
        "swatchpalette", "pencil", "pencil.and.outline", "pencil.tip", "ruler", "scissors",
        "eyedropper", "eyedropper.halffull", "photo", "photo.stack", "camera", "theatermasks",
        "music.note", "music.quarternote.3", "film", "video", "tv", "waveform", "mic",
        "speaker.wave.2", "headphones", "gamecontroller",
        // Devices
        "desktopcomputer", "laptopcomputer", "pc", "display", "display.2", "macpro.gen3",
        "macmini", "macstudio", "ipad", "iphone", "applewatch", "keyboard", "printer",
        // Nature & science
        "atom", "leaf", "tree", "flame", "drop", "bolt", "bolt.horizontal", "sparkles",
        "wand.and.stars", "wand.and.rays", "lightbulb", "lightbulb.fill", "lightbulb.max",
        "moon.stars", "sun.max", "snowflake", "ladybug", "ant", "ant.fill", "tortoise", "hare",
        "bird", "fish", "pawprint", "carrot",
        // Markers
        "star", "star.fill", "heart", "heart.fill", "flag", "flag.checkered", "flag.2.crossed",
        "bookmark", "tag", "tag.fill", "pin", "mappin", "mappin.and.ellipse", "location",
        "location.north", "map", "scope", "target",
        // Work & learning
        "briefcase", "briefcase.fill", "suitcase", "suitcase.rolling", "bag", "cart", "basket",
        "books.vertical", "book", "book.closed", "graduationcap", "brain", "brain.head.profile",
        "puzzlepiece", "puzzlepiece.extension", "puzzlepiece.fill", "building.2",
        "building.columns", "house", "tent",
        // Food & life
        "cup.and.saucer", "cup.and.saucer.fill", "mug", "fork.knife", "wineglass", "birthday.cake",
        // Symbols & keys
        "command", "option", "control", "number", "at", "asterisk", "infinity", "power", "lock",
        "key", "shield", "circle.hexagonpath", "circle.dotted", "slider.horizontal.3", "switch.2",
        "gyroscope",
        // Transport
        "airplane", "car", "bicycle"
    ]
}
