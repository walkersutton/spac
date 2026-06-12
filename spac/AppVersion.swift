import Foundation

enum AppVersion {
	static var displayString: String {
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
		let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

		switch (version.isEmpty, build.isEmpty) {
		case (false, false):
			return "\(version) (\(build))"
		case (false, true):
			return version
		case (true, false):
			return build
		case (true, true):
			return "Unknown"
		}
	}
}
