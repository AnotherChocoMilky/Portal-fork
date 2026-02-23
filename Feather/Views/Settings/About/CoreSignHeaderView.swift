import SwiftUI
import CoreImage

struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitleIndex: Int = 0
    @State private var showCredits = false
    @State private var showSecretDimension = false
    @State private var iconRotationAngle: Double = 0
    @State private var dominantColors: [Color] = []
    var hideAboutButton: Bool = false

    // MARK: - Current Subtitle
    private var currentSubtitle: String {
        HeaderSubtitle.allSubtitles[safe: currentSubtitleIndex] ?? HeaderSubtitle.defaultSubtitle
    }

    // MARK: - Body
    var body: some View {
        headerCard
            .onAppear {
                setupLifecycleObservers()
                rotateSubtitle()
                extractColors()
            }
            .sheet(isPresented: $showCredits) {
                CreditsView()
            }
            .fullScreenCover(isPresented: $showSecretDimension) {
                SecretDimensionView()
            }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 20) {
            // App Icon centered at the top
            appIcon
                .rotationEffect(.degrees(iconRotationAngle))
                .onTapGesture(count: 3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                        iconRotationAngle += 360
                    }
                    HapticsManager.shared.success()
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 2.0)
                        .onEnded { _ in
                            ToastManager.shared.show("🤫 Portal is the best, don't tell anyone!", type: .info)
                            HapticsManager.shared.success()
                        }
                )
            
            VStack(spacing: 12) {
                // App Name centered below
                Text("Portal")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .simultaneousGesture(
                        TapGesture(count: 3)
                            .onEnded {
                                showSecretDimension = true
                                HapticsManager.shared.success()
                            }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded {
                                let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan, .mint]
                                if let randomColor = colors.randomElement() {
                                    UIApplication.shared.connectedScenes
                                        .compactMap { $0 as? UIWindowScene }
                                        .flatMap { $0.windows }
                                        .forEach { $0.tintColor = UIColor(randomColor) }
                                    ToastManager.shared.show("🎨 Color Splash!", type: .info)
                                    HapticsManager.shared.success()
                                }
                            }
                    )

                // Version Row
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .clipShape(Capsule())

                // Release Label (Modern capsule badge)
                Text("RELEASE")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.0)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            }

            // Subtexts centered below
            Text(currentSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .multilineTextAlignment(.center)
                .transition(.opacity)
                .id(currentSubtitleIndex)
                .padding(.top, 4)
            
            // Action Buttons
            if !hideAboutButton {
                creditsButton
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            ZStack {
                if !dominantColors.isEmpty {
                    LinearGradient(
                        colors: [
                            dominantColors[0].opacity(0.1),
                            (dominantColors.count > 1 ? dominantColors[1] : dominantColors[0]).opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.primary.opacity(0.03)
                }

                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.5))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .padding(.horizontal)
    }
    
    // MARK: - App Icon
    @ViewBuilder
    private var appIcon: some View {
        if let iconName = Bundle.main.iconFileName,
           let icon = UIImage(named: iconName) {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        } else {
            Image(systemName: "questionmark.square.dashed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Credits Button
    private var creditsButton: some View {
        Button {
            showCredits = true
            HapticsManager.shared.softImpact()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 9))
                    .symbolRenderingMode(.hierarchical)
                Text(.localized("Credits"))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.accentColor))
            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Lifecycle Observers
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            rotateSubtitle()
        }
    }

    // MARK: - Color Extraction
    private func extractColors() {
        guard let iconName = Bundle.main.iconFileName,
              let uiImage = UIImage(named: iconName),
              let cgImage = uiImage.cgImage else {
            return
        }

        Task.detached {
            let ciImage = CIImage(cgImage: cgImage)
            let extent = ciImage.extent

            let filter = CIFilter(name: "CIAreaAverage")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

            var extracted: [Color] = []

            if let output = filter?.outputImage {
                var bitmap = [UInt8](repeating: 0, count: 4)
                let context = CIContext()
                context.render(output, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

                let color = Color(red: Double(bitmap[0]) / 255, green: Double(bitmap[1]) / 255, blue: Double(bitmap[2]) / 255)
                extracted.append(color)
            }

            let quarterExtent = CGRect(x: extent.width * 0.25, y: extent.height * 0.25, width: extent.width * 0.5, height: extent.height * 0.5)
            let filter2 = CIFilter(name: "CIAreaAverage")
            filter2?.setValue(ciImage, forKey: kCIInputImageKey)
            filter2?.setValue(CIVector(cgRect: quarterExtent), forKey: kCIInputExtentKey)

            if let output2 = filter2?.outputImage {
                var bitmap = [UInt8](repeating: 0, count: 4)
                let context = CIContext()
                context.render(output2, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

                let color2 = Color(red: Double(bitmap[0]) / 255, green: Double(bitmap[1]) / 255, blue: Double(bitmap[2]) / 255)

                if let first = extracted.first {
                    let firstComponents = UIColor(first).cgColor.components ?? [0, 0, 0]
                    let diff = abs(Double(bitmap[0])/255 - Double(firstComponents[0])) +
                               abs(Double(bitmap[1])/255 - Double(firstComponents[1])) +
                               abs(Double(bitmap[2])/255 - Double(firstComponents[2]))
                    if diff > 0.3 {
                        extracted.append(color2)
                    }
                }
            }

            await MainActor.run {
                self.dominantColors = extracted.isEmpty ? [.accentColor] : extracted
            }
        }
    }

    // MARK: - Subtitle Rotation
    private func rotateSubtitle() {
        let subtitles = HeaderSubtitle.allSubtitles
        guard !subtitles.isEmpty else { return }

        var newIndex = Int.random(in: 0..<subtitles.count)
        
        if subtitles.count > 1 {
            var attempts = 0
            while newIndex == currentSubtitleIndex && attempts < 10 {
                newIndex = Int.random(in: 0..<subtitles.count)
                attempts += 1
            }
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentSubtitleIndex = newIndex
        }
    }

    /// Public method to trigger subtitle rotation (call this when tab changes)
    func onTabChange() {
        rotateSubtitle()
    }
}

// MARK: - easy to add header subtitles because i cbf to find the localizedstrings lmao
enum HeaderSubtitle {
    /// Default subtitle shown if array is empty
    static let defaultSubtitle = "the modern signer"

    static var allSubtitles: [String] = [
        "the modern signer",
        "no competition",
        "Are you using the latest Portal version?",
        "Built with Swift",
        "what feature would you like to see here?",
        "listen to Junior H",
        "latinas on top",
        "OTRA RUPTURA MAS AL CORAZON",
        "Kravashit are a scam",
        "Just Works™",
        "Portal in full Spanish?? maybe...",
        "should i put my instagram here??",
        "Portal made by dylan lol",
        "5-7, 7-3, elite ball knowledge needed to understand",
        "why do I encounter stupid people ffs",
        "S on S tier, get it? probably not",
        "easter eggs hidden",
        "where tf is QuickSign at??",
        "Porque la vida es asi -Peso Pluma",
        "made with some crashouts",
        "When is DRUNK releasing omg",
        "girls want girls -drake",
        "this Portal is WAY better",
        "vibe coded project lol",
        "playing hard to get is NOT cool S...",
        "greatest signer",
        "Use Portal gng",
        "Random project",
        "if you want something custom here, ping dylan in the WSF server",
        "my grades are so fucked",
        "need me some Chrome Hearts",
        "coding ts on a mfucking chromebook",
        "WSF On Top",
        "feature rich signer",
        "Kravashit",
        "Just When You Thought",
        "love ragebaiting",
        "drizzy > kendrick",
        "love my future gf S ❤️",
        "Kravasigner Who?",
        "other forgotten signers",
    ]
    
    /// Add a new subtitle at runtime
    static func add(_ subtitle: String) {
        allSubtitles.append(subtitle)
    }
    
    /// Remove a subtitle at runtime
    static func remove(_ subtitle: String) {
        allSubtitles.removeAll { $0 == subtitle }
    }
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    CoreSignHeaderView()
        .padding()
}
