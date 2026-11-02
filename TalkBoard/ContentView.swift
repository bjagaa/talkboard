import SwiftUI

struct ItemDraft: Identifiable {
    let id = UUID()
    var item: Item
    var boardID: UUID
    var isNew: Bool
}

struct BoardDraft: Identifiable {
    let id = UUID()
    var boardID: UUID?          // nil = new page
    var name: String
    var symbol: String
}

struct ContentView: View {
    @EnvironmentObject private var store: BoardStore

    @State private var sentence: [Item] = []
    @State private var editing = false
    @State private var showSettings = false
    @State private var itemDraft: ItemDraft?
    @State private var boardDraft: BoardDraft?

    @State private var gearTaps = 0
    @State private var gearResetTask: Task<Void, Never>?

    private let spacing: CGFloat = 10

    var body: some View {
        VStack(spacing: spacing) {
            sentenceStrip
            tabs
            grid
        }
        .padding(12)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay(alignment: .bottom) { if editing { editBanner } }
        .sheet(isPresented: $showSettings) {
            SettingsView(onEditButtons: {
                showSettings = false
                editing = true
            })
            .environmentObject(store)
        }
        .sheet(item: $itemDraft) { draft in
            ItemEditor(draft: draft).environmentObject(store)
        }
        .sheet(item: $boardDraft) { draft in
            BoardEditor(draft: draft).environmentObject(store)
        }
    }

    // MARK: Sentence strip

    private var sentenceStrip: some View {
        HStack(spacing: spacing) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if sentence.isEmpty {
                            Text("Choose words to build a sentence")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }
                        ForEach(Array(sentence.enumerated()), id: \.offset) { index, word in
                            VStack(spacing: 2) {
                                Text(word.symbol).font(.system(size: 32))
                                Text(word.label).font(.headline)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .frame(minWidth: 64)
                            .background(word.type.color, in: RoundedRectangle(cornerRadius: 10))
                            .id(index)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: sentence.count) { _, count in
                    withAnimation { proxy.scrollTo(count - 1, anchor: .trailing) }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 84, maxHeight: 84, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))

            actionButton("Speak", systemImage: "speaker.wave.2.fill", prominent: true) {
                Speaker.shared.speak(sentence.map(\.spoken).joined(separator: " "), settings: store.settings)
                if store.settings.clearAfterSpeak { sentence.removeAll() }
            }
            actionButton("Delete", systemImage: "delete.left") {
                if !sentence.isEmpty { sentence.removeLast() }
            }
            actionButton("Clear", systemImage: "xmark") {
                sentence.removeAll()
            }
        }
    }

    private func actionButton(_ title: String, systemImage: String, prominent: Bool = false,
                              action: @escaping () -> Void) -> some View {
        DwellButton(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.system(size: 28, weight: .semibold))
                Text(title).font(.headline)
            }
            .frame(width: prominent ? 130 : 100, height: 84)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(prominent ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: Tabs

    private var tabs: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.boards) { board in
                        let selected = board.id == store.currentID
                        DwellButton(action: { store.currentID = board.id }) {
                            HStack(spacing: 8) {
                                Text(board.symbol).font(.system(size: 28))
                                Text(board.name).font(.title3.weight(.semibold))
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 60)
                            .foregroundStyle(selected ? Color(.systemBackground) : Color.primary)
                            .background(selected ? Color.primary : Color(.secondarySystemGroupedBackground))
                        }
                    }
                    if editing {
                        Button {
                            let b = store.currentBoard
                            boardDraft = BoardDraft(boardID: b.id, name: b.name, symbol: b.symbol)
                        } label: {
                            Label("Edit page", systemImage: "pencil").padding(.horizontal, 14).frame(height: 60)
                        }
                        .buttonStyle(.bordered)
                        Button {
                            boardDraft = BoardDraft(boardID: nil, name: "", symbol: "📁")
                        } label: {
                            Label("New page", systemImage: "plus").padding(.horizontal, 14).frame(height: 60)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            // Adult settings: three taps within 2 seconds, so a stray gaze can't open it.
            Button(action: gearTap) {
                VStack(spacing: 2) {
                    Image(systemName: "gearshape").font(.title2)
                    Text(gearTaps == 0 ? "Adults" : "\(3 - gearTaps) more").font(.caption)
                }
                .frame(width: 64, height: 60)
                .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Adult settings. Tap three times.")
        }
    }

    private func gearTap() {
        gearTaps += 1
        gearResetTask?.cancel()
        if gearTaps >= 3 {
            gearTaps = 0
            showSettings = true
            return
        }
        gearResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled { gearTaps = 0 }
        }
    }

    // MARK: Grid

    private var grid: some View {
        let board = store.currentBoard
        let cols = max(2, store.settings.columns)
        let count = board.items.count + (editing ? 1 : 0)
        let rows = max(1, Int((Double(count) / Double(cols)).rounded(.up)))

        return GeometryReader { geo in
            let fitted = (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            let height = max(90, fitted)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: cols),
                          spacing: spacing) {
                    ForEach(board.items) { item in
                        DwellButton(dwellAllowed: !editing, action: { tapped(item) }) {
                            cellFace(symbol: item.symbol, label: item.label, color: item.type.color, height: height)
                                .overlay {
                                    if editing {
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                                            .padding(4)
                                    }
                                }
                        }
                    }
                    if editing {
                        Button {
                            itemDraft = ItemDraft(item: Item(symbol: "⭐", label: "", type: .noun),
                                                  boardID: board.id, isNew: true)
                        } label: {
                            cellFace(symbol: "＋", label: "Add button", color: .clear, height: height)
                                .foregroundStyle(.secondary)
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [8, 6])))
                        }
                        .buttonStyle(PressStyle())
                    }
                }
            }
            .scrollDisabled(fitted >= 90)
        }
    }

    private func cellFace(symbol: String, label: String, color: Color, height: CGFloat) -> some View {
        let scale = store.settings.symbolScale
        return VStack(spacing: 4) {
            Text(symbol)
                .font(.system(size: min(height * 0.45, 96) * scale))
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.system(size: max(16, min(height * 0.15, 30)), weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .foregroundStyle(Color.primary)
        .background(color)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.18), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tapped(_ item: Item) {
        if editing {
            itemDraft = ItemDraft(item: item, boardID: store.boardID(containing: item) ?? store.currentID, isNew: false)
            return
        }
        if item.now {
            Speaker.shared.speak(item.spoken, settings: store.settings)
            return
        }
        sentence.append(item)
        if store.settings.speakEachWord {
            Speaker.shared.speak(item.spoken, settings: store.settings)
        }
    }

    // MARK: Edit banner

    private var editBanner: some View {
        HStack(spacing: 14) {
            Text("Editing: tap a button to change it")
                .font(.headline)
            Button("Done") { editing = false }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(.leading, 20).padding(.trailing, 8).padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 8)
        .padding(.bottom, 16)
    }
}
