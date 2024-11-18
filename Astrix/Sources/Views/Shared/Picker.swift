import SwiftUI

struct NSPickerContent: View {
    var size: ElementSize
    var title: String
    @State private var isHovered = false
    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        ZStack {
            HStack {
                Text(title)
                    .lineLimit(1)
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(Color(NSColor.labelColor))
                    .animation(.snappy, value: title)
                    .contentTransition(.numericText(countsDown: true))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: size.fontSize, weight: .bold))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
            }
            .frame(height: size.value)
            .padding(.horizontal, 25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 500)
                        .fill(Color("ElementsLightenBackground"))
                        .blendMode(.lighten)
                    RoundedRectangle(cornerRadius: 500)
                        .fill(Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.18))
                        .blendMode(.colorDodge)
                    Rectangle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.14),
                                    Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0)
                                ]),
                                center: .bottom,
                                startRadius: 0,
                                endRadius: size.value / 2
                            )
                        )
                        .frame(width: size.value, height: size.value)
                        .scaleEffect(x: 3, y: 1, anchor: .bottom)
                        .blendMode(.colorDodge)
                        .opacity(isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isHovered && isEnabled)
                    Rectangle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(NSColor.labelColor).opacity(0.07),
                                    Color(NSColor.labelColor).opacity(0)
                                ]),
                                center: .bottom,
                                startRadius: 0,
                                endRadius: size.value / 2
                            )
                        )
                        .frame(width: size.value, height: size.value)
                        .scaleEffect(x: 3, y: 1, anchor: .top)
                        .blendMode(.normal)
                        .opacity(isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isHovered && isEnabled)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 500))
            .onHover { hovering in
                isHovered = hovering
            }
        }
        .frame(height: size.value)
    }
}

private struct NSPicker: NSViewRepresentable {
    var size: ElementSize = .medium
    let selection: Binding<String>
    let items: [(String, String)]

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        // Find the selected item's title
        let selectedItemTitle = items.first { $0.0 == selection.wrappedValue }?.1 ?? "Select"

        // Create the SwiftUI view
        let pickerContent = NSPickerContent(size: size, title: selectedItemTitle)
        
        // Create an NSHostingView with the SwiftUI view
        let hostingView = NSHostingView(rootView: pickerContent)
        
        // Create the NSButton
        let button = NSButton(title: "", target: context.coordinator, action: #selector(context.coordinator.buttonClicked))
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.clear.cgColor
        context.coordinator.button = button
        
        // Add the hosting view as a subview of the button
        button.addSubview(hostingView)
        
        // Set constraints for the hosting view to match the button's size
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hostingView.heightAnchor.constraint(equalToConstant: size.value)
        ])

        view.addSubview(button)

        // Set constraints for the button to match the view's size
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.heightAnchor.constraint(equalToConstant: size.value)
        ])
        
        // Set constraints for the view to match the provided frame size
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: size.value)
        ])

        // let button = NSButton(title: "Select an item", target: context.coordinator, action: #selector(context.coordinator.buttonClicked))
        // context.coordinator.button = button

        // Create popover menu
        let menu = NSMenu()
        for item in items {
            let menuItem = NSMenuItem(title: item.1, action: #selector(context.coordinator.menuItemSelected(_:)), keyEquivalent: "")
            menuItem.target = context.coordinator
            menuItem.representedObject = item.0
            menu.addItem(menuItem)
        }

        button.menu = menu
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the selected item's title
        if let button = context.coordinator.button {
            let selectedItemTitle = items.first { $0.0 == selection.wrappedValue }?.1 ?? "Select"
            if let hostingView = button.subviews.first as? NSHostingView<NSPickerContent> {
                hostingView.rootView = NSPickerContent(size: size, title: selectedItemTitle)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: NSPicker
        weak var button: NSButton?

        init(_ parent: NSPicker) {
            self.parent = parent
        }

        @objc func buttonClicked() {
            if let button = button {
                button.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: button.superview)
            }
        }

        @objc func menuItemSelected(_ sender: NSMenuItem) {
            if let selectedValue = sender.representedObject as? String {
                parent.selection.wrappedValue = selectedValue
            }
        }
    }
}

struct LabeledPicker: View {
    var label: LocalizedStringKey
    @Binding var selection: String
    let items: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .foregroundStyle(Color(NSColor.secondaryLabelColor))
                .font(.system(size: 19, weight: .semibold))
            NSPicker(size: .medium, selection: $selection, items: items)
        }
    }
}
