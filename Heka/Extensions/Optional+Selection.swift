extension Optional where Wrapped: Hashable {
    subscript(selecting value: Wrapped) -> Bool {
        get { self == value }
        set {
            if newValue { self = value } else if self == value { self = nil }
        }
    }
}
