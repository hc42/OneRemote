import SwiftUI

@main
struct OneRemoteApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    #endif
    @StateObject private var model = AppModel(real: OneRemoteApp.makeController())

    private static func makeController() -> AmpController {
        #if DEBUG
        // UI tests and screenshots: simulated amplifier instead of Bluetooth
        if CommandLine.arguments.contains("-simulated-amplifier") {
            return SimulatedAmplifier.makeController(arguments: CommandLine.arguments)
        }
        #endif
        return AmpController()
    }

    var body: some Scene {
        #if os(macOS)
        // A single window: the amplifier accepts one connection, a second window adds nothing (ADR 0021)
        Window("One Remote", id: "main") {
            content
                .frame(minWidth: 420, minHeight: 640)
        }
        #else
        WindowGroup {
            content
        }
        #endif
    }

    private var content: some View {
        ContentView()
            .environmentObject(model.controller)
            .environmentObject(model)
    }
}

#if os(macOS)
/// Quits the app when its window is closed (ADR 0021)
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
#endif
