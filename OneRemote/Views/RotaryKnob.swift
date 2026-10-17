import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Endlessly rotatable knob with a white LED ring, modeled on the control knobs of the ONE HD.
///
/// It is turned with the finger along the circular path. Only the change in angle counts (relative),
/// so the knob never jumps to the spot that is touched. For every `degreesPerStep` degrees
/// `onStep` is called, with at most `maxStepsPerUpdate` steps per touch event,
/// so that a hectic movement does not cause a big jump. A short tap calls `onTap`.
struct RotaryKnob: View {
    enum Ring {
        /// Level display, LEDs from the bottom left clockwise
        /// `usable`: LEDs from this index on are above the volume limit and are drawn almost invisible
        /// `count` LEDs light up starting at index `lit` (normally 1, as on the device; with AV Direct the top 3)
        case level(lit: Int, of: Int, from: Double, to: Double, usable: Int, count: Int)
        /// Position display: exactly one LED lights up, `index` -1 means none
        case position(index: Int, count: Int)
        /// Like the source selector on the device: LEDs only on an arc to the right of the knob (angle from 12 o'clock,
        /// clockwise), one small label per LED. `index` -1 means none.
        case arc(index: Int, labels: [String], from: Double, to: Double)
    }

    var ring: Ring
    var centerTop: String
    /// Symbol (see `InputSymbol`) in front of the text in the center, like the digit for inputs 3 and 4
    var centerSymbol: String?
    var centerBottom = ""
    var degreesPerStep: Double
    var maxStepsPerUpdate = 4
    var enabled = true
    /// Dim lit LEDs, for example when muted
    var ringDim = false
    /// Temporarily turn off the lit LED of the input arc (for blinking on an input change)
    var blinkOff = false
    /// Indices of the arc labels that are printed red on the device (Bluetooth, USB, 3 and 4)
    var redLabels: Set<Int> = []
    /// Share of the knob surface in the overall size; the rest is left for LEDs and labels
    var bodyScale = 0.78
    /// Radius of the LED ring relative to the overall size
    var ledRadius = 0.455
    var onStep: (Int) -> Void
    var onTap: () -> Void = {}
    /// Tapping an LED or label of the input arc (index of the position)
    var onSelect: (Int) -> Void = { _ in }
    /// If set, the rotation in degrees is reported instead of whole steps (for a custom, non-linear scale)
    var onDegrees: ((Double) -> Void)?
    /// VoiceOver: name, spoken value, usage hint and the action for swiping up (+1) or down (-1)
    var accessibilityName: LocalizedStringKey = ""
    var accessibilityText = ""
    var accessibilityUsage: LocalizedStringKey = ""
    var onAdjust: (Int) -> Void = { _ in }

    @State private var rotation = 0.0
    @State private var accumulated = 0.0
    @State private var lastAngle: Double?
    @State private var maxDistance: CGFloat = 0
    @State private var startTime: Date?

    #if canImport(UIKit)
    private let haptic = UISelectionFeedbackGenerator()
    #endif

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ledRing(size: s)
                knobBody(size: s)
                centerText(size: s)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Circle())
            .gesture(drag(center: center, size: s))
            .opacity(enabled ? 1 : 0.35)
            // The knob is one adjustable element for VoiceOver (the LEDs and tap areas are hidden)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityName)
            .accessibilityValue(accessibilityText)
            .accessibilityHint(accessibilityUsage)
            .accessibilityAdjustableAction { direction in
                guard enabled else { return }
                switch direction {
                case .increment: onAdjust(1)
                case .decrement: onAdjust(-1)
                @unknown default: break
                }
            }
            .accessibilityAction { if enabled { onTap() } }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Appearance

    @ViewBuilder
    private func ledRing(size s: CGFloat) -> some View {
        let radius = s * ledRadius
        switch ring {
        case let .arc(index, labels, from, to):
            let n = labels.count
            ForEach(0..<n, id: \.self) { i in
                let t = n > 1 ? Double(i) / Double(n - 1) : 0
                let deg = from + (to - from) * t
                let rad = (deg - 90) * .pi / 180
                let lr = radius + s * 0.065
                led(on: i == index && !blinkOff, big: false, size: s)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(deg))
                Group {
                    if labels[i].hasPrefix("@") {
                        InputSymbolView(kind: String(labels[i].dropFirst()),
                                        color: labelColor(i, active: i == index),
                                        lineWidth: max(1, s * 0.0055))
                            .frame(width: s * 0.06, height: s * 0.06)
                    } else {
                        Text(labels[i])
                            .font(.system(size: s * 0.042, weight: .regular))
                            .foregroundStyle(labelColor(i, active: i == index))
                            .fixedSize()
                    }
                }
                .offset(x: cos(rad) * lr, y: sin(rad) * lr)
                // Tap area over LED and label: selects the input directly
                Color.clear
                    .frame(width: s * 0.17, height: s * 0.08)
                    .contentShape(Rectangle())
                    .offset(x: cos(rad) * (radius + s * 0.05), y: sin(rad) * (radius + s * 0.05))
                    .onTapGesture {
                        #if canImport(UIKit)
                        haptic.selectionChanged()
                        #endif
                        onSelect(i)
                    }
            }
        case let .level(lit, total, from, to, usable, count):
            // As in the manual: no full circle, a gap remains at the bottom
            ForEach(0..<total, id: \.self) { i in
                let t = total > 1 ? Double(i) / Double(total - 1) : 0
                led(on: i >= lit && i < lit + count, big: false, size: s)
                    .opacity(i < usable ? 1 : 0.35)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(from + (to - from) * t))
            }
        case let .position(index, count):
            ForEach(0..<count, id: \.self) { i in
                led(on: i == index, big: true, size: s)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) / Double(count) * 360))
            }
        }
    }

    /// Red as printed on the device, otherwise white; the active input is brighter
    private func labelColor(_ i: Int, active: Bool) -> Color {
        if redLabels.contains(i) {
            return Color(red: 0.86, green: 0.14, blue: 0.14).opacity(active ? 1 : 0.7)
        }
        return Color.white.opacity(active ? 0.95 : 0.4)
    }

    private func led(on: Bool, big: Bool, size s: CGFloat) -> some View {
        let base = s * (big ? 0.034 : 0.03)
        let d = (on && big) ? base * 1.5 : base
        return Circle()
            .fill(on ? Color.white.opacity(ringDim ? 0.3 : 1) : Color.white.opacity(0.10))
            .frame(width: d, height: d)
            .shadow(color: on && !ringDim ? Color.white.opacity(0.9) : Color.clear, radius: s * 0.012)
            .animation(.easeOut(duration: 0.12), value: on)
    }

    private func knobBody(size s: CGFloat) -> some View {
        let d = s * bodyScale
        return ZStack {
            // Flat, matte front surface like on the device, just a very subtle gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.115), Color(white: 0.055)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        }
        .frame(width: d, height: d)
        .shadow(color: Color.black.opacity(0.8), radius: s * 0.03, y: s * 0.015)
    }

    private func centerText(size s: CGFloat) -> some View {
        VStack(spacing: 2) {
            // A leading sign hangs to the left of the digits and does not count towards centering
            let sign = centerTop.first.map { "\u{2212}+-".contains($0) ? String($0) : "" } ?? ""
            let digits = String(centerTop.dropFirst(sign.count))
            // The invisible sign on the right balances the visible one on the left, so the digits sit centered
            HStack(spacing: s * 0.025) {
                if let symbol = centerSymbol {
                    InputSymbolView(kind: symbol, color: .white, lineWidth: max(1, s * 0.006))
                        .frame(width: s * 0.075, height: s * 0.075)
                }
                HStack(spacing: 0) {
                    Text(sign)
                    Text(digits)
                    Text(sign).opacity(0)
                }
                .font(.system(size: s * 0.13, weight: .thin))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            }
            if !centerBottom.isEmpty {
                Text(centerBottom)
                    .font(.system(size: s * 0.05, weight: .regular))
                    .tracking(2)
                    .opacity(0.5)
            }
        }
        .foregroundStyle(Color.white)
        .frame(width: s * 0.5)
        .allowsHitTesting(false)
    }

    // MARK: Gesture

    private func drag(center: CGPoint, size s: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard enabled else { return }
                if startTime == nil { startTime = Date() }
                maxDistance = max(maxDistance, hypot(value.translation.width, value.translation.height))

                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                // Near the center the angle is unstable, so there is no turning there
                guard hypot(dx, dy) > s * 0.10 else {
                    lastAngle = nil
                    return
                }
                let angle = atan2(dy, dx) * 180 / .pi
                if let last = lastAngle {
                    var delta = angle - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    turn(by: delta)
                }
                lastAngle = angle
            }
            .onEnded { _ in
                let isTap = enabled
                    && maxDistance < 8
                    && Date().timeIntervalSince(startTime ?? Date()) < 0.5
                lastAngle = nil
                accumulated = 0
                maxDistance = 0
                startTime = nil
                if isTap { onTap() }
            }
    }

    private func turn(by delta: Double) {
        if let onDegrees = onDegrees {
            onDegrees(delta)
            return
        }
        rotation += delta
        accumulated += delta
        let steps = Int((accumulated / degreesPerStep).rounded(.towardZero))
        guard steps != 0 else { return }
        accumulated -= Double(steps) * degreesPerStep
        onStep(max(-maxStepsPerUpdate, min(maxStepsPerUpdate, steps)))
        #if canImport(UIKit)
        haptic.selectionChanged()
        #endif
    }
}


/// Symbols of the inputs as on the front panel of the One HD (Bluetooth, USB, turntable),
/// as a line drawing in a square.
struct InputSymbol: Shape {
    var kind: String

    func path(in r: CGRect) -> Path {
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * y)
        }
        var p = Path()
        switch kind {
        case "bluetooth":
            // Rune: center stroke with two points on the right and crossed lines on the left
            p.move(to: pt(0.30, 0.30)); p.addLine(to: pt(0.70, 0.70)); p.addLine(to: pt(0.50, 0.90))
            p.addLine(to: pt(0.50, 0.10)); p.addLine(to: pt(0.70, 0.30)); p.addLine(to: pt(0.30, 0.70))
        case "usb":
            // Lines: stem plus one branch each on the left and right with a vertical end
            p.move(to: pt(0.50, 0.10)); p.addLine(to: pt(0.50, 0.93))
            p.move(to: pt(0.50, 0.64)); p.addLine(to: pt(0.28, 0.50)); p.addLine(to: pt(0.28, 0.33))
            p.move(to: pt(0.50, 0.50)); p.addLine(to: pt(0.72, 0.36)); p.addLine(to: pt(0.72, 0.27))
        case "usbSolids":
            // Filled parts: arrow head at the top, circle at the bottom, circle on the left, square on the right
            p.move(to: pt(0.50, 0.0)); p.addLine(to: pt(0.59, 0.15)); p.addLine(to: pt(0.41, 0.15)); p.closeSubpath()
            p.addEllipse(in: CGRect(x: r.minX + r.width * 0.435, y: r.minY + r.height * 0.865,
                                    width: r.width * 0.13, height: r.height * 0.13))
            p.addEllipse(in: CGRect(x: r.minX + r.width * 0.215, y: r.minY + r.height * 0.245,
                                    width: r.width * 0.13, height: r.height * 0.13))
            p.addRect(CGRect(x: r.minX + r.width * 0.655, y: r.minY + r.height * 0.14,
                             width: r.width * 0.13, height: r.height * 0.13))
        default:
            // Turntable: record with center hole, tonearm on the right
            p.addEllipse(in: CGRect(x: r.minX, y: r.minY + r.height * 0.20,
                                    width: r.width * 0.72, height: r.height * 0.72))
            p.addEllipse(in: CGRect(x: r.minX + r.width * 0.31, y: r.minY + r.height * 0.51,
                                    width: r.width * 0.10, height: r.height * 0.10))
            p.move(to: pt(0.90, 0.10)); p.addLine(to: pt(0.90, 0.55)); p.addLine(to: pt(0.74, 0.80))
            p.addRect(CGRect(x: r.minX + r.width * 0.84, y: r.minY, width: r.width * 0.12, height: r.height * 0.18))
        }
        return p
    }
}


/// Draws an input symbol with lines, for USB additionally with filled parts.
struct InputSymbolView: View {
    var kind: String
    var color: Color
    var lineWidth: CGFloat

    var body: some View {
        ZStack {
            InputSymbol(kind: kind)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            if kind == "usb" {
                InputSymbol(kind: "usbSolids").fill(color)
            }
        }
    }
}


/// Straight swiping next to turning: swiping right or up increases, left or down
/// decreases. The gesture applies to the whole area around the knob and keeps running even when the finger
/// leaves the area. Turning on the knob itself takes precedence.
/// A distance of `size` points corresponds to a rotation of 135 degrees.
struct ScrubGesture: ViewModifier {
    var size: CGFloat
    var degreesPerStep: Double
    var onStep: (Int) -> Void
    /// If set, the movement in degrees is reported instead of whole steps
    var onDegrees: ((Double) -> Void)?

    @State private var lastPoint: CGPoint?
    @State private var accumulated = 0.0

    #if canImport(UIKit)
    private let haptic = UISelectionFeedbackGenerator()
    #endif

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { value in
                        if let last = lastPoint {
                            let d = (value.location.x - last.x) - (value.location.y - last.y)
                            let deg = Double(d / max(size, 1)) * 135
                            if let onDegrees = onDegrees {
                                onDegrees(deg)
                                lastPoint = value.location
                                return
                            }
                            accumulated += deg
                            let steps = Int((accumulated / degreesPerStep).rounded(.towardZero))
                            if steps != 0 {
                                accumulated -= Double(steps) * degreesPerStep
                                onStep(max(-4, min(4, steps)))
                                #if canImport(UIKit)
                                haptic.selectionChanged()
                                #endif
                            }
                        }
                        lastPoint = value.location
                    }
                    .onEnded { _ in
                        lastPoint = nil
                        accumulated = 0
                    }
            )
    }
}
