//
//  AstrixSection.swift
//  FinderTools
//
//  A group of related menu items shown under a titled header in the Astrix menu.
//

import AppKit

protocol AstrixSection {
    /// The header title shown above the section's items.
    var sectionName: String { get }

    /// The menu items for this section. Return an empty array to hide the section.
    func getSectionItems() -> [NSMenuItem]
}
