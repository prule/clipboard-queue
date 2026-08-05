import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var store: AppStore
    @State private var showSettings = false
    @State private var showEditor = false

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(showSettings: $showSettings)
            MainPaneView(showEditor: $showEditor)
        }
        .frame(width: 1000, height: 640)
        .background(Theme.paneBG)
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .sheet(isPresented: $showEditor) { ItemEditorSheet() }
    }
}

// MARK: - Sidebar (236px)

struct SidebarView: View {
    @EnvironmentObject var store: AppStore
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Traffic-light header
            HStack(spacing: 8) { TrafficLights() }
                .padding(.horizontal, 14)
                .frame(height: 52, alignment: .leading)

            Text("Lists")
                .font(Theme.ui(11, .semibold))
                .tracking(em: 0.06, size: 11)
                .textCase(.uppercase)
                .foregroundStyle(Theme.meta)
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 8)

            ScrollView(.vertical) {
                VStack(spacing: 1) {
                    ForEach(store.lists) { list in
                        ListRow(list: list, isLive: list.id == store.activeList?.id)
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollIndicators(.automatic)

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                Button {
                    store.newList()
                } label: {
                    HStack(spacing: 7) {
                        Text("+").font(Theme.ui(15)).foregroundStyle(Theme.meta)
                        Text("New list").font(Theme.ui(13)).foregroundStyle(Theme.inkMuted)
                    }
                }
                .buttonStyle(HoverRowStyle(hoverColor: Theme.sidebarHover))

                Button {
                    showSettings = true
                } label: {
                    HStack(spacing: 7) {
                        Text("⌥").font(Theme.ui(13)).foregroundStyle(Theme.meta)
                        Text("Settings").font(Theme.ui(13)).foregroundStyle(Theme.inkMuted)
                    }
                }
                .buttonStyle(HoverRowStyle(hoverColor: Theme.sidebarHover))
            }
            .padding(10)
            .overlay(alignment: .top) { Rectangle().fill(Theme.sidebarBorder).frame(height: 1) }
        }
        .frame(width: 236)
        .background(Theme.sidebar)
        .overlay(alignment: .trailing) { Rectangle().fill(Theme.sidebarBorder).frame(width: 1) }
    }
}

private struct ListRow: View {
    @EnvironmentObject var store: AppStore
    let list: ClipList
    let isLive: Bool

    @State private var hovering = false
    @State private var renaming = false
    @State private var draftName = ""

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(isLive ? Color.white : Color.clear)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 0) {
                if renaming {
                    TextField("", text: $draftName)
                        .textFieldStyle(.plain)
                        .font(Theme.ui(13, .medium))
                        .foregroundStyle(isLive ? .white : Theme.inkSoft)
                        .onSubmit { store.rename(list: list.id, to: draftName); renaming = false }
                } else {
                    Text(list.name)
                        .font(Theme.ui(13, .medium))
                        .foregroundStyle(isLive ? .white : Theme.inkSoft)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Text(metaText)
                    .font(Theme.ui(11))
                    .foregroundStyle(isLive ? Color.white.opacity(0.72) : Theme.meta)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isLive ? store.accentColor : (hovering ? Theme.sidebarHover : .clear))
        )
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onHover { hovering = $0 }
        .onTapGesture { store.select(list: list) }
        .contextMenu {
            Button("Rename") { draftName = list.name; renaming = true }
            Button("Delete", role: .destructive) { store.delete(list: list.id) }
                .disabled(store.lists.count <= 1)
        }
    }

    private var metaText: String {
        isLive ? "\(list.meta) · \(store.running ? "active" : "parked")" : list.meta
    }
}

// MARK: - Main pane

struct MainPaneView: View {
    @EnvironmentObject var store: AppStore
    @Binding var showEditor: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            QueuePanelView()
            ItemListView()
            statusBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paneBG)
    }

    private var header: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(store.activeList?.name ?? "No list")
                    .font(Theme.ui(14, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(store.itemCount) items")
                    .font(Theme.ui(12))
                    .foregroundStyle(Theme.meta)
            }
            Spacer()
            HStack(spacing: 6) {
                Button("Edit items") { showEditor = true }
                    .buttonStyle(BorderedButtonStyle(font: Theme.ui(12), vPadding: 4, hPadding: 11,
                                                     radius: 6, shadow: true))
                Button("Capture on copy") { store.captureOnCopy.toggle() }
                    .buttonStyle(CaptureToggleStyle(on: store.captureOnCopy, accent: store.accentColor))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.paneBorder).frame(height: 1) }
    }

    private var statusBar: some View {
        HStack {
            Text("Watching for ⌘V system-wide")
            Spacer()
            Text("⌃⌥→ skip · ⌃⌥← back")
        }
        .font(Theme.ui(11))
        .foregroundStyle(Theme.meta)
        .padding(.horizontal, 14)
        .frame(height: 30)
        .background(Theme.statusBarBG)
        .overlay(alignment: .top) { Rectangle().fill(Theme.paneBorder).frame(height: 1) }
    }
}

/// "Capture on copy" is a toggle in the real app; matches the bordered control
/// when off and tints to the accent when armed.
private struct CaptureToggleStyle: ButtonStyle {
    var on: Bool
    var accent: Color
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.ui(12))
            .foregroundStyle(on ? accent : Theme.inkSoft)
            .padding(.vertical, 4)
            .padding(.horizontal, 11)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(on ? accent.opacity(0.09) : (hovering ? Theme.controlHover : .white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(on ? accent.opacity(0.5) : Theme.controlBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 0, x: 0, y: 1)
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .onHover { hovering = $0 }
    }
}

// MARK: - "On the clipboard now" panel

struct QueuePanelView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("On the clipboard now")
                        .font(Theme.ui(10, .semibold))
                        .tracking(em: 0.1, size: 10)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.meta)

                    HStack(spacing: 9) {
                        PulseDot(color: store.accentColor, active: store.running)
                        Text(store.currentText)
                            .font(Theme.mono(19, .medium))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    HStack(spacing: 0) {
                        Text("Next up · ")
                            .font(Theme.ui(12))
                            .foregroundStyle(Theme.meta)
                        Text(store.nextText)
                            .font(Theme.mono(12))
                            .foregroundStyle(Theme.mono2)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(store.counter)
                        .font(Theme.ui(24, .semibold))
                        .monospacedDigit()
                        .tracking(em: -0.02, size: 24)
                        .foregroundStyle(Theme.ink)
                    Text("pasted")
                        .font(Theme.ui(11))
                        .foregroundStyle(Theme.meta)
                }
            }

            ProgressBar(value: store.progress, color: store.accentColor)

            HStack(spacing: 8) {
                Button(store.primaryButtonLabel) { store.togglePaste() }
                    .buttonStyle(FilledButtonStyle(color: store.running ? store.accentColor : Theme.pausedButton))
                Button("Back") { store.back() }.buttonStyle(BorderedButtonStyle())
                Button("Skip") { store.advance() }.buttonStyle(BorderedButtonStyle())
                Button("Reset") { store.reset() }.buttonStyle(BorderedButtonStyle())
                Spacer()
                Text(store.endBehaviourNote)
                    .font(Theme.ui(11))
                    .foregroundStyle(Theme.metaLight)
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.paneBorder).frame(height: 1) }
    }
}

// MARK: - Item list

struct ItemListView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array((store.activeList?.items ?? []).enumerated()), id: \.element.id) { n, item in
                        ItemRow(n: n, item: item, cursor: store.cursor)
                            .id(item.id)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .onChange(of: store.cursor) { _, _ in scroll(proxy) }
            .onChange(of: store.selectedListID) { _, _ in scroll(proxy) }
            .onAppear { scroll(proxy) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        guard let l = store.activeList, l.items.indices.contains(l.cursor) else { return }
        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(l.items[l.cursor].id, anchor: .center) }
    }
}

private struct ItemRow: View {
    @EnvironmentObject var store: AppStore
    let n: Int
    let item: QueueItem
    let cursor: Int

    private var isCurrent: Bool { n == cursor }
    private var isDone: Bool { n < cursor }

    var body: some View {
        let pad = store.density.rowPadding
        HStack(spacing: 12) {
            Text(String(format: "%02d", n + 1))
                .font(Theme.mono(11))
                .monospacedDigit()
                .foregroundStyle(isCurrent ? store.accentColor : (isDone ? Theme.doneNum : Theme.pending))
                .frame(width: 26, alignment: .trailing)

            Text(item.text)
                .font(Theme.mono(13, isCurrent ? .medium : .regular))
                .foregroundStyle(isCurrent ? Theme.ink : (isDone ? Theme.pending : Theme.inkMuted))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(isCurrent ? "on clipboard" : (isDone ? "pasted" : ""))
                .font(Theme.ui(10, .medium))
                .tracking(em: 0.04, size: 10)
                .textCase(.uppercase)
                .foregroundStyle(isCurrent ? store.accentColor : Theme.doneTag)
        }
        .padding(.vertical, pad.v)
        .padding(.horizontal, pad.h)
        .background(isCurrent ? store.accentColor.opacity(0.07) : .clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isCurrent ? store.accentColor : .clear)
                .frame(width: 3)
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.rowBorder).frame(height: 1) }
        .contentShape(Rectangle())
        .onTapGesture { store.jump(to: n) }
    }
}
