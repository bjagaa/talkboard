import SwiftUI

/// A button that also supports optional in-app dwell: when the eye-tracker pointer rests on it
/// for the dwell time, a fill rises from the bottom and the button activates.
/// If the student uses AssistiveTouch Dwell Control instead, leave in-app dwell OFF in Settings.
struct DwellButton<Label: View>: View {
    @EnvironmentObject private var store: BoardStore
    private let dwellAllowed: Bool
    private let action: () -> Void
    private let label: Label

    @State private var progress: Double = 0
    @State private var dwellTask: Task<Void, Never>?

    init(dwellAllowed: Bool = true,
         action: @escaping () -> Void,
         @ViewBuilder label: () -> Label) {
        self.dwellAllowed = dwellAllowed
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .overlay(alignment: .bottom) {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.35))
                            .frame(height: geo.size.height * progress)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressStyle())
        .onHover { inside in
            dwellTask?.cancel()
            progress = 0
            guard inside, dwellAllowed, store.settings.dwellInApp else { return }
            let seconds = max(0.3, store.settings.dwellSeconds)
            dwellTask = Task { @MainActor in
                let start = Date()
                while !Task.isCancelled {
                    let p = Date().timeIntervalSince(start) / seconds
                    progress = min(1, p)
                    if p >= 1 {
                        progress = 0
                        action()
                        return
                    }
                    try? await Task.sleep(nanoseconds: 30_000_000)
                }
            }
        }
        .onDisappear { dwellTask?.cancel() }
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
