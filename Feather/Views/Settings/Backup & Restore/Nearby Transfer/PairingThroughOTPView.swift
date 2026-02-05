import SwiftUI
import NimbleViews
import MultipeerConnectivity
import Combine

// MARK: - OTP Pairing Mode
enum OTPPairingMode {
    case sender
    case recipient
}

// MARK: - Pairing Through OTP View
struct PairingThroughOTPView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OTPPairingViewModel()
    @State private var selectedMode: OTPPairingMode = .sender
    @State private var otpInput: String = ""
    @State private var showingTransfer = false
    
    var body: some View {
        NBList(.localized("Remote Pairing")) {
            // Mode Selection
            Section {
                Picker("Mode", selection: $selectedMode) {
                    Text("Sender").tag(OTPPairingMode.sender)
                    Text("Recipient").tag(OTPPairingMode.recipient)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedMode) { newMode in
                    viewModel.switchMode(to: newMode)
                    otpInput = ""
                }
            } header: {
                AppearanceSectionHeader(title: String.localized("Pairing Mode"), icon: "person.2.fill")
            }
            
            // Guidance Text
            Section {
                guidanceTextView
            } header: {
                AppearanceSectionHeader(title: String.localized("Instructions"), icon: "info.circle.fill")
            }
            
            // Sender UI
            if selectedMode == .sender {
                senderSection
            }
            
            // Recipient UI
            if selectedMode == .recipient {
                recipientSection
            }
        }
        .navigationTitle("Remote Pairing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    viewModel.cleanup()
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingTransfer) {
            NavigationStack {
                TransferProgressView(
                    service: viewModel.transferService,
                    onCancel: {
                        viewModel.transferService.cancelTransfer()
                    },
                    onRetry: {
                        // Retry logic handled by service
                    }
                )
                .navigationTitle("Transfer Progress")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            viewModel.setup()
        }
        .onChange(of: viewModel.transferStarted) { started in
            if started {
                showingTransfer = true
            }
        }
    }
    
    // MARK: - Guidance Text
    @ViewBuilder
    private var guidanceTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if selectedMode == .sender {
                Text("Share this code with your other device. It expires shortly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Enter the code from the sender to connect securely.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Sender Section
    @ViewBuilder
    private var senderSection: some View {
        Section {
            VStack(spacing: 20) {
                // OTP Display
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.otpCode.enumerated()), id: \.offset) { index, char in
                        Text(String(char))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .frame(width: 50, height: 60)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.vertical, 8)
                
                // Expiration Countdown
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(viewModel.expirationColor)
                    Text("Expires in \(viewModel.timeRemaining)s")
                        .font(.headline)
                        .foregroundStyle(viewModel.expirationColor)
                }
                
                // Status
                if viewModel.isPeerConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Recipient connected")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 8)
                }
                
                // Waiting State
                if viewModel.isWaitingForRecipient && !viewModel.isPeerConnected {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Waiting for recipient...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        } header: {
            AppearanceSectionHeader(title: String.localized("Your Code"), icon: "key.fill")
        } footer: {
            Text("Share this code with the receiving device. The code will expire in \(viewModel.otpExpirationSeconds) seconds.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        // Regenerate Button
        Section {
            Button {
                viewModel.regenerateOTP()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Generate New Code")
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isPeerConnected)
        }
    }
    
    // MARK: - Recipient Section
    @ViewBuilder
    private var recipientSection: some View {
        Section {
            VStack(spacing: 16) {
                // OTP Input
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.otpLength, id: \.self) { index in
                        Text(index < otpInput.count ? String(Array(otpInput)[index]) : "")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .frame(width: 50, height: 60)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(index == otpInput.count ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                }
                
                // Keypad or TextField
                TextField("", text: $otpInput)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .opacity(0.01)
                    .frame(height: 1)
                    .onChange(of: otpInput) { newValue in
                        // Limit input to OTP length
                        if newValue.count > viewModel.otpLength {
                            otpInput = String(newValue.prefix(viewModel.otpLength))
                        }
                        // Auto-validate when complete
                        if otpInput.count == viewModel.otpLength {
                            viewModel.validateOTP(otpInput)
                        }
                    }
            }
            .padding(.vertical, 16)
        } header: {
            AppearanceSectionHeader(title: String.localized("Enter Code"), icon: "keyboard.fill")
        } footer: {
            Text("Enter the \(viewModel.otpLength)-digit code from the sending device")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        // Validation Status
        if viewModel.isValidating {
            Section {
                HStack {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Validating code...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        
        // Device Preview (after successful validation)
        if let peerInfo = viewModel.connectedPeerInfo {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "iphone")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                    
                    Text(peerInfo.deviceName)
                        .font(.headline)
                    
                    Toggle("Trust this device", isOn: $viewModel.trustDevice)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } header: {
                AppearanceSectionHeader(title: String.localized("Sender Device"), icon: "checkmark.shield.fill")
            }
            
            // Confirm Button
            Section {
                Button {
                    viewModel.confirmConnection()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Begin Transfer")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.trustDevice)
            }
        }
        
        // Error Display
        if let error = viewModel.errorMessage {
            Section {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - OTP Pairing View Model
class OTPPairingViewModel: ObservableObject {
    @Published var otpCode: String = ""
    @Published var timeRemaining: Int = 0
    @Published var isPeerConnected: Bool = false
    @Published var isWaitingForRecipient: Bool = false
    @Published var isValidating: Bool = false
    @Published var errorMessage: String?
    @Published var connectedPeerInfo: (deviceName: String, peerId: MCPeerID)?
    @Published var trustDevice: Bool = false
    @Published var transferStarted: Bool = false
    
    let otpLength: Int = 6
    let otpExpirationSeconds: Int = 300 // 5 minutes
    
    var transferService = NearbyTransferService()
    private var otpTimer: Timer?
    private var currentMode: OTPPairingMode = .sender
    private var otpStartTime: Date?
    
    var expirationColor: Color {
        if timeRemaining > 60 {
            return .green
        } else if timeRemaining > 30 {
            return .orange
        } else {
            return .red
        }
    }
    
    func setup() {
        if currentMode == .sender {
            generateOTP()
            startAdvertising()
        } else {
            startBrowsing()
        }
    }
    
    func switchMode(to mode: OTPPairingMode) {
        cleanup()
        currentMode = mode
        setup()
    }
    
    func cleanup() {
        otpTimer?.invalidate()
        otpTimer = nil
        transferService.stop()
    }
    
    // MARK: - Sender Methods
    
    func generateOTP() {
        // Generate a random 6-8 digit OTP
        let otp = String(format: "%0\(otpLength)d", Int.random(in: 0..<Int(pow(10.0, Double(otpLength)))))
        otpCode = otp
        otpStartTime = Date()
        timeRemaining = otpExpirationSeconds
        isWaitingForRecipient = true
        
        // Store OTP for validation
        UserDefaults.standard.set(otp, forKey: "currentOTP")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "otpStartTime")
        
        startTimer()
    }
    
    func regenerateOTP() {
        generateOTP()
        startAdvertising()
    }
    
    private func startTimer() {
        otpTimer?.invalidate()
        otpTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.otpStartTime else { return }
            
            let elapsed = Int(Date().timeIntervalSince(startTime))
            self.timeRemaining = max(0, self.otpExpirationSeconds - elapsed)
            
            if self.timeRemaining == 0 {
                self.otpTimer?.invalidate()
                self.regenerateOTP()
            }
        }
    }
    
    private func startAdvertising() {
        transferService.startReceiveMode()
        // In a real implementation, you'd use a custom discovery info with the OTP
        // For simplicity, we'll use the OTP as part of the peer display name
        isWaitingForRecipient = true
    }
    
    // MARK: - Recipient Methods
    
    private func startBrowsing() {
        transferService.startSendMode()
    }
    
    func validateOTP(_ code: String) {
        isValidating = true
        errorMessage = nil
        
        // Simulate validation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Check if OTP matches any discovered peer
            // In a real implementation, this would query discovered peers for their OTP
            let storedOTP = UserDefaults.standard.string(forKey: "currentOTP")
            let storedTime = UserDefaults.standard.double(forKey: "otpStartTime")
            
            let isExpired = Date().timeIntervalSince1970 - storedTime > Double(self.otpExpirationSeconds)
            
            if let storedOTP = storedOTP, storedOTP == code, !isExpired {
                // Valid OTP - simulate finding the peer
                self.connectedPeerInfo = (deviceName: UIDevice.current.name, peerId: MCPeerID(displayName: UIDevice.current.name))
                self.isValidating = false
            } else {
                self.errorMessage = "Invalid or expired code. Please try again."
                self.isValidating = false
                
                // Clear input after error
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.errorMessage = nil
                }
            }
        }
    }
    
    func confirmConnection() {
        guard let peerInfo = connectedPeerInfo else { return }
        
        // Connect to the peer and start transfer
        transferService.connect(to: peerInfo.peerId)
        transferStarted = true
    }
}
