import SwiftUI

struct ScanView: View {
    @EnvironmentObject var c: AmpController

    var body: some View {
        List {
            Section {
                Text(c.scanning ? String(localized: "Searching for devices") : c.status)
                    .foregroundStyle(.secondary)
                // The search runs by itself and does not need to be stopped. Only when it is not
                // running (for example after Bluetooth was switched off) is there a button to restart it.
                if !c.scanning {
                    Button("Search for devices") { c.startScan() }
                }
                if let saved = c.savedDevice {
                    Text("Default device: \(saved.name)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Devices found") {
                if c.found.isEmpty {
                    Text("Nothing found yet").foregroundStyle(.secondary)
                }
                ForEach(c.found) { d in
                    Button(d.name) { c.connect(d.id) }
                }
            }
        }
        .toolbar {
            if c.savedDevice != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { c.closeScan() }
                }
            }
        }
    }
}
