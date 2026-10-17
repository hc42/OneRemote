import SwiftUI

/// AV Direct section with a two-step confirmation for enabling:
/// Step 1: warning dialog that must be confirmed explicitly.
/// Step 2: final dialog "Enable now".
/// Disabling needs a simple confirmation.
struct AVDirectView: View {
    @EnvironmentObject var c: AmpController

    @State private var showWarning = false
    @State private var warningAccepted = false
    @State private var showFinalConfirm = false
    @State private var showDisableConfirm = false
    @State private var busy = false

    private var canChange: Bool { c.avDirectKnown && c.avDirectSupported && !busy }

    private var hint: String? {
        if !c.avDirectKnown { return String(localized: "Waiting for the state of the amplifier …") }
        if c.firmware.isEmpty { return String(localized: "Firmware unknown.") }
        if !c.avDirectSupported { return String(localized: "Requires firmware 2.0 or newer (currently: \(c.firmware)).") }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AV Direct").font(.headline)
                Spacer()
                Text(c.avDirectKnown ? (c.avDirect ? String(localized: "ON") : String(localized: "OFF")) : "–")
                    .font(.subheadline.bold())
                    .foregroundStyle(c.avDirect ? Color.orange : Color.secondary)
            }
            Text("The ONE then works as a power amplifier, for example for the front channels of a home theater. On the AV input the volume is then fixed at a high level.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if c.avDirect {
                Button("Disable AV Direct …") { showDisableConfirm = true }
                    .buttonStyle(.bordered)
                    .disabled(!canChange)
            } else {
                Button("Enable AV Direct …") { showWarning = true }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(!canChange)
            }

            if let hint = hint {
                Text(hint).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Step 1: warning
        .sheet(isPresented: $showWarning, onDismiss: {
            if warningAccepted {
                warningAccepted = false
                showFinalConfirm = true
            }
        }) {
            AVDirectWarningSheet { warningAccepted = true }
        }
        // Step 2: final confirmation
        .alert("Really enable AV Direct?", isPresented: $showFinalConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Enable now", role: .destructive) { toggle(whileAVDirectIs: false) }
        } message: {
            Text("Your amplifier will be switched to AV Direct mode. Make sure your system is set up correctly, otherwise the speakers can be damaged.")
        }
        // Disable
        .alert("Disable AV Direct?", isPresented: $showDisableConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Disable") { toggle(whileAVDirectIs: true) }
        }
    }

    /// The command is a toggle. It is only sent if AV Direct still has the state
    /// the confirmation was based on (`whileAVDirectIs`).
    private func toggle(whileAVDirectIs expected: Bool) {
        guard c.avDirect == expected else { return }
        busy = true
        c.toggleAVDirect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { busy = false }
    }
}

struct AVDirectWarningSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var understood = false
    let onAccept: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Speakers can be damaged", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)

                    Text("In AV Direct mode the amplifier works as a power amplifier. This lets you use it as a high-quality front-channel power amplifier in a home theater system.")

                    Text("WARNING: If AV Direct is active and the AV input is selected, the volume of the ONE is fixed at a high level. The volume controls in this app are then locked.")
                        .fontWeight(.semibold)

                    Text("This can damage your speakers if the system is not set up correctly. Set the levels of the source (for example AV receiver or processor) appropriately beforehand and read the amplifier's manual.")

                    Toggle("I have read and understood the warning.", isOn: $understood)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("AV Direct")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        onAccept()
                        dismiss()
                    }
                    .disabled(!understood)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 480)
        #endif
    }
}
