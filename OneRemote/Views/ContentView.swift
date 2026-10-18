import SwiftUI

struct ContentView: View {
    @EnvironmentObject var c: AmpController
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if c.showScan {
                    ScanView()
                } else if c.connected {
                    ControlView()
                } else {
                    ConnectionView()
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        // The device is black, so is the app
        .preferredColorScheme(.dark)
        // Splash image inside the app (same as the launch screen), so that it always appears
        // regardless of the iOS launch screen cache
        .overlay {
            if showSplash {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image("LaunchLogo")
                }
                .transition(.opacity)
            }
        }
        // When opening, refocusing or unlocking, fetch the values from the amplifier again,
        // because the device may have been turned in the meantime
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            if c.connected {
                c.refresh()
            } else if !c.connecting, !c.showScan {
                // When returning to the app, connect again in case the amplifier is back by now
                c.retry()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeOut(duration: 0.5)) { showSplash = false }
        }
    }

    private var title: String {
        if c.showScan { return String(localized: "Choose device") }
        if c.isDemo { return String(localized: "Demo") }
        return c.connected ? c.deviceName : "One Remote"
    }
}
