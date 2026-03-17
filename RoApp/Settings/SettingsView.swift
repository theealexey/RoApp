import SwiftUI
import Observation

enum SettingsViewModel {
    enum Keys {
        static let hasSeenOnboarding = "settings.hasSeenOnboarding"
    }
}

@MainActor
@Observable
final class SettingsScreenModel {
    private let settingsStore: SettingsStoreProtocol

    var focusMinutes: Int {
        didSet {
            settingsStore.focusDurationMinutes = focusMinutes
        }
    }

    var shortMinutes: Int {
        didSet {
            settingsStore.shortBreakDurationMinutes = shortMinutes
        }
    }

    var longMinutes: Int {
        didSet {
            settingsStore.longBreakDurationMinutes = longMinutes
        }
    }

    var hapticsEnabled: Bool {
        didSet {
            settingsStore.hapticsEnabled = hapticsEnabled
        }
    }

    var notificationsEnabled: Bool {
        didSet {
            settingsStore.notificationsEnabled = notificationsEnabled
        }
    }

    var autoStartBreak: Bool {
        didSet {
            settingsStore.autoStartBreaksEnabled = autoStartBreak
        }
    }

    init(settingsStore: SettingsStoreProtocol = SettingsStore()) {
        self.settingsStore = settingsStore
        self.focusMinutes = settingsStore.focusDurationMinutes
        self.shortMinutes = settingsStore.shortBreakDurationMinutes
        self.longMinutes = settingsStore.longBreakDurationMinutes
        self.hapticsEnabled = settingsStore.hapticsEnabled
        self.notificationsEnabled = settingsStore.notificationsEnabled
        self.autoStartBreak = settingsStore.autoStartBreaksEnabled
    }
}

@MainActor
struct SettingsView: View {
    @State private var model = SettingsScreenModel()
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionService.self) private var subscription

    var body: some View {
        ZStack {
            RoTheme.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    if !subscription.isPro { proBanner }
                    durationsSection
                    preferencesSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 52)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationBackground(RoTheme.Colors.background)
        }
        .onChange(of: model.notificationsEnabled) { _, isEnabled in
            guard isEnabled else { return }

            Task {
                let isAuthorized = await NotificationService.shared.requestAuthorization()
                if !isAuthorized {
                    model.notificationsEnabled = false
                }
            }
        }
    }

    private var proBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(RoTheme.Colors.accent.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Text("ro")
                        .font(.system(size: 13, weight: .ultraLight))
                        .foregroundStyle(RoTheme.Colors.accent)
                        .tracking(3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("settings.pro.title"))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(RoTheme.Colors.textPrimary)

                    Text(LocalizedStringKey("settings.pro.subtitle"))
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(RoTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(RoTheme.Colors.accent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(RoTheme.Colors.chipBorder.opacity(0.5), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack {
            Text(LocalizedStringKey("settings.title"))
                .font(RoTheme.Typography.modeLabel)
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .tracking(4)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var durationsSection: some View {
        SettingsSection(title: LocalizedStringKey("settings.durations")) {
            DurationRow(
                label: LocalizedStringKey("mode.focus"),
                value: $model.focusMinutes,
                range: 5...90
            )

            Divider()
                .background(RoTheme.Colors.borderSubtle)

            DurationRow(
                label: LocalizedStringKey("mode.short"),
                value: $model.shortMinutes,
                range: 1...30
            )

            Divider()
                .background(RoTheme.Colors.borderSubtle)

            DurationRow(
                label: LocalizedStringKey("mode.long"),
                value: $model.longMinutes,
                range: 5...60
            )
        }
    }

    private var preferencesSection: some View {
        SettingsSection(title: LocalizedStringKey("settings.preferences")) {
            ToggleRow(
                label: LocalizedStringKey("settings.haptics"),
                symbol: "waveform",
                isOn: $model.hapticsEnabled
            )

            Divider()
                .background(RoTheme.Colors.borderSubtle)

            ToggleRow(
                label: LocalizedStringKey("settings.notifications"),
                symbol: "bell",
                isOn: $model.notificationsEnabled
            )

            Divider()
                .background(RoTheme.Colors.borderSubtle)

            ToggleRow(
                label: LocalizedStringKey("settings.autoBreak"),
                symbol: "arrow.trianglehead.2.clockwise",
                isOn: $model.autoStartBreak
            )
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: LocalizedStringKey("settings.about")) {
            InfoRow(
                label: LocalizedStringKey("settings.version"),
                value: appVersion
            )

            Divider()
                .background(RoTheme.Colors.borderSubtle)

            InfoRow(
                label: LocalizedStringKey("settings.build"),
                value: buildNumber
            )
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

private struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(RoTheme.Typography.modeLabel)
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(RoTheme.Colors.surfaceGlass)
            )
        }
    }
}

private struct DurationRow: View {
    let label: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(RoTheme.Colors.textPrimary)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RoTheme.Colors.textTertiary)
                        .frame(
                            width: RoTheme.Layout.settingsButtonSize,
                            height: RoTheme.Layout.settingsButtonSize
                        )
                        .contentShape(Circle())
                        .background(Circle().fill(RoTheme.Colors.surfaceGlass))
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.system(size: 18, weight: .thin))
                    .foregroundStyle(RoTheme.Colors.textPrimary)
                    .monospacedDigit()
                    .frame(minWidth: 28, alignment: .center)
                    .contentTransition(.numericText())

                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RoTheme.Colors.textTertiary)
                        .frame(
                            width: RoTheme.Layout.settingsButtonSize,
                            height: RoTheme.Layout.settingsButtonSize
                        )
                        .contentShape(Circle())
                        .background(Circle().fill(RoTheme.Colors.surfaceGlass))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(value)")
        .accessibilityHint(String(localized: "a11y.duration.hint", defaultValue: "Adjustable"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if value < range.upperBound { value += 1 }
            case .decrement:
                if value > range.lowerBound { value -= 1 }
            @unknown default:
                break
            }
        }
    }
}

private struct ToggleRow: View {
    let label: LocalizedStringKey
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(RoTheme.Colors.accent.opacity(0.7))
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(label)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textPrimary)
            }
        }
        .tint(RoTheme.Colors.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct InfoRow: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(RoTheme.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionService())
}
