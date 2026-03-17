import SwiftUI

struct RoBackground: View {
    let vm: TimerViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Double = 0

    var body: some View {
        ZStack {
            RoTheme.Colors.background
                .ignoresSafeArea()
            AmbientOrb(state: vm.state, phase: phase)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear { startBreathing() }
        .onChange(of: vm.state) { _, _ in
            phase = 0
            startBreathing()
        }
    }

    private func startBreathing() {
        guard !reduceMotion else {
            phase = 0.5
            return
        }

        withAnimation(
            .easeInOut(duration: breathDuration)
            .repeatForever(autoreverses: true)
        ) {
            phase = 1
        }
    }

    private var breathDuration: Double {
        switch vm.state {
        case .running:  4.0
        case .paused:   6.0
        case .finished: 1.5
        case .idle:     8.0
        }
    }
}

private struct AmbientOrb: View {
    let state: TimerState
    let phase: Double

    var body: some View {
        Ellipse()
            .fill(state.orbColor.opacity(0.07 + phase * 0.05))
            .frame(width: RoTheme.Layout.orbDiameter, height: RoTheme.Layout.orbDiameter)
            .blur(radius: RoTheme.Layout.orbBlur)
            .scaleEffect(0.88 + phase * 0.14)
    }
}
