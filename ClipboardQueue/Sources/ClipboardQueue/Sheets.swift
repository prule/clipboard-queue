import SwiftUI

/// Backs the three design props (accent, end behaviour, density) with real settings.
struct SettingsSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(Theme.ui(14, .semibold))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Accent")
                HStack(spacing: 8) {
                    ForEach(Accent.allCases) { accent in
                        Button {
                            store.accent = accent
                        } label: {
                            Circle()
                                .fill(Color(hex: accent.hex))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle().strokeBorder(Theme.ink.opacity(store.accent == accent ? 0.9 : 0),
                                                          lineWidth: 2)
                                        .padding(-3)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(accent.name)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("At the end of a list")
                Picker("", selection: Binding(
                    get: { store.endBehaviour },
                    set: { store.endBehaviour = $0 }
                )) {
                    Text("Stop").tag(EndBehaviour.stop)
                    Text("Loop back to item 01").tag(EndBehaviour.loop)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .font(Theme.ui(13))
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Row density")
                Picker("", selection: Binding(
                    get: { store.density },
                    set: { store.density = $0 }
                )) {
                    Text("Comfortable").tag(Density.comfortable)
                    Text("Compact").tag(Density.compact)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("How it works")
                Text("Clipboard Queue puts one item on the clipboard at a time. Paste it wherever you like, then advance the queue with ⌃⌥→.")
                    .font(Theme.ui(12))
                    .foregroundStyle(Theme.label)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("Shortcuts")
                Text("⌃⌥→ skip · ⌃⌥← back · ⌃⌥C open main window")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.mono2)
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }.buttonStyle(FilledButtonStyle(color: store.accentColor))
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(Theme.paneBG)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.ui(10, .semibold))
            .tracking(em: 0.1, size: 10)
            .textCase(.uppercase)
            .foregroundStyle(Theme.meta)
    }
}

/// "Edit items" — one item per line.
struct ItemEditorSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("Edit items").font(Theme.ui(14, .semibold)).foregroundStyle(Theme.ink)
                Text(store.activeList?.name ?? "").font(Theme.ui(12)).foregroundStyle(Theme.meta)
            }
            Text("One item per line. Blank lines are dropped.")
                .font(Theme.ui(11))
                .foregroundStyle(Theme.meta)

            TextEditor(text: $text)
                .font(Theme.mono(12))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Theme.controlBorder, lineWidth: 1)
                )
                .frame(width: 520, height: 380)

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel") { dismiss() }.buttonStyle(BorderedButtonStyle())
                Button("Save") {
                    store.replaceItems(with: text)
                    dismiss()
                }
                .buttonStyle(FilledButtonStyle(color: store.accentColor))
            }
        }
        .padding(20)
        .background(Theme.paneBG)
        .onAppear { text = store.activeItemsAsText }
    }
}
