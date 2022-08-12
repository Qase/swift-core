//
//  KeychainQueryValue.swift
//  
//
//  Created by Martin Troup on 12.09.2021.
//

import Foundation

typealias KeychainQueryValue = [String: Any]

extension KeychainQueryValue {
    var cfDictionary: CFDictionary { self as CFDictionary }
}
