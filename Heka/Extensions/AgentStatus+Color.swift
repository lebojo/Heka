import SwiftUI

extension AgentStatus {
    var color: Color {
        switch self {
        case .working: Color.agentWorking
        case .ready: Color.success
        case .waitingForInput: Color.warning
        }
    }
}
