import SwiftUI

/// Everything that is not needed all the time: device selection, balance, display, volume limit,
/// AV Direct and device info.
struct SettingsView: View {
    @EnvironmentObject var c: AmpController
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("knobSensitivity2") private var sensitivity = 0.5

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                deviceSection
                balanceSection
                displaySection
                maxVolumeSection
                sensitivitySection
                AVDirectSection()
                infoSection
            }
            .padding()
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Settings")
    }

    // MARK: Device

    private var deviceSection: some View {
        GroupBox("Device") {
            VStack(alignment: .leading, spacing: 8) {
                Text(c.deviceName).font(.headline)
                Text(c.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if c.isDemo {
                    Text("Demo mode: this is a simulated amplifier.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Exit demo") {
                        dismiss()
                        app.exitDemo()
                    }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("exitDemoButton")
                } else {
                    Button("Search for another device") {
                        // Close the settings first, otherwise they stay on top of the search
                        dismiss()
                        c.openScan()
                    }
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Balance

    private var balanceSection: some View {
        GroupBox("Balance") {
            VStack(spacing: 8) {
                Text(c.balanceText)
                    .font(.headline.monospacedDigit())
                Slider(
                    value: Binding(get: { Double(c.balance) }, set: { c.setBalance(Int($0.rounded())) }),
                    in: 0...20,
                    step: 1
                )
                HStack {
                    Text("Left").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Center") { c.setBalance(10) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Spacer()
                    Text("Right").font(.caption).foregroundStyle(.secondary)
                }
                if c.headphones {
                    Text("Balance is disabled while headphones are connected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(c.headphones)
        }
    }

    // MARK: Display

    private var displaySection: some View {
        GroupBox("Display brightness") {
            HStack(spacing: 16) {
                Button { c.brightness(up: false) } label: {
                    Label("Dimmer", systemImage: "sun.min")
                }
                .buttonStyle(HoldRepeatButtonStyle(interval: 0.25))
                Button { c.brightness(up: true) } label: {
                    Label("Brighter", systemImage: "sun.max")
                }
                .buttonStyle(HoldRepeatButtonStyle(interval: 0.25))
            }
        }
    }

    // MARK: Volume limit

    private var maxVolumeSection: some View {
        GroupBox("Volume limit") {
            VStack(alignment: .leading, spacing: 6) {
                Stepper(
                    "Maximum: \(AmpBLE.dbText(c.maxVolume))",
                    value: $c.maxVolume,
                    in: 10...AmpBLE.maxHardwareVolume,
                    step: 5
                )
                Text("Knobs and buttons do not go above this value. The limit is saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Sensitivity

    private var sensitivitySection: some View {
        GroupBox("Sensitivity") {
            VStack(spacing: 8) {
                Slider(value: $sensitivity, in: 0...1)
                HStack {
                    Text("Sluggish").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Default") { sensitivity = 0.5 }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Spacer()
                    Text("Sensitive").font(.caption).foregroundStyle(.secondary)
                }
                Text("Applies to turning and swiping for volume and input.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Device info

    private var infoSection: some View {
        GroupBox("Device info") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Serial number: \(c.serial.isEmpty ? "–" : c.serial)")
                Text("Firmware: \(c.firmware.isEmpty ? "–" : c.firmware)")
                Text("DAC model: \(c.hasDAC ? String(localized: "yes") : String(localized: "no"))")
                Text("Headphones: \(c.headphones ? String(localized: "connected") : String(localized: "no"))")
                Text("AV Direct: \(c.avDirect ? String(localized: "on") : String(localized: "off"))")
                Button("Refresh values") { c.refresh() }
                    .buttonStyle(.bordered)
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// AV Direct in one group, the actual logic including the warnings lives in `AVDirectView`.
private struct AVDirectSection: View {
    var body: some View {
        GroupBox {
            AVDirectView()
        }
    }
}
