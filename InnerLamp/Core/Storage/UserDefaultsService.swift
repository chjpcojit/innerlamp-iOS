//
//  UserDefaultsService.swift
//  base_project
//
//  Created by ChjpCoj on 2/5/26.
//

import Foundation

protocol UserDefaultsService {
    func save<T: Codable>(key: String, value: T)
    func load<T: Codable>(key: String, type: T.Type) -> T?
    func remove(key: String)
    func exists(key: String) -> Bool
}

final class UserDefaultsServiceImpl: UserDefaultsService {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save<T>(key: String, value: T) where T : Decodable, T : Encodable {
        if let data = try? encoder.encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func load<T>(key: String, type: T.Type) -> T? where T : Decodable, T : Encodable {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        return try? decoder.decode(T.self, from: data)
    }
    
    func remove(key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func exists(key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}

// Convenience extensions for common types
extension UserDefaultsService {
    func saveBool(key: String, value: Bool) {
        save(key: key, value: value)
    }
    
    func loadBool(key: String, defaultValue: Bool = false) -> Bool {
        return load(key: key, type: Bool.self) ?? false
    }
    
    func saveString(key: String, value: String) {
        save(key: key, value: value)
    }
    
    func loadString(key: String) -> String? {
        return load(key: key, type: String.self) ?? ""
    }
}
