import SwiftUI

/// Holds the controller the screens use: the real amplifier, or the simulated one in demo mode.
/// The real controller keeps running in the background while the demo is shown.
final class AppModel: ObservableObject {
    @Published private(set) var controller: AmpController
    private let real: AmpController

    init(real: AmpController) {
        self.real = real
        self.controller = real
    }

    var isDemo: Bool { controller.isDemo }

    func startDemo() {
        guard !isDemo else { return }
        controller = SimulatedAmplifier.makeDemoController()
    }

    func exitDemo() {
        controller = real
    }
}
