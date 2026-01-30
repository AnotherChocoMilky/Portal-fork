import SwiftUI

struct FRAppIconView: View {
	private var _app: AppInfoPresentable
	private var _size: CGFloat
	@AppStorage("Feather.shouldTintIcons") private var _shouldTintIcons: Bool = false
	@AppStorage("Feather.userTintColor") private var _userTintColor: String = "#0077BE"
	@AppStorage("Feather.userTintColorType") private var _colorType: String = "solid"
	@AppStorage("Feather.userTintGradientStart") private var _gradientStartHex: String = "#0077BE"
	@AppStorage("Feather.userInterfaceStyle") private var _userInterfaceStyle: Int = 0

	@State private var _tintedIcon: UIImage?
	
	init(app: AppInfoPresentable, size: CGFloat = 87) {
		self._app = app
		self._size = size
	}
	
	var body: some View {
		Group {
			if _shouldTintIcons {
				if let tintedIcon = _tintedIcon {
					Image(uiImage: tintedIcon)
						.appIconStyle(size: _size)
				} else {
					originalIconView
						.onAppear {
							loadTintedIcon()
						}
				}
			} else {
				originalIconView
			}
		}
		.onChange(of: _shouldTintIcons) { newValue in
			if newValue {
				loadTintedIcon()
			}
		}
		.onChange(of: _userTintColor) { _ in loadTintedIcon() }
		.onChange(of: _colorType) { _ in loadTintedIcon() }
		.onChange(of: _gradientStartHex) { _ in loadTintedIcon() }
		.onChange(of: _userInterfaceStyle) { _ in loadTintedIcon() }
	}

	@ViewBuilder
	private var originalIconView: some View {
		if
			let iconFilePath = Storage.shared.getAppDirectory(for: _app)?.appendingPathComponent(_app.icon ?? ""),
			let uiImage = UIImage(contentsOfFile: iconFilePath.path)
		{
			Image(uiImage: uiImage)
				.appIconStyle(size: _size)
		} else {
			Image("App_Unknown")
				.appIconStyle(size: _size)
		}
	}

	private func loadTintedIcon() {
		guard _shouldTintIcons else { return }
		Task.detached(priority: .userInitiated) {
			if let bundleURL = Storage.shared.getAppDirectory(for: _app),
			   let tinted = iconTest(bundleURL) {
				await MainActor.run {
					self._tintedIcon = tinted
				}
			}
		}
	}
}
