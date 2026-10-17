import SwiftUI
#if os(macOS)
import AppKit
#endif

extension View {
    /// Mouse wheel / trackpad scrolling over this view (macOS only, no-op elsewhere).
    /// `onScroll` gets the movement in "notches": one wheel notch is about 1, a trackpad
    /// swipe of roughly 60 points is 1 as well. Positive means the wheel moved up.
    func scrollWheel(_ onScroll: @escaping (Double) -> Void) -> some View {
        #if os(macOS)
        background(ScrollWheelCatcher(onScroll: onScroll))
        #else
        self
        #endif
    }
}

#if os(macOS)
private struct ScrollWheelCatcher: NSViewRepresentable {
    var onScroll: (Double) -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.onScroll = onScroll
    }

    final class CatcherView: NSView {
        var onScroll: ((Double) -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let m = monitor { NSEvent.removeMonitor(m) }
            monitor = nil
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, event.window === self.window else { return event }
                let point = self.convert(event.locationInWindow, from: nil)
                guard self.bounds.contains(point) else { return event }
                // Physical direction, independent of the "natural scrolling" setting
                var dy = Double(event.scrollingDeltaY)
                if event.isDirectionInvertedFromDevice { dy = -dy }
                self.onScroll?(event.hasPreciseScrollingDeltas ? dy / 60 : dy)
                return nil
            }
        }

        deinit {
            if let m = monitor { NSEvent.removeMonitor(m) }
        }
    }
}
#endif
