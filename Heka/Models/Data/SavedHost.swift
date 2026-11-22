import Foundation

struct SavedHost: Codable, Equatable, Identifiable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case id, name, addresses, pairingAccount, isScanned
    }

    let id: UUID
    var name: String
    var addresses: [String]
    let pairingAccount: String
    let isScanned: Bool

    init(id: UUID = UUID(), name: String, addresses: [String], pairingAccount: String? = nil, isScanned: Bool = false) {
        self.id = id
        self.name = name
        self.addresses = addresses
        self.pairingAccount = pairingAccount ?? "remotePairingCode.\(id.uuidString)"
        self.isScanned = isScanned
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        addresses = try container.decode([String].self, forKey: .addresses)
        pairingAccount = try container.decode(String.self, forKey: .pairingAccount)
        isScanned = try container.decodeIfPresent(Bool.self, forKey: .isScanned) ?? false
    }

    var summary: String { addresses.joined(separator: ", ") }

    func matches(_ invitation: PairingInvitation) -> Bool {
        id == invitation.hostID || !isScanned && !Set(addresses).isDisjoint(with: invitation.addresses)
    }

    func preferring(_ address: String) -> SavedHost {
        var host = self
        host.addresses = [address] + addresses.filter { $0 != address }
        return host
    }
}
