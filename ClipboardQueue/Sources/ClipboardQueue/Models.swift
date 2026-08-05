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
    static let demo = [
        "ada.lovelace@northwind.co", "SIGNUP-4471-QX", "Marcus Chen",
        "https://northwind.co/r/onboard", "beatriz.almeida@vela.io", "SIGNUP-4472-QX",
        "Priya Raghunathan", "+1 (415) 555-0142", "tomas.novak@vela.io",
        "SIGNUP-4473-QX", "Wren Adeyemi", "https://northwind.co/r/invite",
        "hana.sato@meridian.dev", "SIGNUP-4474-QX", "Oliver Brandt",
        "4th Floor, 88 Grange St", "lucia.moreno@meridian.dev", "SIGNUP-4475-QX",
        "Devon Ellery", "https://northwind.co/r/trial"
    ]

    static let testCards = [
        "4242 4242 4242 4242", "4000 0025 0000 3155", "4000 0000 0000 9995",
        "5555 5555 5555 4444", "3782 822463 10005", "6011 1111 1111 1117",
        "3056 9309 0259 04", "4000 0000 0000 0002"
    ]

    static let supportMacros = [
        "Thanks for reaching out — I'm looking into this now.",
        "Could you send us a screenshot of what you're seeing?",
        "I've escalated this to our engineering team.",
        "This should be fixed in the latest release — mind updating?",
        "Sorry for the delay on this one.",
        "I've issued a refund; it lands in 5–10 business days.",
        "Your account has been upgraded.",
        "Can you confirm the email address on the account?",
        "We've reset your password — check your inbox.",
        "Closing this out; reopen any time if it recurs.",
        "Here's our status page: https://status.northwind.co",
        "I've added a note to your account for next time.",
        "Happy to help — anything else I can pick up?",
        "Following up on this — still seeing the issue?"
    ]

    static func numbered(_ prefix: String, _ count: Int) -> [String] {
        (1...count).map { "\(prefix) \(String(format: "%02d", $0))" }
    }

    static func lists() -> [ClipList] {
        [
            ClipList(name: "Demo — Q3 signups", items: demo.map { QueueItem(text: $0) }, cursor: 3),
            ClipList(name: "Test card numbers", items: testCards.map { QueueItem(text: $0) }),
            ClipList(name: "Support macros", items: supportMacros.map { QueueItem(text: $0) }),
            ClipList(name: "Onboarding demo", items: numbered("Onboarding step", 31).map { QueueItem(text: $0) }),
            ClipList(name: "Localisation strings", items: numbered("string.key", 62).map { QueueItem(text: $0) })
        ]
    }
}
