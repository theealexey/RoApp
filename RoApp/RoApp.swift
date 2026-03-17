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
    }
}
