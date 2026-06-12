import SwiftUI

struct SettingsView: View {
	@ObservedObject var prefs: PreferencesStore
	@ObservedObject var updateController: UpdateController
	let t: SpacToken

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 0) {
				SpacSectionLabel("General", t: t)
				SpacCard(t: t) {
					SpacRow("Launch at Login", t: t) {
						Toggle("", isOn: $prefs.launchAtLogin)
							.labelsHidden()
							.toggleStyle(.switch)
					}
					SpacRowDivider(t: t)
					SpacRow("Show Menu Bar Icon",
					        description: "When hidden, spac runs silently in the background.",
					        t: t) {
						Toggle("", isOn: $prefs.showMenuBarIcon)
							.labelsHidden()
							.toggleStyle(.switch)
					}
					}

				SpacSectionLabel("Updates", spaced: true, t: t)
				SpacCard(t: t) {
					SpacRow("Check for Updates", t: t) {
						Button("Check now") { updateController.checkForUpdates() }
							.buttonStyle(SpacButtonStyle(t: t))
					}
				}

				Spacer(minLength: 24)
			}
			.padding(.horizontal, 24)
			.padding(.top, 56)
			.padding(.bottom, 24)
		}
	}
}
