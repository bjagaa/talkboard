import SwiftUI
import AVFoundation

// MARK: - Settings (adults only)

struct SettingsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    var onEditButtons: () -> Void

    @State private var confirmReset = false
    private let voices = Speaker.englishVoices

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Buttons per row: \(store.settings.columns)",
                            value: $store.settings.columns, in: 2...8)
                    VStack(alignment: .leading) {
                        Text("Symbol size: \(store.settings.symbolScale, specifier: "%.1f")×")
                        Slider(value: $store.settings.symbolScale, in: 0.6...1.6, step: 0.1)
                    }
                } header: { Text("Layout") }

                Section {
                    Toggle("Dwell inside the app", isOn: $store.settings.dwellInApp)
                    VStack(alignment: .leading) {
                        Text("Dwell time: \(store.settings.dwellSeconds, specifier: "%.1f") seconds")
                        Slider(value: $store.settings.dwellSeconds, in: 0.5...3.0, step: 0.1)
                    }
                    .disabled(!store.settings.dwellInApp)
                } header: { Text("Eye gaze") } footer: {
                    Text("If the student uses AssistiveTouch Dwell Control with the eye tracker, leave this off so a button is not chosen twice.")
                }

                Section {
                    Toggle("Say each word when it is chosen", isOn: $store.settings.speakEachWord)
                    Toggle("Clear the sentence after Speak", isOn: $store.settings.clearAfterSpeak)
                    VStack(alignment: .leading) {
                        Text("Voice speed")
                        Slider(value: $store.settings.rate, in: 0.3...0.6)
                    }
                    Picker("Voice", selection: $store.settings.voiceIdentifier) {
                        Text("Default (US English)").tag(String?.none)
                        ForEach(voices, id: \.identifier) { v in
                            Text(voiceName(v)).tag(Optional(v.identifier))
                        }
                    }
                    Button("Test voice") {
                        Speaker.shared.speak("Hello, I am ready to talk.", settings: store.settings)
                    }
                } header: { Text("Voice") } footer: {
                    Text("Download better voices on the iPad in Settings > Accessibility > Spoken Content > Voices.")
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                        ForEach(WordType.allCases) { t in
                            Text(t.name)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                .background(t.color, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Color key (Fitzgerald)") }

                Section {
                    Button("Edit buttons and pages") { onEditButtons() }
                    Button("Reset all boards", role: .destructive) { confirmReset = true }
                }
            }
            .navigationTitle("Board settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Reset all boards to the starter words? Custom buttons will be removed.",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset all boards", role: .destructive) { store.resetAll() }
            }
        }
    }

    private func voiceName(_ v: AVSpeechSynthesisVoice) -> String {
        switch v.quality {
        case .premium:  return "\(v.name) (Premium)"
        case .enhanced: return "\(v.name) (Enhanced)"
        default:        return v.name
        }
    }
}

// MARK: - Button editor

struct ItemEditor: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ItemDraft
    @State private var confirmDelete = false

    init(draft: ItemDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text(draft.item.symbol.isEmpty ? "⭐" : draft.item.symbol).font(.system(size: 48))
                            Text(draft.item.label.isEmpty ? "word" : draft.item.label).font(.headline)
                        }
                        .frame(width: 140, height: 120)
                        .background(draft.item.type.color, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.18), lineWidth: 2))
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Symbol (emoji)", text: $draft.item.symbol)
                    TextField("Word on the button", text: $draft.item.label)
                    TextField("What the voice says (optional)", text: $draft.item.say)
                } footer: {
                    Text("Tap the 😀 key on the iPad keyboard to pick an emoji. Leave the voice line empty to say the word.")
                }

                Section {
                    Picker("Word type", selection: $draft.item.type) {
                        ForEach(WordType.allCases) { t in Text(t.name).tag(t) }
                    }
                    Toggle("Speak right away (don't add to sentence)", isOn: $draft.item.now)
                    Picker("Page", selection: $draft.boardID) {
                        ForEach(store.boards) { b in Text("\(b.symbol) \(b.name)").tag(b.id) }
                    }
                }

                if !draft.isNew {
                    Section {
                        Button("Move earlier on the page") { store.moveItemEarlier(draft.item) }
                        Button("Delete button", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(draft.isNew ? "Add a button" : "Edit button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var item = draft.item
                        item.label = item.label.trimmingCharacters(in: .whitespaces)
                        item.say = item.say.trimmingCharacters(in: .whitespaces)
                        if item.symbol.trimmingCharacters(in: .whitespaces).isEmpty { item.symbol = "⭐" }
                        store.saveItem(item, to: draft.boardID)
                        dismiss()
                    }
                    .disabled(draft.item.label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete this button?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.deleteItem(draft.item)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Page editor

struct BoardEditor: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: BoardDraft
    @State private var confirmDelete = false

    init(draft: BoardDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Symbol (emoji)", text: $draft.symbol)
                TextField("Page name", text: $draft.name)
                if let id = draft.boardID, store.boards.count > 1 {
                    Button("Delete page", role: .destructive) { confirmDelete = true }
                        .confirmationDialog("Delete this page and all its buttons?",
                                            isPresented: $confirmDelete, titleVisibility: .visible) {
                            Button("Delete page", role: .destructive) {
                                store.deleteBoard(id: id)
                                dismiss()
                            }
                        }
                }
            }
            .navigationTitle(draft.boardID == nil ? "New page" : "Edit page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = draft.name.trimmingCharacters(in: .whitespaces)
                        let symbol = draft.symbol.trimmingCharacters(in: .whitespaces).isEmpty ? "📁" : draft.symbol
                        if let id = draft.boardID {
                            store.updateBoard(id: id, name: name, symbol: symbol)
                        } else {
                            store.addBoard(name: name, symbol: symbol)
                        }
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
