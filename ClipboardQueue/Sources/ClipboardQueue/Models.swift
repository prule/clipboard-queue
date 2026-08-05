import Foundation

struct QueueItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
}

struct ClipList: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var items: [QueueItem]
    /// Index of the item currently on the clipboard.
    var cursor: Int = 0

    var meta: String {
        "\(items.count) item\(items.count == 1 ? "" : "s")"
    }
}

enum EndBehaviour: String, Codable { case stop, loop }
enum Density: String, Codable, CaseIterable, Identifiable {
    case comfortable, compact
    var id: String { rawValue }
    var rowPadding: (v: CGFloat, h: CGFloat) { self == .compact ? (5, 16) : (9, 16) }
}

/// The four accents exposed as a design prop.
enum Accent: String, Codable, CaseIterable, Identifiable {
    case blue = "0a68d0"
    case ink = "1b1b1f"
    case green = "0f7a53"
    case rust = "a03c1e"
    var id: String { rawValue }
    var hex: String { rawValue }
    var name: String {
        switch self {
        case .blue: return "Blue"
        case .ink: return "Ink"
        case .green: return "Green"
        case .rust: return "Rust"
        }
    }
}

// MARK: - Seed content

enum Seed {
    /// Quotation text only, no attributions: the app pushes whatever the cursor
    /// is on straight to the system clipboard, so nothing seeded may resemble a
    /// personal name, address, account identifier or card number.
    static let quotes = [
        "Well begun is half done.",
        "The obstacle is the way.",
        "Fall seven times, stand up eight.",
        "Simplicity is the ultimate sophistication.",
        "What we do now echoes in eternity.",
        "The best time to plant a tree was twenty years ago.",
        "Begin where you are, with what you have.",
        "Small steps, taken daily, compound."
    ]

    static func lists() -> [ClipList] {
        [ClipList(name: "Sample quotes", items: quotes.map { QueueItem(text: $0) })]
    }
}
