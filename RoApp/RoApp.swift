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
    private let settingsStore: SettingsStoreProtocol
    @State private var hasSeenOnboarding: Bool
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    @Environment(\.modelContext) private var modelContext

    init(settingsStore: SettingsStoreProtocol = SettingsStore()) {
        self.settingsStore = settingsStore
        _hasSeenOnboarding = State(initialValue: settingsStore.hasSeenOnboarding)
    }

    var body: some View {
        Group {
            if hasSeenOnboarding {
                ContentView(
                    repository: SessionRepository(context: modelContext)
                )
            } else {
                OnboardingView {
                    settingsStore.hasSeenOnboarding = true
                    hasSeenOnboarding = true
                }
            }
        }
        .preferredColorScheme(
            (AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme
        )
    }
}
