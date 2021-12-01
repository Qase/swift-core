//
//  UserDefaults+.swift
//  
//
//  Created by Martin Troup on 01.09.2021.
//

import Foundation

public extension UserDefaults {
    func store<Value>(value: Value, forKey key: String) {
        set(value, forKey: key)
    }

    func delete(forKey key: String) {
        set(nil, forKey: key)
    }
}
