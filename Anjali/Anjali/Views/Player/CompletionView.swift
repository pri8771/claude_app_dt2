import SwiftUI

/// Shown when a prayer completes. Offers Done / Repeat / Save.
struct CompletionView: View {
    let prayer: Prayer
    let theme: ThemePalette
    let onDone: () -> Void
    let onRepeat: () -> Void
    let onSave: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            theme.background.opacity(0.98).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "flame.fill")
                    .font(.largeTitle)
                    .foregroundStyle(theme.accent)
                    .shadow(color: theme.accent.opacity(0.6), radius: 20)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .accessibilityHidden(true)

                Text("May this action be steady.")
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(theme.foreground)
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onDone) {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
                    .accessibilityLabel("Done")
                    .accessibilityHint("Return to Today")

                    HStack(spacing: 12) {
                        Button(action: onRepeat) {
                            Label("Repeat", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .secondaryAction(theme: theme)
                        .accessibilityLabel("Repeat prayer")

                        Button(action: onSave) {
                            Label("Save this prayer", systemImage: "bookmark")
                                .frame(maxWidth: .infinity)
                        }
                        .secondaryAction(theme: theme)
                        .accessibilityLabel("Save this prayer")
                    }
                }
            }
            .padding(28)
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    appeared = true
                }
            }
        }
    }
}

private extension View {
    func secondaryAction(theme: ThemePalette) -> some View {
        self
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 14)
            .background(theme.foreground.opacity(0.12))
            .foregroundStyle(theme.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
