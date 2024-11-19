import SwiftUI

protocol AstrixSection {
    var sectionName: String { get }

    func getSectionItems() -> [NSMenuItem]
}
