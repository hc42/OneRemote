import SwiftUI

@main
struct OneRemoteApp: App {
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
        WindowGroup {
            ContentView()
                .environmentObject(model.controller)
                .environmentObject(model)
                #if os(macOS)
                .frame(minWidth: 420, minHeight: 640)
                #endif
        }
    }
}
