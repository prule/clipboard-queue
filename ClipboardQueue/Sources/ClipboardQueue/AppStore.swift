import SwiftUI
import AppKit
import Combine

/// Owns the lists, the queue cursor, and the system clipboard.
@MainActor
final class AppStore: ObservableObject {

    static let shared = AppStore()

    @Published var lists: [ClipList] = []
    @Published var selectedListID: UUID?

    /// Whether the queue is driving the clipboard. Parked when the user copies
    /// something of their own, or when a non-looping list runs out.
    @Published var running: Bool = true {
        didSet { if running { parkReason = nil } }
    }

    enum ParkReason { case outsideCopy, endOfList }

    /// Why the queue parked, so the status bar can say which of the two happened.
    @Published private(set) var parkReason: ParkReason?

    /// Appends anything copied outside the app to the active list.
    @Published var captureOnCopy: Bool = false

    @Published var accent: Accent = .blue { didSet { persistSettings() } }
    @Published var endBehaviour: EndBehaviour = .stop { didSet { persistSettings() } }
    @Published var density: Density = .comfortable { didSet { persistSettings() } }

    private var pasteboardWatcher: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    /// The string we most recently put on the pasteboard, so we can tell our
    /// own writes apart from the user's copies.
    private var ownedText: String?

    var accentColor: Color { Color(hex: accent.hex) }

    // MARK: - Lifecycle

    init() {
        loadSettings()
        if let saved = Persistence.loadLists() {
            lists = saved
        } else {
            lists = Seed.lists()
            Persistence.saveLists(lists)
        }
        selectedListID = lists.first?.id
        startWatchingPasteboard()
        if running { writeCurrentToPasteboard() }
    }

    // MARK: - Derived state

    var activeList: ClipList? {
        guard let id = selectedListID else { return lists.first }
        return lists.first { $0.id == id } ?? lists.first
    }

    private var activeIndex: Int? {
        guard let id = activeList?.id else { return nil }
        return lists.firstIndex { $0.id == id }
    }

    var cursor: Int { activeList?.cursor ?? 0 }
    var itemCount: Int { activeList?.items.count ?? 0 }

    var currentText: String {
        guard let l = activeList, l.items.indices.contains(l.cursor) else { return "— empty list —" }
        return l.items[l.cursor].text
    }

    var nextText: String {
        guard let l = activeList, !l.items.isEmpty else { return "— empty list —" }
        let n = l.cursor + 1
        if n < l.items.count { return l.items[n].text }
        return endBehaviour == .loop ? l.items[0].text : "— end of list —"
    }

    var counter: String { "\(min(cursor + 1, itemCount)) of \(itemCount)" }
    var counterShort: String { "\(min(cursor + 1, itemCount))/\(itemCount)" }

    var progress: Double {
        guard itemCount > 0 else { return 0 }
        return Double(cursor + 1) / Double(itemCount)
    }

    var primaryButtonLabel: String { running ? "Next item" : "Resume" }

    var endBehaviourNote: String {
        endBehaviour == .loop ? "Loops back to item 01 at the end" : "Stops at the end of the list"
    }

    /// Left of the status bar: the app never watches for ⌘V, so this reports
    /// whether the queue currently owns the clipboard and, if not, why.
    var statusNote: String {
        guard !running else { return "Queue holds the clipboard" }
        return parkReason == .endOfList ? "Finished — end of list" : "Parked — you copied something else"
    }

    var isLive: Bool { running }

    // MARK: - Queue control

    func togglePaste() {
        if running {
            advance()
        } else {
            running = true
            writeCurrentToPasteboard()
        }
    }

    /// Advance one item, honouring the end-of-list behaviour.
    func advance() {
        guard let idx = activeIndex, !lists[idx].items.isEmpty else { return }
        let next = lists[idx].cursor + 1
        if next >= lists[idx].items.count {
            if endBehaviour == .loop {
                lists[idx].cursor = 0
            } else {
                lists[idx].cursor = lists[idx].items.count - 1
                running = false
                parkReason = .endOfList
                persistLists()
                return
            }
        } else {
            lists[idx].cursor = next
        }
        running = true
        persistLists()
        writeCurrentToPasteboard()
    }

    func back() {
        guard let idx = activeIndex, !lists[idx].items.isEmpty else { return }
        lists[idx].cursor = max(0, lists[idx].cursor - 1)
        running = true
        persistLists()
        writeCurrentToPasteboard()
    }

    func reset() {
        guard let idx = activeIndex else { return }
        lists[idx].cursor = 0
        running = true
        persistLists()
        writeCurrentToPasteboard()
    }

    /// Clicking a row in the list puts that item on the clipboard.
    func jump(to index: Int) {
        guard let idx = activeIndex, lists[idx].items.indices.contains(index) else { return }
        lists[idx].cursor = index
        running = true
        persistLists()
        writeCurrentToPasteboard()
    }

    func select(list: ClipList) {
        selectedListID = list.id
        running = true
        writeCurrentToPasteboard()
    }

    // MARK: - List editing

    func newList() {
        var name = "New list"
        var n = 2
        while lists.contains(where: { $0.name == name }) { name = "New list \(n)"; n += 1 }
        let list = ClipList(name: name, items: [])
        lists.append(list)
        selectedListID = list.id
        persistLists()
    }

    func rename(list id: UUID, to name: String) {
        guard let i = lists.firstIndex(where: { $0.id == id }) else { return }
        lists[i].name = name.isEmpty ? lists[i].name : name
        persistLists()
    }

    func delete(list id: UUID) {
        lists.removeAll { $0.id == id }
        if selectedListID == id { selectedListID = lists.first?.id }
        persistLists()
        writeCurrentToPasteboard()
    }

    /// Replaces the active list's items from a newline-separated block of text.
    func replaceItems(with text: String) {
        guard let idx = activeIndex else { return }
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        lists[idx].items = lines.map { QueueItem(text: $0) }
        lists[idx].cursor = min(lists[idx].cursor, max(0, lines.count - 1))
        persistLists()
        writeCurrentToPasteboard()
    }

    var activeItemsAsText: String {
        (activeList?.items ?? []).map(\.text).joined(separator: "\n")
    }

    // MARK: - Pasteboard

    func writeCurrentToPasteboard() {
        guard running, let l = activeList, l.items.indices.contains(l.cursor) else { return }
        let text = l.items[l.cursor].text
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        ownedText = text
        lastChangeCount = pb.changeCount
    }

    private func startWatchingPasteboard() {
        pasteboardWatcher = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollPasteboard() }
        }
    }

    /// A change we didn't make means the user copied something: park the queue
    /// (keeping our place) rather than fighting them for the clipboard.
    private func pollPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        let text = pb.string(forType: .string)
        guard let text, text != ownedText else { return }

        if captureOnCopy, let idx = activeIndex {
            lists[idx].items.append(QueueItem(text: text))
            persistLists()
        }
        running = false
        parkReason = .outsideCopy
    }

    // MARK: - Persistence

    private func persistLists() { Persistence.saveLists(lists) }

    private func persistSettings() {
        let d = UserDefaults.standard
        d.set(accent.rawValue, forKey: "accent")
        d.set(endBehaviour.rawValue, forKey: "endBehaviour")
        d.set(density.rawValue, forKey: "density")
    }

    private func loadSettings() {
        let d = UserDefaults.standard
        if let a = d.string(forKey: "accent"), let v = Accent(rawValue: a) { accent = v }
        if let e = d.string(forKey: "endBehaviour"), let v = EndBehaviour(rawValue: e) { endBehaviour = v }
        if let s = d.string(forKey: "density"), let v = Density(rawValue: s) { density = v }
    }
}

enum Persistence {
    private static var url: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".clipboardqueue", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("lists.json")
    }

    static func loadLists() -> [ClipList]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([ClipList].self, from: data)
    }

    static func saveLists(_ lists: [ClipList]) {
        guard let data = try? JSONEncoder().encode(lists) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
