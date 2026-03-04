import SwiftUI
import MultipeerConnectivity

struct TransferSourcesMP: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var transferService = SourcesTransferService()
    var sourceURLs: [String] = []

    @State private var isReceiveMode = false
    @State private var showSuccess = false
    @State private var receivedCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                Picker("Mode", selection: $isReceiveMode) {
                    Text("Send").tag(false)
                    Text("Receive").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: isReceiveMode) { newValue in
                    transferService.stop()
                    if newValue {
                        transferService.startReceiveMode()
                    } else {
                        transferService.startSendMode()
                    }
                    HapticsManager.shared.softImpact()
                }

                if isReceiveMode {
                    receiveContent
                } else {
                    sendContent
                }

                Spacer()
            }
            .padding(.vertical, 20)
            .navigationTitle("Wireless Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        transferService.stop()
                        dismiss()
                    }
                }
            }
            .onAppear {
                transferService.startSendMode()
                transferService.onSourcesReceived = { urls in
                    var added = 0
                    for url in urls {
                        if !Storage.shared.sourceExists(url) {
                            Storage.shared.addSource(url: url)
                            added += 1
                        }
                    }
                    receivedCount = added
                    withAnimation {
                        showSuccess = true
                    }
                    HapticsManager.shared.success()
                }
            }
            .onDisappear {
                transferService.stop()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isReceiveMode ? Color.cyan.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: isReceiveMode ? "wave.3.left.circle.fill" : "dot.radiowaves.left.and.right")
                    .font(.system(size: 40))
                    .foregroundStyle(isReceiveMode ? Color.cyan : Color.blue)
            }

            Text(isReceiveMode ? "Ready to Receive" : "Sharing \(sourceURLs.count) Sources")
                .font(.headline)

            Text(isReceiveMode ? "Stay on this screen to be discoverable" : "Select a nearby device to send sources")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var sendContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nearby Devices")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if transferService.discoveredPeers.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Looking for devices...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                List(transferService.discoveredPeers, id: \.self) { peer in
                    Button {
                        transferService.sendSources(sourceURLs, to: peer)
                    } label: {
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundStyle(Color.accentColor)
                            Text(peer.displayName)
                            Spacer()
                            if case .connecting = transferService.state {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }

            if case .completed = transferService.state {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Sent successfully!")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }

    private var receiveContent: some View {
        VStack(spacing: 24) {
            if showSuccess {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("\(receivedCount) Sources Added")
                        .font(.headline)

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(16)
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Discoverable as \(UIDevice.current.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 40)
            }
        }
    }
}
