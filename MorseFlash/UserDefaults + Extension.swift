//
//  UserDefaults + Extension.swift
//  MorseFlash
//
//  Created by Руслан Садыков on 03.07.2023.
//

import Foundation

// MARK: – UserDefaultsKeys extension
extension UserDefaults {
    enum UserDefaultsKeys: String {
        case isNeedTutorial
    }

    var isNeedTutorial: Bool? {
        set { setCustomObject(customObject: newValue, forKey: UserDefaultsKeys.isNeedTutorial.rawValue) }
        get { return getCustomObject(forKey: UserDefaultsKeys.isNeedTutorial.rawValue) }
    }
}

// MARK: – Custom objects extension
extension UserDefaults {
    func setCustomObject<T: Codable>(customObject: T, forKey: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(customObject) {
            set(encoded, forKey: forKey)
        }
    }
    func getCustomObject<T: Codable>(forKey: String) -> T? {
        if let decoded  = object(forKey: forKey) as? Data{
            let decoder = JSONDecoder()
            if let decodedObject = try? decoder.decode(T.self, from: decoded) {
                return decodedObject
            }
        }
        return nil
    }
}
