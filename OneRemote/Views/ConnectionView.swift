import SwiftUI

/// Shows the connection setup to the saved device and, on errors, the
/// "retry" and "search for another device" buttons.
struct ConnectionView: View {
    @EnvironmentObject var c: AmpController

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // The device in a soft cone of light that fades to transparent towards the edge
            // (same image as on the launch screen, just larger)
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 340, maxHeight: 340)

            if c.connecting {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
            }

            Text(c.deviceName)
                .font(.title3.bold())

            Text(c.status)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                if !c.connecting {
                    Button("Try again") { c.retry() }
                        .buttonStyle(.borderedProminent)
                }
                Button("Search for another device") { c.openScan() }
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .padding()
        // Pure black like the launch screen and the control page, so the light cone fades out seamlessly
        .background(Color.black.ignoresSafeArea())
    }
}
