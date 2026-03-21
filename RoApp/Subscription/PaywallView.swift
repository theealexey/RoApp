import SwiftUI
import StoreKit

@MainActor
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var isRestoringPurchases = false
    @State private var isPurchasing = false
    @State private var isShowingErrorAlert = false

    var body: some View {
        ZStack {
            RoTheme.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerView
                    benefitsView
                    productsView
                    restoreSection
                    footerView
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .task {
            await subscriptionService.loadProducts()
            await subscriptionService.refresh()
        }
        .onChange(of: subscriptionService.isPro) { _, isPro in
            if isPro {
                dismiss()
            }
        }
        .onChange(of: subscriptionService.purchaseErrorMessage) { _, newValue in
            isShowingErrorAlert = newValue != nil
        }
        .alert(
            String(localized: "paywall.error.title", defaultValue: "Purchase Error"),
            isPresented: $isShowingErrorAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(
                subscriptionService.purchaseErrorMessage
                ?? String(localized: "paywall.error.fallback", defaultValue: "Something went wrong.")
            )
        }
    }

    private var headerView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RoTheme.Colors.accent.opacity(0.06))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)

                PaywallHeroIllustration(color: RoTheme.Colors.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(LocalizedStringKey("paywall.title"))
                    .font(.system(size: 28, weight: .thin))
                    .foregroundStyle(RoTheme.Colors.textPrimary)

                Text(LocalizedStringKey("paywall.subtitle"))
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 12)
    }

    private var benefitsView: some View {
        VStack(spacing: 12) {
            benefitRow(
                title: String(localized: "paywall.feature.stats", defaultValue: "Advanced statistics"),
                subtitle: String(localized: "paywall.feature.stats.desc", defaultValue: "See deeper progress and session history.")
            )

            benefitRow(
                title: String(localized: "paywall.feature.intervals", defaultValue: "Custom timer durations"),
                subtitle: String(localized: "paywall.feature.intervals.desc", defaultValue: "Tune focus and break lengths to your workflow.")
            )

            benefitRow(
                title: String(localized: "paywall.feature.widgets", defaultValue: "Widgets and premium polish"),
                subtitle: String(localized: "paywall.feature.widgets.desc", defaultValue: "A cleaner, more complete Ro experience.")
            )
        }
    }

    private func benefitRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(RoTheme.Colors.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RoTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(RoTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(cardBackground)
        .accessibilityElement(children: .combine)
    }

    private var productsView: some View {
        VStack(spacing: 12) {
            if subscriptionService.isLoading {
                ProgressView()
                    .tint(RoTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if subscriptionService.products.isEmpty {
                Text(LocalizedStringKey("paywall.products.unavailable"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RoTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(cardBackground)
            } else {
                ForEach(subscriptionService.products, id: \.id) { product in
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        Button {
            purchase(product)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(product.displayName)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(RoTheme.Colors.textPrimary)

                            if let badge = badgeText(for: product.id) {
                                Text(badge)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(RoTheme.Colors.background)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoTheme.Colors.textPrimary)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(product.description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(RoTheme.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(RoTheme.Colors.textPrimary)
                }

                if product.id == RoProduct.annual.rawValue {
                    Text(LocalizedStringKey("paywall.bestValue"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RoTheme.Colors.accent)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing || isRestoringPurchases)
        .opacity((isPurchasing || isRestoringPurchases) ? 0.7 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(productAccessibilityLabel(product))
        .accessibilityAddTraits(.isButton)
    }

    private func productAccessibilityLabel(_ product: Product) -> String {
        var parts = [product.displayName, product.displayPrice]
        if let badge = badgeText(for: product.id) {
            parts.append(badge)
        }
        return parts.joined(separator: ", ")
    }

    private var restoreSection: some View {
        VStack(spacing: 12) {
            Button {
                restorePurchases()
            } label: {
                HStack {
                    if isRestoringPurchases {
                        ProgressView()
                            .tint(RoTheme.Colors.textPrimary)
                    } else {
                        Text(LocalizedStringKey("paywall.restore"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundStyle(RoTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(cardBackground)
            }
            .buttonStyle(.plain)
            .disabled(isRestoringPurchases || isPurchasing)

            if subscriptionService.isPro {
                Text(LocalizedStringKey("paywall.pro.active"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RoTheme.Colors.accent)
            }
        }
    }

    private var footerView: some View {
        VStack(spacing: 8) {
            Text(LocalizedStringKey("paywall.terms"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(RoTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Button(String(localized: "paywall.close", defaultValue: "Close")) {
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(RoTheme.Colors.textSecondary)
        }
        .padding(.top, 8)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(RoTheme.Colors.surfaceGlass)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(RoTheme.Colors.borderSubtle, lineWidth: 1)
            }
    }

    private func purchase(_ product: Product) {
        guard !isPurchasing else { return }

        isPurchasing = true

        Task {
            await subscriptionService.purchase(product)
            isPurchasing = false
        }
    }

    private func restorePurchases() {
        guard !isRestoringPurchases else { return }

        isRestoringPurchases = true

        Task {
            await subscriptionService.restorePurchases()
            isRestoringPurchases = false
        }
    }

    private func badgeText(for productID: String) -> String? {
        switch productID {
        case RoProduct.annual.rawValue:
            return String(localized: "paywall.badge.bestValue", defaultValue: "BEST VALUE")
        case RoProduct.monthly.rawValue:
            return String(localized: "paywall.badge.flexible", defaultValue: "FLEXIBLE")
        default:
            return nil
        }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionService())
}
