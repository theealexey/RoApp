import UIKit

// MARK: - Protocol

@MainActor
protocol HapticsServiceProtocol: AnyObject {
    func tap()
    func start()
    func pause()
    func finish()
    func reset()
}

// MARK: - Implementation

@MainActor
final class HapticsService: HapticsServiceProtocol {

    private let settingsStore: SettingsStoreProtocol

    init(settingsStore: SettingsStoreProtocol) {
        self.settingsStore = settingsStore
    }

    private lazy var light        = UIImpactFeedbackGenerator(style: .light)
    private lazy var medium       = UIImpactFeedbackGenerator(style: .medium)
    private lazy var heavy        = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var notification = UINotificationFeedbackGenerator()

    func tap() {
        guard settingsStore.hapticsEnabled else { return }
        light.prepare()
        light.impactOccurred()
    }

    func start() {
        guard settingsStore.hapticsEnabled else { return }
        medium.prepare()
        medium.impactOccurred(intensity: 0.85)
    }

    func pause() {
        guard settingsStore.hapticsEnabled else { return }
        light.prepare()
        light.impactOccurred(intensity: 0.6)
    }

    func finish() {
        guard settingsStore.hapticsEnabled else { return }
        notification.prepare()
        notification.notificationOccurred(.success)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            self?.heavy.impactOccurred(intensity: 0.7)
        }
    }

    func reset() {
        guard settingsStore.hapticsEnabled else { return }
        light.prepare()
        light.impactOccurred(intensity: 0.5)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(60))
            self?.light.impactOccurred(intensity: 0.35)
        }
    }
}
