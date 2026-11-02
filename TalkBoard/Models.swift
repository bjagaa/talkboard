import SwiftUI

// MARK: - Word types (Fitzgerald Key colors used on AAC boards)

enum WordType: String, Codable, CaseIterable, Identifiable {
    case pron, verb, adj, noun, social, q, neg, misc

    var id: String { rawValue }

    var name: String {
        switch self {
        case .pron:   return "People"
        case .verb:   return "Actions"
        case .adj:    return "Describing"
        case .noun:   return "Things"
        case .social: return "Social"
        case .q:      return "Questions"
        case .neg:    return "No / Stop"
        case .misc:   return "Little words"
        }
    }

    private var hexes: (light: UInt32, dark: UInt32) {
        switch self {
        case .pron:   return (0xFFF1A6, 0x5C5220)
        case .verb:   return (0xC9EFC4, 0x24502A)
        case .adj:    return (0xCFE2FF, 0x23405F)
        case .noun:   return (0xFFD9B8, 0x5E3A1C)
        case .social: return (0xFFD3E6, 0x5A2842)
        case .q:      return (0xE5D6FB, 0x3F2E60)
        case .neg:    return (0xFFC9C4, 0x63292A)
        case .misc:   return (0xFFFFFF, 0x2A313C)
        }
    }

    var color: Color {
        let h = hexes
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: h.dark) : UIColor(hex: h.light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

// MARK: - Data

struct Item: Codable, Identifiable, Hashable {
    var id = UUID()
    var symbol: String
    var label: String
    var type: WordType
    /// What the voice says. Empty means "say the label".
    var say: String = ""
    /// Speak immediately instead of adding to the sentence.
    var now: Bool = false

    var spoken: String { say.isEmpty ? label : say }
}

struct Board: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var symbol: String
    var items: [Item]
}

struct AppSettings: Codable, Equatable {
    var columns: Int = 5
    var symbolScale: Double = 1.0
    var dwellInApp: Bool = false
    var dwellSeconds: Double = 1.2
    var speakEachWord: Bool = true
    var clearAfterSpeak: Bool = false
    var rate: Float = 0.45          // AVSpeechUtterance rate, 0...1
    var voiceIdentifier: String? = nil
}

// MARK: - Starter vocabulary

private func W(_ symbol: String, _ label: String, _ type: WordType,
               say: String = "", now: Bool = false) -> Item {
    Item(symbol: symbol, label: label, type: type, say: say, now: now)
}

enum StarterBoards {
    static func make() -> [Board] {
        [
            Board(name: "Quick", symbol: "⭐", items: [
                W("👍", "yes", .social, now: true), W("👎", "no", .neg, now: true),
                W("🙋", "help", .verb, now: true), W("✋", "stop", .neg, now: true),
                W("➕", "more", .adj), W("✅", "all done", .social, now: true),
                W("🙂", "I", .pron), W("❤️", "want", .verb),
                W("🚻", "bathroom", .noun, say: "I need the bathroom", now: true),
                W("🥤", "drink", .noun), W("😴", "tired", .adj),
                W("🤕", "it hurts", .adj, now: true), W("👋", "hello", .social, now: true),
                W("🙏", "thank you", .social, now: true), W("❓", "what", .q)
            ]),
            Board(name: "Core words", symbol: "💬", items: [
                W("🙂", "I", .pron), W("👉", "you", .pron), W("👦", "he", .pron), W("👧", "she", .pron),
                W("👥", "we", .pron), W("❤️", "want", .verb), W("👀", "see", .verb), W("🫴", "get", .verb),
                W("🚶", "go", .verb), W("🎮", "play", .verb), W("👍", "like", .verb), W("✋", "stop", .neg),
                W("🚫", "not", .neg), W("➕", "more", .adj), W("🔁", "again", .misc), W("📦", "it", .misc),
                W("👇", "this", .misc), W("📍", "here", .misc), W("⬆️", "up", .misc), W("⬇️", "down", .misc),
                W("➡️", "in", .misc), W("⬅️", "out", .misc), W("🤝", "and", .misc), W("🙌", "finished", .adj)
            ]),
            Board(name: "Feelings", symbol: "😊", items: [
                W("😀", "happy", .adj), W("😢", "sad", .adj), W("😠", "mad", .adj), W("😨", "scared", .adj),
                W("😴", "tired", .adj), W("🤒", "sick", .adj), W("🤕", "hurt", .adj), W("😕", "confused", .adj),
                W("😌", "calm", .adj), W("🤩", "excited", .adj), W("😣", "frustrated", .adj), W("🥶", "cold", .adj),
                W("🥵", "hot", .adj), W("🍽️", "hungry", .adj), W("🙂", "I feel", .pron)
            ]),
            Board(name: "People", symbol: "👪", items: [
                W("🙂", "me", .pron), W("👩‍🏫", "teacher", .pron), W("🧑‍⚕️", "nurse", .pron), W("👩", "mom", .pron),
                W("👨", "dad", .pron), W("🧒", "friend", .pron), W("🧑‍🦽", "aide", .pron),
                W("🗣️", "speech teacher", .pron), W("👵", "grandma", .pron), W("👴", "grandpa", .pron),
                W("🧑‍🤝‍🧑", "class", .pron), W("🚌", "bus driver", .pron)
            ]),
            Board(name: "Food & drink", symbol: "🍎", items: [
                W("💧", "water", .noun), W("🧃", "juice", .noun), W("🥛", "milk", .noun), W("🍎", "apple", .noun),
                W("🍌", "banana", .noun), W("🍪", "cookie", .noun), W("🍕", "pizza", .noun), W("🥪", "sandwich", .noun),
                W("🍗", "chicken", .noun), W("🍚", "rice", .noun), W("🍝", "pasta", .noun), W("🧀", "crackers", .noun),
                W("🥣", "snack", .noun), W("🍴", "lunch", .noun), W("🍽️", "eat", .verb), W("🥤", "drink", .verb)
            ]),
            Board(name: "School", symbol: "🏫", items: [
                W("📚", "read", .verb), W("✏️", "write", .verb), W("🎨", "art", .noun), W("🎵", "music", .noun),
                W("💻", "computer", .noun), W("📱", "iPad", .noun), W("🏀", "gym", .noun), W("🌳", "outside", .noun),
                W("📺", "video", .noun), W("🧩", "puzzle", .noun), W("🔢", "math", .noun), W("🚌", "bus", .noun),
                W("🏠", "home", .noun), W("⏸️", "break", .noun, say: "I need a break", now: true),
                W("🔇", "quiet", .adj)
            ]),
            Board(name: "Questions", symbol: "❓", items: [
                W("❓", "what", .q), W("📍", "where", .q), W("🕐", "when", .q), W("🧑", "who", .q),
                W("🤔", "why", .q), W("🔧", "how", .q),
                W("❓", "What is that?", .q, now: true), W("🏠", "When do I go home?", .q, now: true),
                W("🍴", "Is it lunch time?", .q, now: true), W("🔁", "Can you say that again?", .q, now: true)
            ])
        ]
    }
}
