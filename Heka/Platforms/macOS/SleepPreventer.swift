import Foundation
import IOKit.pwr_mgt
import Observation

@MainActor @Observable final class SleepPreventer {
    private(set) var isPreventingSleep = false
    @ObservationIgnored private var assertion: IOPMAssertionID = 0
    @ObservationIgnored private var expiry: Task<Void, Never>?
    @ObservationIgnored private var lastActivity = ContinuousClock.now
    @ObservationIgnored private var isConnected = false
    @ObservationIgnored private var policy = KeepAwakePolicy.oneHour

    func update(isConnected: Bool, policy: KeepAwakePolicy) {
        self.isConnected = isConnected
        self.policy = policy
        refresh()
    }

    func recordActivity() {
        lastActivity = .now
        refresh()
    }

    func release() {
        isConnected = false
        refresh()
    }

    private func refresh() {
        expiry?.cancel()
        expiry = nil
        guard isConnected else { setPreventing(false); return }
        guard let limit = policy.idleLimit else { setPreventing(true); return }
        let remaining = limit - (ContinuousClock.now - lastActivity)
        guard remaining > .zero else { setPreventing(false); return }
        setPreventing(true)
        expiry = Task { [weak self] in
            do { try await Task.sleep(for: remaining) } catch { return }
            self?.refresh()
        }
    }

    private func setPreventing(_ prevent: Bool) {
        guard prevent != isPreventingSleep else { return }
        if prevent {
            var id: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Heka keeps the Mac awake while a mobile device is connected" as CFString,
                &id
            )
            guard result == kIOReturnSuccess else { return }
            assertion = id
        } else {
            IOPMAssertionRelease(assertion)
            assertion = 0
        }
        isPreventingSleep = prevent
    }
}
