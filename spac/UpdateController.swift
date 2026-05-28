import Foundation
import Sparkle

@MainActor
final class UpdateController: ObservableObject {
	static let shared = UpdateController()

	private let updaterController: SPUStandardUpdaterController

	private init() {
		updaterController = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: nil,
			userDriverDelegate: nil
		)
	}

	func checkForUpdates() {
		updaterController.checkForUpdates(nil)
	}
}
