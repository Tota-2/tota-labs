import Foundation

final class CloudSaveService {
    static let shared = CloudSaveService()

    private let store = NSUbiquitousKeyValueStore.default

    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private init() {}

    func data(for key: String) -> Data? {
        guard isAvailable else { return nil }
        store.synchronize()
        return store.data(forKey: key)
    }

    @discardableResult
    func save(data: Data, for key: String) -> Bool {
        guard isAvailable else { return false }
        store.set(data, forKey: key)
        return store.synchronize()
    }
}
