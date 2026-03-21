import SwiftUI

private struct OnboardingPage: Identifiable {
    let id: Int
    let illustration: AnyView
    let title: LocalizedStringKey
    let body: LocalizedStringKey
}

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var currentPage = 0

    private var pages: [OnboardingPage] {
        let color = RoTheme.Colors.accent
        return [
            OnboardingPage(
                id: 0,
                illustration: AnyView(FocusCircleIllustration(color: color)),
                title: "onboarding.title.0",
                body: "onboarding.body.0"
            ),
            OnboardingPage(
                id: 1,
                illustration: AnyView(TimerFlowIllustration(color: color)),
                title: "onboarding.title.1",
                body: "onboarding.body.1"
            ),
            OnboardingPage(
                id: 2,
                illustration: AnyView(StackLayersIllustration(color: color)),
                title: "onboarding.title.2",
                body: "onboarding.body.2"
            ),
            OnboardingPage(
                id: 3,
                illustration: AnyView(GrowthArrowIllustration(color: color)),
                title: "onboarding.title.3",
                body: "onboarding.body.3"
            )
        ]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoTheme.Colors.background
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(pages) { page in
                    PageView(page: page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            bottomOverlay
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .zIndex(1000)
        }
    }

    private var bottomOverlay: some View {
        VStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(pages) { page in
                    Capsule()
                        .fill(
                            currentPage == page.id
                            ? RoTheme.Colors.accent
                            : RoTheme.Colors.textGhost
                        )
                        .frame(width: currentPage == page.id ? 18 : 6, height: 6)
                        .animation(RoTheme.Animation.standard, value: currentPage)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)

            HStack {
                Spacer()

                Button(action: handlePrimaryButtonTap) {
                    HStack(spacing: 8) {
                        Text(
                            currentPage < pages.count - 1
                            ? String(localized: "onboarding.next", defaultValue: "Далее")
                            : String(localized: "onboarding.start", defaultValue: "Начать")
                        )
                        .font(.system(size: 17, weight: .regular))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(RoTheme.Colors.textPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(RoTheme.Colors.accent.opacity(0.20))
                            .overlay(
                                Capsule()
                                    .strokeBorder(RoTheme.Colors.chipBorder, lineWidth: 0.5)
                            )
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minWidth: 132, minHeight: 52)
                .background(Color.clear)
                .accessibilityHint(
                    currentPage < pages.count - 1
                        ? String(localized: "a11y.onboarding.next.hint", defaultValue: "Goes to next page")
                        : String(localized: "a11y.onboarding.start.hint", defaultValue: "Starts the app")
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(RoTheme.Colors.background.opacity(0.92))
        )
    }

    private func handlePrimaryButtonTap() {
        if currentPage < pages.count - 1 {
            withAnimation(RoTheme.Animation.standard) {
                currentPage += 1
            }
        } else {
            onFinish()
        }
    }
}

private struct PageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(RoTheme.Colors.accent.opacity(0.06))
                    .frame(width: 160, height: 160)
                    .blur(radius: 30)
                    .allowsHitTesting(false)

                page.illustration
                    .allowsHitTesting(false)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 26, weight: .thin))
                    .foregroundStyle(RoTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(RoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 120)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
