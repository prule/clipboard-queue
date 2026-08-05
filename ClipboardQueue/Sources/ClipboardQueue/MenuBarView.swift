import SwiftUI

/// The 330px menu-bar popover (design 1b).
struct MenuBarView: View {
    @EnvironmentObject var store: AppStore
    var openMainWindow: () -> Void
    var switchList: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(store.activeList?.name ?? "No list")
                    .font(Theme.ui(12, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Spacer()
                Text(store.counter)
                    .font(Theme.ui(11))
                    .monospacedDigit()
                    .foregroundStyle(Theme.meta)
            }

            ProgressBar(value: store.progress, color: store.accentColor, height: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Clipboard")
                    .font(Theme.ui(9, .semibold))
                    .tracking(em: 0.1, size: 9)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.meta)

                Text(store.currentText)
                    .font(Theme.mono(14, .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle().fill(Theme.hairline).frame(height: 1)

                HStack(spacing: 0) {
                    Text("Next · ").font(Theme.ui(11)).foregroundStyle(Theme.meta)
                    Text(store.nextText)
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.mono2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Theme.cardBorder, lineWidth: 1)
            )

            HStack(spacing: 6) {
                Button(store.primaryButtonLabel) { store.togglePaste() }
                    .buttonStyle(FilledButtonStyle(color: store.running ? store.accentColor : Theme.pausedButton,
                                                   font: Theme.ui(12, .medium),
                                                   hPadding: 10, radius: 6, expands: true))
                Button("←") { store.back() }
                    .buttonStyle(BorderedButtonStyle(font: Theme.ui(12), hPadding: 10, radius: 6))
                    .help("Back · ⌃⌥←")
                Button("→") { store.advance() }
                    .buttonStyle(BorderedButtonStyle(font: Theme.ui(12), hPadding: 10, radius: 6))
                    .help("Next item · ⌃⌥→")
            }

            Rectangle().fill(Theme.paneBorder).frame(height: 1).padding(.vertical, 1)

            VStack(spacing: 0) {
                menuRow("Switch list…", trailing: "▸", action: switchList)
                menuRow("Open main window", trailing: "⌃⌥C", mono: true, action: openMainWindow)
                menuRow("Quit", trailing: "⌘Q", mono: true) { NSApp.terminate(nil) }
            }
        }
        .padding(10)
        .frame(width: 330)
        .background(Theme.popoverBG)
    }

    private func menuRow(_ title: String, trailing: String, mono: Bool = false,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(Theme.ui(12)).foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(trailing)
                    .font(mono ? Theme.mono(11) : Theme.ui(12))
                    .foregroundStyle(Theme.metaLight)
            }
        }
        .buttonStyle(HoverRowStyle(hoverColor: Theme.menuHover, radius: 5, vPadding: 5, hPadding: 6))
    }
}

/// The "Switch list…" submenu, shown in place of the main popover body.
struct ListPickerView: View {
    @EnvironmentObject var store: AppStore
    var onPick: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Text("◂").foregroundStyle(Theme.metaLight)
                    Text("Lists").font(Theme.ui(12, .semibold)).foregroundStyle(Theme.ink)
                    Spacer()
                }
            }
            .buttonStyle(HoverRowStyle(hoverColor: Theme.menuHover, radius: 5, vPadding: 5, hPadding: 6))

            Rectangle().fill(Theme.paneBorder).frame(height: 1)

            ForEach(store.lists) { list in
                Button {
                    store.select(list: list)
                    onPick()
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(list.id == store.activeList?.id ? store.accentColor : .clear)
                            .frame(width: 6, height: 6)
                        Text(list.name).font(Theme.ui(12)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                        Spacer()
                        Text(list.meta).font(Theme.ui(11)).foregroundStyle(Theme.meta)
                    }
                }
                .buttonStyle(HoverRowStyle(hoverColor: Theme.menuHover, radius: 5, vPadding: 5, hPadding: 6))
            }
        }
        .padding(10)
        .frame(width: 330)
        .background(Theme.popoverBG)
    }
}

/// Popover container that swaps between the main body and the list picker.
struct MenuBarRoot: View {
    @EnvironmentObject var store: AppStore
    var openMainWindow: () -> Void
    @State private var picking = false

    var body: some View {
        Group {
            if picking {
                ListPickerView(onPick: { picking = false }, onBack: { picking = false })
            } else {
                MenuBarView(openMainWindow: openMainWindow, switchList: { picking = true })
            }
        }
    }
}
