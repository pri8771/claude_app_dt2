import SwiftUI

/// Two-screen first-launch onboarding:
///  1. Wordmark + tagline.
///  2. A few gentle preferences (script + ishta devata).
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var page = 0

    // Local draft of preferences, committed on finish.
    @State private var script: ScriptPreference = .both
    @State private var ishta: Deity?

    private let theme = ThemePalette.palette(for: .dawn)

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            TabView(selection: $page) {
                welcome.tag(0)
                preferences.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Screen 1

    private var welcome: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Anjali")
                .font(.system(size: 64, weight: .light, design: .serif))
                .foregroundStyle(theme.accent)
            Text("A sacred pause for everyday life")
                .font(.title3)
                .foregroundStyle(theme.foreground.opacity(0.85))
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                withAnimation { page = 1 }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }

    // MARK: Screen 2

    private var preferences: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("A few quiet choices")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(theme.foreground)
                Text("You can change these anytime in Me.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryForeground)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Script")
                    .font(.headline)
                    .foregroundStyle(theme.foreground)
                Picker("Script", selection: $script) {
                    ForEach(ScriptPreference.allCases) { pref in
                        Text(pref.displayName).tag(pref)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Ishta devata")
                    .font(.headline)
                    .foregroundStyle(theme.foreground)
                Text("A deity close to your heart, if you have one.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryForeground)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        deityChip(nil, label: "None")
                        ForEach(Deity.allCases) { deity in
                            deityChip(deity, label: deity.displayName)
                        }
                    }
                }
            }

            Spacer()

            Button {
                finish()
            } label: {
                Text("Enter")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 32)
        .padding(.top, 64)
    }

    private func deityChip(_ deity: Deity?, label: String) -> some View {
        let isSelected = ishta == deity
        return Button {
            ishta = deity
        } label: {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? theme.accent : Color.white.opacity(0.12))
                .foregroundStyle(isSelected ? Color(hex: "1A1208") : theme.foreground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        settings.scriptPreference = script
        settings.ishtaDevata = ishta
        withAnimation {
            settings.hasCompletedOnboarding = true
        }
    }
}
