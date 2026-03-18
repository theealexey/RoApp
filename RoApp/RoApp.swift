import SwiftUI
import SwiftData

@main
struct RoApp: App {
    @State private var subscriptionService = SubscriptionService()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(subscriptionService)
        }
        .modelContainer(for: FocusSession.self)
    }
}

struct AppRootView: View {
    @State private var hasSeenOnboarding =
        UserDefaults.standard.bool(forKey: SettingsViewModel.Keys.hasSeenOnboarding)
    @State private var settingsStore = SettingsStore()

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if hasSeenOnboarding {
                ContentView(
                    repository: SessionRepository(context: modelContext)
                )
            } else {
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: SettingsViewModel.Keys.hasSeenOnboarding)
                    hasSeenOnboarding = true
                }
            }
        }
        .preferredColorScheme(resolvedColorScheme)
    }

    private var resolvedColorScheme: ColorScheme? {
        switch settingsStore.appearanceMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
