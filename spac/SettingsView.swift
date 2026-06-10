import SwiftUI

// MARK: - Tab

enum SettingsTab: String, Hashable {
    case general, about
}

// MARK: - Design tokens

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

private struct SPToken {
    let dark: Bool

    var sidebarBg: Color { dark ? Color(hex: 0x232326) : Color(hex: 0xe7e7ea) }
    var contentBg: Color { dark ? Color(hex: 0x1c1c1e) : Color(hex: 0xf4f4f6) }
    var cardBg: Color { dark ? Color(hex: 0x2b2b2e) : .white }
    var divider: Color { dark ? .white.opacity(0.085) : .black.opacity(0.085) }
    var text: Color { dark ? .white : Color(hex: 0x1b1b1f) }
    var text2: Color {
        dark ? Color(red: 0.922, green: 0.922, blue: 0.961).opacity(0.62)
             : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.62)
    }
    var text3: Color {
        dark ? Color(red: 0.922, green: 0.922, blue: 0.961).opacity(0.34)
             : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.40)
    }
    var selBg: Color { dark ? .white.opacity(0.10) : .black.opacity(0.075) }
    var controlBg: Color { dark ? Color(hex: 0x3a3a3d) : .white }
    var controlBorder: Color { dark ? .white.opacity(0.10) : .black.opacity(0.14) }
    var topEdge: Color { dark ? .white.opacity(0.06) : .white.opacity(0.70) }
    var pillBg: Color { dark ? .white.opacity(0.07) : .black.opacity(0.04) }
    var pillBorder: Color { dark ? .white.opacity(0.10) : .black.opacity(0.08) }
}

// MARK: - Root view

struct SettingsView: View {
    @ObservedObject var prefs: PreferencesStore
    @ObservedObject var updateController: UpdateController
    @State private var selectedTab: SettingsTab = .general
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let t = SPToken(dark: colorScheme == .dark)
        HStack(spacing: 0) {
            SidebarView(selected: $selectedTab, t: t)
                .frame(width: 186)
            ContentArea(selectedTab: $selectedTab, prefs: prefs, updateController: updateController, t: t)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @Binding var selected: SettingsTab
    let t: SPToken

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            SidebarNavRow(label: "General", icon: "gearshape", isSelected: selected == .general, t: t) { selected = .general }
            SidebarNavRow(label: "About", icon: "info.circle", isSelected: selected == .about, t: t) { selected = .about }
            Spacer()
        }
        .padding(.top, 44)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity)
        .background(t.sidebarBg)
    }
}

private struct SidebarNavRow: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let t: SPToken
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 17, height: 17)
                    .foregroundStyle(isSelected ? t.text : t.text2)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(t.text)
                Spacer()
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? t.selBg : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

// MARK: - Content area

private struct ContentArea: View {
    @Binding var selectedTab: SettingsTab
    @ObservedObject var prefs: PreferencesStore
    @ObservedObject var updateController: UpdateController
    let t: SPToken

    var body: some View {
        ZStack(alignment: .topTrailing) {
            switch selectedTab {
            case .general:
                GeneralTab(prefs: prefs, updateController: updateController, t: t)
            case .about:
                AboutTab(t: t)
            }

            if selectedTab != .about {
                AppPill(t: t)
                    .padding(.top, 14)
                    .padding(.trailing, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) { t.topEdge.frame(height: 1) }
        .overlay(alignment: .leading) { t.divider.frame(width: 1) }
        .background(t.contentBg)
    }
}

// MARK: - App pill

private struct AppPill: View {
    let t: SPToken

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "capslock.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(t.text)
                .frame(width: 22, height: 22)
                .background(t.controlBg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(t.controlBorder, lineWidth: 1)
                }
            Text("spac")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(t.text)
        }
        .padding(.leading, 7)
        .padding(.trailing, 13)
        .padding(.vertical, 6)
        .background(t.pillBg)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(t.pillBorder, lineWidth: 1) }
    }
}

// MARK: - General tab

private struct GeneralTab: View {
    @ObservedObject var prefs: PreferencesStore
    @ObservedObject var updateController: UpdateController
    let t: SPToken

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SPSectionLabel("General", t: t)
                SPCard(t: t) {
                    SPRow("Launch at Login", t: t) {
                        Toggle("", isOn: $prefs.launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    SPDivider(t: t)
                    SPRow("Show Menu Bar Icon",
                          description: "When hidden, spac runs silently in the background.",
                          t: t) {
                        Toggle("", isOn: $prefs.showMenuBarIcon)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    SPDivider(t: t)
                    SPRow("Show Icon in Dock", t: t) {
                        Toggle("", isOn: $prefs.showDockIcon)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }

                SPSectionLabel("Updates", spaced: true, t: t)
                SPCard(t: t) {
                    SPRow("Check for Updates", t: t) {
                        Button("Check now") { updateController.checkForUpdates() }
                            .buttonStyle(SPButtonStyle(t: t))
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

// MARK: - About tab

private struct AboutTab: View {
    let t: SPToken
    private let githubURL = URL(string: "https://github.com/walkersutton/spac")!
    private let authorURL = URL(string: "https://walkersutton.com")!

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("SettingsLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 86, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 21))
                .shadow(color: .black.opacity(0.28), radius: 6, x: 0, y: 2)

            Text("spac")
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(t.text)
                .padding(.top, 18)

            Text("Version \(version)")
                .font(.system(size: 13))
                .foregroundStyle(t.text2)
                .padding(.top, 5)

            Text("A caps lock HUD for macOS.")
                .font(.system(size: 13))
                .foregroundStyle(t.text2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 290)
                .padding(.top, 16)

            Link("GitHub", destination: githubURL)
                .foregroundStyle(.accentColor)
                .font(.system(size: 13))
                .onHover { inside in
                    if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                .padding(.top, 20)

            HStack(spacing: 0) {
                Text("© 2025 ")
                Link("Walker Sutton", destination: authorURL)
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
            }
            .font(.system(size: 12))
            .foregroundStyle(t.text3)
            .padding(.top, 26)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 56)
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }
}

// MARK: - Shared components

private struct SPSectionLabel: View {
    let title: String
    var spaced: Bool = false
    let t: SPToken
    init(_ title: String, spaced: Bool = false, t: SPToken) {
        self.title = title; self.spaced = spaced; self.t = t
    }

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .tracking(-0.15)
            .foregroundStyle(t.text)
            .padding(.top, spaced ? 22 : 0)
            .padding(.bottom, 9)
            .padding(.horizontal, 4)
    }
}

private struct SPCard<Content: View>: View {
    let t: SPToken
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(t.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            if !t.dark {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
            }
        }
        .shadow(color: !t.dark ? .black.opacity(0.04) : .clear, radius: 2, x: 0, y: 1)
    }
}

private struct SPRow<Control: View>: View {
    let label: String
    var description: String?
    let t: SPToken
    @ViewBuilder let control: () -> Control
    init(_ label: String, description: String? = nil, t: SPToken,
         @ViewBuilder control: @escaping () -> Control) {
        self.label = label; self.description = description; self.t = t; self.control = control
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(t.text)
                if let desc = description {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(t.text2)
                }
            }
            Spacer()
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minHeight: 46)
    }
}

private struct SPDivider: View {
    let t: SPToken
    var body: some View {
        Rectangle()
            .fill(t.divider)
            .frame(height: 1)
            .padding(.leading, 14)
    }
}

private struct SPButtonStyle: ButtonStyle {
    let t: SPToken
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(t.text)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(t.controlBg)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(t.controlBorder, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}
