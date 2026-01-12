import SwiftUI

struct SettingsView: View {
	@ObservedObject var prefs: PreferencesStore

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack(spacing: 20) {
				Image("SettingsLogo")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 80, height: 80)
					.clipShape(RoundedRectangle(cornerRadius: 16))
				
				VStack(alignment: .leading, spacing: 4) {
					Text("spac")
						.font(.system(size: 32, weight: .heavy))
					Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}
			.padding(.horizontal, 30)
			.padding(.top, 30)
			.padding(.bottom, 20)
			
			Divider()
			
			// Content
			VStack(alignment: .leading, spacing: 15) {
				Toggle("Launch at Login", isOn: $prefs.launchAtLogin)
				Toggle("Show Menu Bar Icon", isOn: $prefs.showMenuBarIcon)
				Toggle("Show Icon in Dock", isOn: $prefs.showDockIcon)
			}
			.toggleStyle(.checkbox)
			.padding(30)
			
			Spacer()
			
			// Footer
			HStack {
				Button(role: .destructive) {
					NSApp.terminate(nil)
				} label: {
					Text("Quit spac")
						.frame(minWidth: 80)
				}
				.keyboardShortcut("q", modifiers: .command)
				.buttonStyle(.borderedProminent)
				
				Spacer()
				
				Link(destination: URL(string: "https://github.com/walkersutton/spac")!) {
					HStack(spacing: 4) {
						Image(systemName: "safari")
						Text("View on GitHub")
					}
				}
				.font(.footnote)
				.foregroundStyle(.link)
			}
			.padding(.horizontal, 30)
			.padding(.bottom, 30)
		}
		.frame(width: 400, height: 360)
	}
}


