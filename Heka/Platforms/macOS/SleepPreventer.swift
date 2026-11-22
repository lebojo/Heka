import Foundation
import Observation

@MainActor @Observable final class SleepPreventer {
    private(set) var isPreventingSleep = false
    @ObservationIgnored private var activity: NSObjectProtocol?
    @ObservationIgnored private var expiry: Task<Void, Never>?
    @ObservationIgnored private var expiryDeadline: ContinuousClock.Instant?
    @ObservationIgnored private var lastActivity = ContinuousClock.now
    @ObservationIgnored private var lastDisconnection = ContinuousClock.now
    @ObservationIgnored private var isConnected = false
    @ObservationIgnored private weak var settings: SettingsStore?

    static let reconnectionGrace = Duration.seconds(60)

    func configure(settings: SettingsStore) {
        self.settings = settings
        observePolicy()
    }

    func update(isConnected: Bool) {
        guard isConnected != self.isConnected else { return }
        if !isConnected { lastDisconnection = .now }
        self.isConnected = isConnected
        refresh()
    }

    func recordActivity() {
        lastActivity = .now
        if !isPreventingSleep { refresh() }
    }

    func release() {
        isConnected = false
        lastDisconnection = .now - Self.reconnectionGrace
        refresh()
    }

    private func observePolicy() {
        withObservationTracking {
            _ = settings?.keepAwake
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.refresh()
                self?.observePolicy()
            }
        }
    }

    private var deadline: ContinuousClock.Instant? {
        guard let policy = settings?.keepAwake, policy != .never else { return .now }
        let activityDeadline = policy.idleLimit.map { lastActivity + $0 }
        guard !isConnected else { return activityDeadline }
        let graceDeadline = lastDisconnection + Self.reconnectionGrace
        return activityDeadline.map { min($0, graceDeadline) } ?? graceDeadline
    }

    private func refresh() {
        guard let deadline else {
            cancelExpiry()
            setPreventing(true)
            return
        }
        guard deadline > .now else {
            cancelExpiry()
            setPreventing(false)
            return
        }
        setPreventing(true)
        scheduleExpiry(at: deadline)
    }

    private func scheduleExpiry(at deadline: ContinuousClock.Instant) {
        if expiry != nil, let expiryDeadline, expiryDeadline <= deadline { return }
        expiry?.cancel()
        expiryDeadline = deadline
        expiry = Task { [weak self] in
            do { try await Task.sleep(until: deadline) } catch { return }
            self?.expiry = nil
            self?.expiryDeadline = nil
            self?.refresh()
        }
    }

    private func cancelExpiry() {
        expiry?.cancel()
        expiry = nil
        expiryDeadline = nil
    }

    private func setPreventing(_ prevent: Bool) {
        guard prevent != isPreventingSleep else { return }
        if prevent {
            activity = ProcessInfo.processInfo.beginActivity(
                options: .idleSystemSleepDisabled,
                reason: "Heka keeps the Mac awake while a mobile device is connected"
            )
        } else if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
        isPreventingSleep = prevent
    }
}
