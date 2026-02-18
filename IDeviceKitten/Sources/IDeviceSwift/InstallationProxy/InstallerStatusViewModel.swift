//
//  InstallerStatusViewModel.swift
//  IDeviceKit
//
//  Created by samara on 3.06.2025.
//

import Combine

extension InstallerStatusViewModel {
	public enum InstallerStatus: Equatable {
		case none
		case ready
		case sendingManifest
		case sendingPayload
		case installing
		case completed(Result<Void, Error>)
		case broken(Error)

		public static func == (lhs: InstallerStatus, rhs: InstallerStatus) -> Bool {
			switch (lhs, rhs) {
			case (.none, .none),
				 (.ready, .ready),
				 (.sendingManifest, .sendingManifest),
				 (.sendingPayload, .sendingPayload),
				 (.installing, .installing):
				return true
			case (.completed(let lhsResult), .completed(let rhsResult)):
				switch (lhsResult, rhsResult) {
				case (.success, .success):
					return true
				case (.failure(let lhsError), .failure(let rhsError)):
					return "\(lhsError)" == "\(rhsError)"
				default:
					return false
				}
			case (.broken(let lhsError), .broken(let rhsError)):
				return "\(lhsError)" == "\(rhsError)"
			default:
				return false
			}
		}
	}
}

public class InstallerStatusViewModel: ObservableObject {
	@Published public var status: InstallerStatus
	@Published public var uploadProgress: Double = 0.0
	@Published public var packageProgress: Double = 0.0
	@Published public var installProgress: Double = 0.0
	
	public var isIDevice: Bool
	
	public var overallProgress: Double {
		if isIDevice {
			(installProgress + uploadProgress + packageProgress) / 3.0
		} else {
			packageProgress
		}
	}
	
	public var isCompleted: Bool {
		if case .completed = status {
			true
		} else {
			false
		}
	}
	
	public init(
		status: InstallerStatus = .none,
		isIdevice: Bool = true
	) {
		self.status = status
		self.isIDevice = isIdevice
	}
}
