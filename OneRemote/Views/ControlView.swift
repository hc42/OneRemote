import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Main page: two large endless rotary controls on a black background, like on the amplifier.
/// As on the device: source selector on the left or top, volume on the right or bottom (tapping mutes).
/// Everything else lives in `SettingsView`, reachable via the gear icon at the top right.
struct ControlView: View {
    @EnvironmentObject var c: AmpController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Last state of the LED display, needed for the hysteresis between turning up and down
    @State private var lastLEDIndex = 0
    /// The input LED blinks after a change (on the device: 3 s long, 2 blinks per second; here: 1.5 s, 4 per second)
    @State private var inputBlinkOff = false
    @State private var inputBlinkTask: Task<Void, Never>?
    @State private var previousInput: AmpInput?
    @Environment(\.scenePhase) private var scenePhase
    /// Sensitivity of turning and swiping, adjustable in the settings (0 = sluggish, 1 = sensitive)
    @AppStorage("knobSensitivity2") private var sensitivity = 0.5

    /// The turn angle per step is multiplied by this factor: 12 (sluggish) through 6 (middle) to 3 (sensitive)
    private var slowdown: Double { 3 * pow(4, 1 - sensitivity) }
    /// Turn angle for the way from one LED to the next. The scale is not linear in dB, so one dB
    /// needs a different amount of travel depending on the range (see `scrubVolume`).
    private var volumeDegreesPerLED: Double { 20 * slowdown }
    /// Position while scrolling the volume, in LED units (0 to 20, with fractions)
    @State private var scrubPos: Double?
    /// Fractions of a step from the mouse wheel over the input knob
    @State private var inputScrollAcc = 0.0
    @State private var scrubTime = Date.distantPast
    private var inputDegreesPerStep: Double { 16 * slowdown }
    /// No blinking until then: after opening, unlocking or connecting, the app fetches the input again,
    /// which is not a change the user witnesses
    @State private var blinkQuietUntil = Date.distantPast

    /// As in the manual (front panel schematic, page 7 of the user instructions): LEDs from bottom left
    /// (-128 deg) over the top to bottom right (+128 deg), with a gap at the bottom. For the count (21) see `ledUpDB`.
    /// The LEDs sit close to the knob edge (radius about 1.08 times).
    private let volumeLEDs = 21

    /// Both knobs have the same size (as on the device); the rest of the area is left for LEDs and labels
    private static let bodyScale = 0.74

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height * 1.15
            let knob = knobSize(in: geo.size, wide: wide)
            Group {
                if wide {
                    HStack(spacing: 16) {
                        inputZone(knob)
                        volumeZone(knob)
                    }
                } else {
                    VStack(spacing: 8) {
                        inputZone(knob)
                        volumeZone(knob)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
        .background(keyboardShortcuts)
        .onChange(of: c.volume) { v in
            let newIndex = ledIndex(for: v, previous: lastLEDIndex)
            #if canImport(UIKit)
            if newIndex != lastLEDIndex { UISelectionFeedbackGenerator().selectionChanged() }
            #endif
            lastLEDIndex = newIndex
        }
        .onChange(of: c.input) { new in
            // Only real changes blink, not the first reading of the input after connecting
            let changed = previousInput != nil && new != nil && new != previousInput
                && scenePhase == .active && Date() >= blinkQuietUntil && !reduceMotion
            previousInput = new
            if changed { startInputBlink() } else if new == nil { stopInputBlink() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { blinkQuietUntil = Date().addingTimeInterval(2) }
        }
        .onAppear {
            previousInput = c.input
            blinkQuietUntil = Date().addingTimeInterval(2)
        }
        .onDisappear { stopInputBlink() }
        .toolbar {
            ToolbarItem {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        #if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        #endif
    }

    // MARK: Keyboard

    /// Invisible buttons that provide the keyboard shortcuts (Mac, and iPad with a keyboard):
    /// up/down = volume, left/right = input, space = mute
    private var keyboardShortcuts: some View {
        Group {
            Button("") { c.setVolume(c.volume + 1) }.keyboardShortcut(.upArrow, modifiers: [])
            Button("") { c.setVolume(c.volume - 1) }.keyboardShortcut(.downArrow, modifiers: [])
            Button("") { c.stepInput(1) }.keyboardShortcut(.rightArrow, modifiers: [])
            Button("") { c.stepInput(-1) }.keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { c.toggleMute() }.keyboardShortcut(.space, modifiers: [])
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    // MARK: Swipe areas

    /// The area around the knob accepts straight swiping (right/up more, left/down less);
    /// turning takes precedence on the knob itself.
    private func inputZone(_ size: CGFloat) -> some View {
        inputKnob(size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(ScrubGesture(size: size, degreesPerStep: inputDegreesPerStep, onStep: { c.stepInput($0) }))
            .scrollWheel { notches in
                inputScrollAcc += notches
                let steps = Int(inputScrollAcc.rounded(.towardZero))
                if steps != 0 {
                    inputScrollAcc -= Double(steps)
                    c.stepInput(max(-4, min(4, steps)))
                }
            }
    }

    private func volumeZone(_ size: CGFloat) -> some View {
        volumeKnob(size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(ScrubGesture(size: size, degreesPerStep: volumeDegreesPerLED,
                                   onStep: { _ in }, onDegrees: { scrubVolume($0) }))
            // Mouse wheel (macOS): one notch is a third of an LED step
            .scrollWheel { scrubVolume($0 * 0.33 * volumeDegreesPerLED) }
    }

    // MARK: Volume

    private func volumeKnob(_ size: CGFloat) -> some View {
        // The LEDs stand for the real range of the amplifier (0 to 90), not 0 up to the limit.
        // This makes the display match the device. LEDs above the configured limit are dimmed.
        let locked = c.volumeLocked
        // On the device exactly one LED lights up (the current value). With AV Direct and source AV the
        // volume is fixed at a high level, then the three highest LEDs light up.
        let lit = locked ? volumeLEDs - 3 : ledIndex(for: c.volume, previous: lastLEDIndex)
        let usable = locked ? volumeLEDs : ledIndex(for: c.maxVolume, previous: 0) + 1
        let number = AmpBLE.dbText(c.volume).replacingOccurrences(of: " dB", with: "")

        // Negative spacing: the label moves into the empty margin below the knob (there are no LEDs at the bottom)
        return VStack(spacing: -size * 0.09) {
            RotaryKnob(
                ring: .level(lit: lit, of: volumeLEDs, from: -128, to: 128, usable: usable, count: locked ? 3 : 1),
                centerTop: c.muted ? "MUTE" : (locked ? String(localized: "FIXED") : number),
                centerBottom: (c.muted || locked) ? "" : "dB",
                degreesPerStep: volumeDegreesPerLED,
                enabled: !locked,
                ringDim: c.muted,
                bodyScale: Self.bodyScale,
                ledRadius: Self.bodyScale / 2 * 1.08,
                onStep: { _ in },
                onTap: { c.toggleMute() },
                onDegrees: { scrubVolume($0) },
                accessibilityName: "Volume",
                accessibilityText: c.muted ? String(localized: "Muted")
                    : (c.volumeLocked ? String(localized: "Fixed") : AmpBLE.dbText(c.volume)),
                accessibilityUsage: "Swipe up or down to change the volume. Double tap to mute or unmute.",
                onAdjust: { c.setVolume(c.volume + $0) }
            )
            .frame(width: size, height: size)
            caption("Volume")
        }
    }

    // MARK: Input

    private func inputKnob(_ size: CGFloat) -> some View {
        let all = AmpInput.allCases
        let index = c.input.flatMap { all.firstIndex(of: $0) } ?? -1

        // Negative spacing: the label moves into the empty margin below the knob (there are no LEDs at the bottom)
        return VStack(spacing: -size * 0.09) {
            RotaryKnob(
                ring: .arc(index: index, labels: all.map(\.shortTitle), from: 31, to: 122),
                centerTop: c.input?.title ?? "–",
                centerSymbol: c.input?.symbolKind,
                degreesPerStep: inputDegreesPerStep,
                blinkOff: inputBlinkOff,
                redLabels: [0, 1, 2, 3],
                bodyScale: Self.bodyScale,
                ledRadius: Self.bodyScale / 2 * 1.08,
                onStep: { c.stepInput($0) },
                onSelect: { c.select(all[$0]) },
                accessibilityName: "Input",
                accessibilityText: c.input?.title ?? String(localized: "Unknown"),
                accessibilityUsage: "Swipe up or down to change the input.",
                onAdjust: { c.stepInput($0) }
            )
            .frame(width: size, height: size)
            caption("Input")
        }
    }

    // MARK: Helpers

    /// Anchor points of the scale in dB: LED k starts at `ledKnotsDB[k]` when turning up (the first one at 0 = -90 dB).
    /// Values in between are interpolated linearly.
    private static let ledKnotsDB: [Double] = [
        -90, -88, -69, -54, -43, -36, -33, -30, -27, -23, -21,
        -18, -15, -12, -9, -6, -4, -3, -2, -1, 0,
    ]

    /// Position in LED units (0 to 20) for a dB value
    private func scalePosition(forDB db: Double) -> Double {
        let k = Self.ledKnotsDB
        guard db > k[0] else { return 0 }
        guard db < k[k.count - 1] else { return Double(k.count - 1) }
        let i = k.lastIndex(where: { $0 <= db }) ?? 0
        return Double(i) + (db - k[i]) / (k[i + 1] - k[i])
    }

    /// dB value for a position in LED units
    private func scaleDB(forPosition p: Double) -> Double {
        let k = Self.ledKnotsDB
        let i = min(k.count - 2, max(0, Int(p.rounded(.down))))
        return k[i] + (p - Double(i)) * (k[i + 1] - k[i])
    }

    /// Scrolling the volume: the way from LED to LED is always the same length, while the volume value in between
    /// changes in single dB steps. Where the LED steps are far apart (for example -88 to -69),
    /// the way per dB is short, at the last LEDs (-3 to 0) it is long. `degrees` is the finger movement.
    private func scrubVolume(_ degrees: Double) {
        guard !c.volumeLocked else { return }
        let now = Date()
        // The intermediate position remembers fractions of a dB; after a pause it starts again from the device value
        var pos = scrubPos.flatMap { now.timeIntervalSince(scrubTime) < 0.6 ? $0 : nil }
            ?? scalePosition(forDB: Double(c.volume - AmpBLE.maxHardwareVolume))
        let top = scalePosition(forDB: Double(c.maxVolume - AmpBLE.maxHardwareVolume))
        pos = min(top, max(0, pos + degrees / volumeDegreesPerLED))
        scrubPos = pos
        scrubTime = now
        let db = scaleDB(forPosition: pos).rounded()
        c.setVolume(AmpBLE.maxHardwareVolume + Int(db))
    }

    /// As on the device: the LED of the new input blinks for 1.5 seconds, four times per second (on the device 3 s at 2 blinks per second, here faster and shorter).
    /// Another change restarts the blinking.
    private func startInputBlink() {
        inputBlinkTask?.cancel()
        inputBlinkTask = Task { @MainActor in
            inputBlinkOff = false
            for _ in 0..<6 {
                try? await Task.sleep(nanoseconds: 125_000_000)
                if Task.isCancelled { return }
                inputBlinkOff = true
                try? await Task.sleep(nanoseconds: 125_000_000)
                if Task.isCancelled { return }
                inputBlinkOff = false
            }
        }
    }

    private func stopInputBlink() {
        inputBlinkTask?.cancel()
        inputBlinkTask = nil
        inputBlinkOff = false
    }

    /// When turning up: from this dB value on the respective LED lights up (21 LEDs, the first is index 0).
    /// Measured on the One HD, the scale follows no simple formula. The first LED applies from "-infinity".
    private static let ledUpDB: [Int] = [
        -1000, -88, -69, -54, -43, -36, -33, -30, -27, -23, -21,
        -18, -15, -12, -9, -6, -4, -3, -2, -1, 0,
    ]

    /// When turning down: at this dB value the display jumps to the respective LED. It stays there
    /// until the next value (that of the LED below) is reached. So the scale has a hysteresis.
    private static let ledDownDB: [Int] = [
        -90, -70, -55, -44, -37, -34, -31, -28, -25, -22, -19,
        -16, -13, -10, -7, -5, -4, -3, -2, -1, 0,
    ]

    /// Index of the lit LED. `previous` is the previous index and resolves the cases in which
    /// turning up and down show different LEDs (hysteresis).
    private func ledIndex(for volume: Int, previous: Int) -> Int {
        let db = volume - AmpBLE.maxHardwareVolume
        let up = Self.ledUpDB.lastIndex(where: { $0 <= db }) ?? 0
        let down = Self.ledDownDB.firstIndex(where: { db <= $0 }) ?? (volumeLEDs - 1)
        let lo = min(up, down), hi = max(up, down)
        return min(volumeLEDs - 1, min(max(previous, lo), hi))
    }

    private func caption(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .textCase(.uppercase)
            .accessibilityHidden(true)
            .font(.caption)
            .tracking(4)
            .foregroundStyle(Color.white.opacity(0.45))
    }

    /// Choose the knob size so that both knobs including their labels fit on the screen
    private func knobSize(in size: CGSize, wide: Bool) -> CGFloat {
        let label: CGFloat = 40
        let value: CGFloat = wide
            ? min((size.width - 16 - 24) / 2, size.height - label - 16)
            : min(size.width - 8, (size.height - 8 - 2 * label - 16) / 2)
        return max(140, min(value, 560))
    }
}
