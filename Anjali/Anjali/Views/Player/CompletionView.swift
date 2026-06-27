import SwiftUI

/// Shown when a prayer completes. Offers Done / Repeat / Save.
struct CompletionView: View {
    let prayer: Prayer
    let theme: ThemePalette
    let onDone: () -> Void
    let onRepeat: () -> Void
    let onSave: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            theme.background.opacity(0.98).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(theme.accent)
                    .shadow(color: theme.accent.opacity(0.6), radius: 20)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Text("May this action be steady.")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(theme.foreground)
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onDone) {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))

                    HStack(spacing: 12) {
                        Button(action: onRepeat) {
                            Label("Repeat", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .secondaryAction(theme: theme)

                        Button(action: onSave) {
                            Label("Save this prayer", systemImage: "bookmark")
                                .frame(maxWidth: .infinity)
                        }
                        .secondaryAction(theme: theme)
                    }
                }
            }
            .padding(28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                appeared = true
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
