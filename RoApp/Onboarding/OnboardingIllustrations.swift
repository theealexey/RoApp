import SwiftUI

// MARK: - Page 0: Focus Circle
// Концепт: незамкнутый круг с точкой на конце — фокус, начало пути

struct FocusCircleIllustration: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.34
            let lineWidth: CGFloat = 2.5

            // Arc — 270° open circle
            let startAngle = Angle.degrees(-90)
            let endAngle = Angle.degrees(180)

            var arcPath = Path()
            arcPath.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )

            context.stroke(
                arcPath,
                with: .color(color),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )

            // Dot at the end of the arc
            let dotAngle = endAngle.radians
            let dotCenter = CGPoint(
                x: center.x + radius * cos(dotAngle),
                y: center.y + radius * sin(dotAngle)
            )
            let dotRadius: CGFloat = 5

            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: dotCenter.x - dotRadius,
                y: dotCenter.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fill(dotPath, with: .color(color))
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Page 1: Timer Flow
// Концепт: три горизонтальных блока (фокус-перерыв-фокус), соединённые стрелками

struct TimerFlowIllustration: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let centerY = size.height / 2
            let blockW: CGFloat = 28
            let blockH: CGFloat = 28
            let gap: CGFloat = 16
            let totalW = blockW * 3 + gap * 2
            let startX = (size.width - totalW) / 2
            let lineWidth: CGFloat = 2
            let cornerRadius: CGFloat = 6

            for i in 0..<3 {
                let x = startX + CGFloat(i) * (blockW + gap)
                let rect = CGRect(x: x, y: centerY - blockH / 2, width: blockW, height: blockH)

                // Middle block is smaller (break)
                if i == 1 {
                    let smallH: CGFloat = 18
                    let smallRect = CGRect(x: x, y: centerY - smallH / 2, width: blockW, height: smallH)
                    let path = Path(roundedRect: smallRect, cornerRadius: cornerRadius)
                    context.stroke(path, with: .color(color.opacity(0.5)), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                } else {
                    let path = Path(roundedRect: rect, cornerRadius: cornerRadius)
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }

                // Arrow between blocks
                if i < 2 {
                    let arrowStartX = x + blockW + 3
                    let arrowEndX = arrowStartX + gap - 6
                    var arrowPath = Path()
                    arrowPath.move(to: CGPoint(x: arrowStartX, y: centerY))
                    arrowPath.addLine(to: CGPoint(x: arrowEndX, y: centerY))
                    // Arrowhead
                    arrowPath.move(to: CGPoint(x: arrowEndX - 4, y: centerY - 3))
                    arrowPath.addLine(to: CGPoint(x: arrowEndX, y: centerY))
                    arrowPath.addLine(to: CGPoint(x: arrowEndX - 4, y: centerY + 3))

                    context.stroke(arrowPath, with: .color(color.opacity(0.4)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Page 2: Stack Layers
// Концепт: три наложенных прямоугольника со сдвигом — сессии, прогресс, накопление

struct StackLayersIllustration: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let w: CGFloat = 52
            let h: CGFloat = 32
            let offsetY: CGFloat = 10
            let lineWidth: CGFloat = 2
            let cornerRadius: CGFloat = 8

            for i in 0..<3 {
                let fi = CGFloat(2 - i) // draw back to front
                let y = centerY - h / 2 + fi * offsetY - offsetY
                let opacity = 0.3 + Double(i) * 0.3
                let rect = CGRect(x: centerX - w / 2, y: y, width: w, height: h)
                let path = Path(roundedRect: rect, cornerRadius: cornerRadius)
                context.stroke(path, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Page 3: Growth Arrow
// Концепт: стрелка вверх из точки — рост, прогресс, статистика (как у sashazavisha)

struct GrowthArrowIllustration: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let lineWidth: CGFloat = 2.5
            let arrowBottom = size.height * 0.7
            let arrowTop = size.height * 0.25
            let headSize: CGFloat = 12

            // Vertical line
            var linePath = Path()
            linePath.move(to: CGPoint(x: centerX, y: arrowBottom))
            linePath.addLine(to: CGPoint(x: centerX, y: arrowTop))

            context.stroke(linePath, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Arrowhead
            var headPath = Path()
            headPath.move(to: CGPoint(x: centerX - headSize, y: arrowTop + headSize))
            headPath.addLine(to: CGPoint(x: centerX, y: arrowTop))
            headPath.addLine(to: CGPoint(x: centerX + headSize, y: arrowTop + headSize))

            context.stroke(headPath, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            // Dot at bottom — starting point
            let dotRadius: CGFloat = 4
            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: centerX - dotRadius,
                y: arrowBottom - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fill(dotPath, with: .color(color))
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Empty State Illustration
// Пунктирный круг — ожидание первой сессии

struct EmptyStateIllustration: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.3

            var circle = Path()
            circle.addEllipse(in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))

            context.stroke(
                circle,
                with: .color(color),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 6])
            )
        }
        .frame(width: 64, height: 64)
    }
}

// MARK: - Paywall Hero
// Круг с тремя стрелками вверх — фокус ведёт к росту

struct PaywallHeroIllustration: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let radius = min(size.width, size.height) * 0.36
            let lineWidth: CGFloat = 2.5

            // Circle
            var circlePath = Path()
            circlePath.addEllipse(in: CGRect(
                x: centerX - radius,
                y: centerY - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.stroke(circlePath, with: .color(color.opacity(0.3)), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Three arrows pointing up inside the circle
            let arrowSpacing: CGFloat = 18
            let arrowHeight: CGFloat = 28
            let headSize: CGFloat = 7
            let arrowBaseY = centerY + arrowHeight * 0.35

            for i in -1...1 {
                let x = centerX + CGFloat(i) * arrowSpacing
                let topY = arrowBaseY - arrowHeight
                let height = i == 0 ? arrowHeight + 6 : arrowHeight // Center arrow taller

                var arrow = Path()
                arrow.move(to: CGPoint(x: x, y: arrowBaseY))
                arrow.addLine(to: CGPoint(x: x, y: arrowBaseY - height))

                // Head
                arrow.move(to: CGPoint(x: x - headSize, y: (arrowBaseY - height) + headSize))
                arrow.addLine(to: CGPoint(x: x, y: arrowBaseY - height))
                arrow.addLine(to: CGPoint(x: x + headSize, y: (arrowBaseY - height) + headSize))

                let opacity = i == 0 ? 1.0 : 0.6
                context.stroke(arrow, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: 140, height: 140)
    }
}
