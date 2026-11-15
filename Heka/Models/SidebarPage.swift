import SwiftUI

enum SidebarPage: String, CaseIterable, Identifiable, Sendable {
    case projects
    case workInProgress

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .projects: "Projects"
        case .workInProgress: "Work in Progress"
        }
    }

    var systemImage: String {
        switch self {
        case .projects: "folder"
        case .workInProgress: "bolt.horizontal"
        }
    }

    var searchPrompt: LocalizedStringKey {
        switch self {
        case .projects: "Filter projects and terminals"
        case .workInProgress: "Filter terminals"
        }
    }
}
