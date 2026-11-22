import SwiftUI

extension SubagentStatus {
    var color: Color {
        switch self {
        case .working: Color.agentWorking
        case .done: Color.success
        case .stopped: Color.textSecondary
        }
    }
}
