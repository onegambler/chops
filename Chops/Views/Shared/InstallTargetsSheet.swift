import SwiftUI

struct InstallTargetsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let skills: [Skill]
    var onComplete: (SourceInstallSummary) -> Void

    @State private var selectedTargetIDs: Set<String> = Set(AgentTarget.installed.map(\.id))
    @State private var isInstalling = false

    private var targets: [AgentTarget] {
        AgentTarget.all
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(targets) { target in
                    let installed = target.isInstalled
                    HStack {
                        Toggle(isOn: Binding(
                            get: { selectedTargetIDs.contains(target.id) },
                            set: { selected in
                                if selected {
                                    selectedTargetIDs.insert(target.id)
                                } else {
                                    selectedTargetIDs.remove(target.id)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(target.displayName)
                                Text(target.expandedSkillsDir)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .disabled(!installed)

                        Spacer()

                        if !installed {
                            Text("Not detected")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 7)

                    if target.id != targets.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 10)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("All Installed") {
                    selectedTargetIDs = Set(AgentTarget.installed.map(\.id))
                }
                Button {
                    install()
                } label: {
                    if isInstalling {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Install")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedTargetIDs.isEmpty || isInstalling)
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    private var title: String {
        skills.count == 1 ? "Install \(skills[0].name)" : "Install \(skills.count) Skills"
    }

    private func install() {
        isInstalling = true
        let selected = targets.filter { selectedTargetIDs.contains($0.id) }
        let summary = SourceInstallService.install(skills: skills, targets: selected)
        onComplete(summary)
        isInstalling = false
        dismiss()
    }
}
