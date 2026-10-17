import SwiftUI

@main
struct OneRemoteApp: App {
    @StateObject private var controller = AmpController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                #if os(macOS)
                .frame(minWidth: 420, minHeight: 640)
                #endif
        }
    }
}
