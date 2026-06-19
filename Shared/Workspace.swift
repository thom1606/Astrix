//
//  Workspace.swift
//  Astrix
//
//  A user-defined workspace: a named, ordered list of launch actions surfaced in
//  the menu bar. Clicking a workspace runs every one of its actions in order.
//

import Foundation

/// A named bundle of launch actions (open this repo in Cursor, open the docs site
/// in the browser, open a terminal here…).
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
    /// The actions run, in order, when the workspace is launched.
    var actions: [WorkspaceAction]

    init(id: UUID = UUID(), name: String = "", icon: String = Workspace.defaultIcon, actions: [WorkspaceAction] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.actions = actions
    }

    /// Fallback name for a workspace the user hasn't named yet.
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Workspace" : name
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
