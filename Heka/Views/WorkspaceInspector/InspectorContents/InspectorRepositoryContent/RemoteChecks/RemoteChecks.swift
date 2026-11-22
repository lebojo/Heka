import SwiftUI

struct RemoteChecks: View {
    let model: InspectorStore
    let headSHA: String?

    var body: some View {
        RemoteSummary(model: model)
        if let remote = model.remote {
            if let pr = remote.changeRequest, let checks = pr.statusCheckRollup, !checks.isEmpty {
                Divider()
                Text(remote.hosting.changeRequestChecksTitle).font(.sectionTitle)
                if pr.headRefOid != headSHA {
                    Label { Text(remote.hosting.remoteCommitNotice) } icon: { Image(systemName: "info.circle") }
                        .font(.caption).foregroundStyle(Color.textSecondary)
                }
                ForEach(checks) { check in CheckRow(title: check.title, result: check.result, url: check.url) }
            }
            Divider()
            Text(remote.hosting.runsTitle).font(.sectionTitle)
            if let headSHA { Text(String(headSHA.prefix(8))).font(.captionMono).foregroundStyle(Color.textSecondary) }
            if let error = remote.checksError {
                InspectorNotice(title: remote.hosting.runsUnavailableTitle, error: error)
            } else if remote.runs.isEmpty {
                Text(headSHA == nil ? "No commits in this repository." : remote.hosting.noRunsMessage)
                    .font(.callout).foregroundStyle(Color.textSecondary)
            }
            ForEach(remote.runs) { run in CheckRow(title: run.workflowName.isEmpty ? run.displayTitle : run.workflowName, result: run.result, url: run.url) }
        }
    }
}
