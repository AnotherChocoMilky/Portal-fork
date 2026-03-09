import SwiftUI

// MARK: - View Model

@MainActor
final class EnterpriseViewModel: ObservableObject {
	@Published var certificates: [EnterpriseCertificate] = []
	@Published var isLoading = false
	@Published var errorMessage: String? = nil
	@Published var importedIDs: Set<UUID> = []

	func load() {
		guard !isLoading else { return }
		isLoading = true
		errorMessage = nil

		Task {
			do {
				let certs = try await CertificateEnterpriseFetcher.shared.fetchEnterpriseCertificates()
				certificates = certs
				isLoading = false
			} catch {
				errorMessage = error.localizedDescription
				isLoading = false
			}
		}
	}

	func importCertificate(_ certificate: EnterpriseCertificate) {
		FR.handleCertificateFiles(
			p12URL: certificate.p12URL,
			provisionURL: certificate.provisionURL,
			p12Password: "",
			certificateName: certificate.name,
			isDefault: false
		) { [weak self] error in
			Task { @MainActor in
				guard let self else { return }
				if let error = error {
					self.errorMessage = error.localizedDescription
				} else {
					self.importedIDs.insert(certificate.id)
					HapticsManager.shared.success()
				}
			}
		}
	}
}

// MARK: - View

struct CertificateEnterpriseView: View {
	@Environment(\.dismiss) private var dismiss
	@StateObject private var viewModel = EnterpriseViewModel()

	var body: some View {
		NavigationStack {
			ZStack {
				Color(UIColor.systemGroupedBackground)
					.ignoresSafeArea()

				Group {
					if viewModel.isLoading {
						loadingView
					} else if let error = viewModel.errorMessage {
						errorView(message: error)
					} else if viewModel.certificates.isEmpty {
						emptyView
					} else {
						certificateList
					}
				}
			}
			.navigationTitle("Enterprise Certificates")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.title2)
							.foregroundStyle(.secondary)
							.symbolRenderingMode(.hierarchical)
					}
					.buttonStyle(.plain)
				}
			}
		}
		.onAppear {
			viewModel.load()
		}
	}

	// MARK: - Loading

	private var loadingView: some View {
		VStack(spacing: 16) {
			ProgressView()
				.scaleEffect(1.4)
			Text("Downloading Certificates...")
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - Error

	private func errorView(message: String) -> some View {
		VStack(spacing: 20) {
			Image(systemName: "exclamationmark.triangle.fill")
				.font(.system(size: 48))
				.foregroundStyle(.orange)
			Text("Failed to Load Certificates")
				.font(.headline)
			Text(message)
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
			Button {
				viewModel.load()
			} label: {
				Text("Retry")
					.font(.headline)
					.foregroundStyle(.white)
					.padding(.horizontal, 32)
					.padding(.vertical, 12)
					.background(Color.accentColor)
					.clipShape(Capsule())
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - Empty

	private var emptyView: some View {
		VStack(spacing: 16) {
			Image(systemName: "building.2.crop.circle")
				.font(.system(size: 48))
				.foregroundStyle(.secondary)
			Text("No Certificates Found")
				.font(.headline)
			Text("The archive did not contain any valid certificate pairs.")
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - List

	private var certificateList: some View {
		List(viewModel.certificates) { cert in
			Button {
				viewModel.importCertificate(cert)
			} label: {
				HStack(spacing: 16) {
					ZStack {
						RoundedRectangle(cornerRadius: 10, style: .continuous)
							.fill(Color.accentColor.opacity(0.12))
							.frame(width: 38, height: 38)
						Image(systemName: "building.2.fill")
							.font(.system(size: 16, weight: .semibold))
							.foregroundStyle(Color.accentColor)
					}

					VStack(alignment: .leading, spacing: 3) {
						Text(cert.name)
							.font(.system(size: 16, weight: .semibold))
							.foregroundStyle(.primary)
						Text("Tap to import certificate")
							.font(.caption)
							.foregroundStyle(.secondary)
					}

					Spacer()

					if viewModel.importedIDs.contains(cert.id) {
						Image(systemName: "checkmark.circle.fill")
							.font(.system(size: 20))
							.foregroundStyle(.green)
							.transition(.scale.combined(with: .opacity))
					}
				}
				.padding(.vertical, 4)
			}
			.buttonStyle(.plain)
			.animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.importedIDs)
		}
		.listStyle(.insetGrouped)
	}
}
