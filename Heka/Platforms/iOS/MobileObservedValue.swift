import Observation

@MainActor @Observable final class MobileObservedValue<Value: Equatable> {
    private(set) var value: Value?

    init(_ value: Value?) {
        self.value = value
    }

    func update(_ newValue: Value?) {
        if value != newValue { value = newValue }
    }
}
