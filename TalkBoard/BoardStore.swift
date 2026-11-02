import SwiftUI

/// Holds all boards and settings and saves them to a JSON file on the iPad.
/// Everything works offline; nothing leaves the device.
final class BoardStore: ObservableObject {
    @Published var boards: [Board] { didSet { save() } }
    @Published var settings: AppSettings { didSet { save() } }
    @Published var currentID: UUID

    private struct Saved: Codable {
        var boards: [Board]
        var settings: AppSettings
    }

    private struct OnlyBoards: Codable {
        var boards: [Board]
    }

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("talkboard.json")
    }

    init() {
        var loadedBoards = StarterBoards.make()
        var loadedSettings = AppSettings()
        if let data = try? Data(contentsOf: Self.fileURL) {
            if let saved = try? JSONDecoder().decode(Saved.self, from: data), !saved.boards.isEmpty {
                loadedBoards = saved.boards
                loadedSettings = saved.settings
            } else if let onlyBoards = try? JSONDecoder().decode(OnlyBoards.self, from: data),
                      !onlyBoards.boards.isEmpty {
                // Settings format changed in an update: keep the student's boards, reset settings.
                loadedBoards = onlyBoards.boards
            }
        }
        boards = loadedBoards
        settings = loadedSettings
        currentID = loadedBoards[0].id
    }

    private func save() {
        let saved = Saved(boards: boards, settings: settings)
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    // MARK: Boards

    var currentBoard: Board {
        boards.first(where: { $0.id == currentID }) ?? boards[0]
    }

    func addBoard(name: String, symbol: String) {
        let board = Board(name: name, symbol: symbol, items: [])
        boards.append(board)
        currentID = board.id
    }

    func updateBoard(id: UUID, name: String, symbol: String) {
        guard let i = boards.firstIndex(where: { $0.id == id }) else { return }
        boards[i].name = name
        boards[i].symbol = symbol
    }

    func deleteBoard(id: UUID) {
        guard boards.count > 1 else { return }
        boards.removeAll { $0.id == id }
        if !boards.contains(where: { $0.id == currentID }) { currentID = boards[0].id }
    }

    // MARK: Items

    /// Saves an item onto a board. If it is already on that board it keeps its place;
    /// if it lived on another board it moves to the end of this one.
    func saveItem(_ item: Item, to boardID: UUID) {
        if let b = boards.firstIndex(where: { $0.id == boardID }),
           let i = boards[b].items.firstIndex(where: { $0.id == item.id }) {
            boards[b].items[i] = item
            return
        }
        var copy = boards
        for b in copy.indices { copy[b].items.removeAll { $0.id == item.id } }
        if let b = copy.firstIndex(where: { $0.id == boardID }) { copy[b].items.append(item) }
        boards = copy
    }

    func deleteItem(_ item: Item) {
        var copy = boards
        for b in copy.indices { copy[b].items.removeAll { $0.id == item.id } }
        boards = copy
    }

    func moveItemEarlier(_ item: Item) {
        for b in boards.indices {
            if let i = boards[b].items.firstIndex(where: { $0.id == item.id }), i > 0 {
                boards[b].items.swapAt(i, i - 1)
                return
            }
        }
    }

    func boardID(containing item: Item) -> UUID? {
        boards.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.id
    }

    func resetAll() {
        boards = StarterBoards.make()
        settings = AppSettings()
        currentID = boards[0].id
    }
}
