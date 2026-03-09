import SwiftUI

// MARK: - View

struct CertificateEnterpriseView: View {
	@Environment(\.dismiss) private var dismiss
	@StateObject private var fetcher = CertificateEnterpriseFetcher.shared
	@State private var importedIDs: Set<UUID> = []
	@State private var importErrorMessage: String? = nil

	private let p12Password = "WSF"

	var body: some View {
		NavigationStack {
			ZStack {
				Color(UIColor.systemGroupedBackground)
					.ignoresSafeArea()

				Group {
					if fetcher.isLoading {
						loadingView
					} else if let error = fetcher.errorMessage {
						errorView(message: error)
					} else if fetcher.certificates.isEmpty {
						emptyView
					} else {
						certificateList
					}
				}
			}
			.navigationTitle("Enterprise Certificates")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					if !fetcher.isLoading {
						Button {
							fetcher.fetchEnterpriseCertificates(forceRefresh: true)
						} label: {
							Image(systemName: "arrow.clockwise")
								.font(.system(size: 16, weight: .medium))
						}
					}
				}
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
			.alert(
				"Import Error",
				isPresented: Binding(
					get: { importErrorMessage != nil },
					set: { if !$0 { importErrorMessage = nil } }
				)
			) {
				Button("OK", role: .cancel) { importErrorMessage = nil }
			} message: {
				if let msg = importErrorMessage {
					Text(msg)
				}
			}
		}
		.onAppear {
			fetcher.fetchEnterpriseCertificates(forceRefresh: false)
		}
	}

	// MARK: - Loading

	private var loadingView: some View {
		VStack(spacing: 16) {
			ProgressView()
				.scaleEffect(1.4)
			Text("Fetching Enterprise Certificates")
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
				fetcher.fetchEnterpriseCertificates(forceRefresh: false)
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
			Text("No Enterprise certificates were found. Try fetching again.")
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - List

	private var certificateList: some View {
		List(fetcher.certificates) { cert in
			Button {
				importCertificate(cert)
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
						Text(cert.certificateName)
							.font(.system(size: 16, weight: .semibold))
							.foregroundStyle(.primary)
						Text("Tap to import certificate")
							.font(.caption)
							.foregroundStyle(.secondary)
					}

					Spacer()

					if importedIDs.contains(cert.id) {
						Image(systemName: "checkmark.circle.fill")
							.font(.system(size: 20))
							.foregroundStyle(.green)
							.transition(.scale.combined(with: .opacity))
					}
				}
				.padding(.vertical, 4)
			}
			.buttonStyle(.plain)
			.animation(.spring(response: 0.3, dampingFraction: 0.7), value: importedIDs)
		}
		.listStyle(.insetGrouped)
	}

	// MARK: - Import

	private func importCertificate(_ certificate: EnterpriseCertificate) {
		FR.handleCertificateFiles(
			p12URL: certificate.p12URL,
			provisionURL: certificate.provisionURL,
			p12Password: p12Password,
			certificateName: certificate.certificateName,
			isDefault: false
		) { error in
			Task { @MainActor in
				if let error = error {
					importErrorMessage = error.localizedDescription
				} else {
					importedIDs.insert(certificate.id)
					HapticsManager.shared.success()
				}
			}
		}
	}
}
