import Foundation

protocol KeyValueStoring {
    func data(forKey: String) -> Data?
    func set(_ value: Any?, forKey: String)
}

extension UserDefaults: KeyValueStoring {}

final class UserDefaultsStore {
    private let defaults: KeyValueStoring

    init(defaults: KeyValueStoring = UserDefaults.standard) {
        self.defaults = defaults
    }

    func load<T: Decodable>(_ type: T.Type, key: String, defaultValue: T) -> T {
        guard let data = defaults.data(forKey: key) else { return defaultValue }
        return (try? JSONDecoder().decode(type, from: data)) ?? defaultValue
    }

    func save<T: Encodable>(_ value: T, key: String) {
        let data = (try? JSONEncoder().encode(value))
        defaults.set(data, forKey: key)
    }
}
