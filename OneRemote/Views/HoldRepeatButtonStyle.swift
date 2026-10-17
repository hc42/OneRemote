import SwiftUI

/// Button style that repeats the step while held (volume, display brightness).
/// A tap triggers exactly one step. If pressed longer than `initialDelay`, another step follows every
/// `interval` seconds until the finger is lifted.
///
/// Safety: stopping hangs on a `@GestureState`. It is also reset
/// when the gesture is cancelled (for example because the ScrollView takes over), so the
/// repeat cannot keep running forever. It also stops when the button
/// is disabled or the view disappears.
struct HoldRepeatButtonStyle: PrimitiveButtonStyle {
    var prominent = false
    var tint: Color = .accentColor
    var foreground: Color = .white
    var repeats = true
    var initialDelay = 0.4
    var interval = 0.1

    func makeBody(configuration: Configuration) -> some View {
        HoldRepeatBody(configuration: configuration, style: self)
    }
}

private struct HoldRepeatBody: View {
    let configuration: PrimitiveButtonStyle.Configuration
    let style: HoldRepeatButtonStyle

    @Environment(\.isEnabled) private var isEnabled
    @GestureState private var isPressing = false
    @State private var active = false
    @State private var delayTimer: Timer?
    @State private var repeatTimer: Timer?

    var body: some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, style.prominent ? 14 : 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(style.prominent ? style.tint : style.tint.opacity(0.15))
            )
            .foregroundStyle(style.prominent ? style.foreground : style.tint)
            .opacity(!isEnabled ? 0.4 : (isPressing ? 0.6 : 1))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressing) { _, state, _ in state = true }
                    .onChanged { _ in
                        if !active {
                            active = true
                            pressStarted()
                        }
                    }
                    .onEnded { _ in
                        active = false
                        stop()
                    }
            )
            // Also on a cancelled gesture: reset the state and end the repeat
            .onChange(of: isPressing) { pressing in
                if !pressing {
                    stop()
                    active = false
                }
            }
            .onChange(of: isEnabled) { enabled in
                if !enabled { stop() }
            }
            .onDisappear { stop() }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { configuration.trigger() }
    }

    private func pressStarted() {
        guard isEnabled else { return }
        configuration.trigger() // one step immediately
        guard style.repeats else { return }

        let delay = Timer(timeInterval: style.initialDelay, repeats: false) { _ in
            let repeating = Timer(timeInterval: style.interval, repeats: true) { _ in
                configuration.trigger()
            }
            // .common so that the timer also runs while a ScrollView is tracking touches
            RunLoop.main.add(repeating, forMode: .common)
            repeatTimer = repeating
        }
        RunLoop.main.add(delay, forMode: .common)
        delayTimer = delay
    }

    private func stop() {
        delayTimer?.invalidate()
        delayTimer = nil
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}
