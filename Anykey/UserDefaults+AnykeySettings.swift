//
//  UserDefaults+AnykeySettings.swift
//  Anykey
//
//  Created by Artem Chistyakov on 2/18/21.
//

import Foundation

let configPathKey: String = "configPath"
let configPathDefault: String = "~/.Anykey.json"

extension UserDefaults {
    @objc dynamic var configPath: String {
        let value = string(forKey: configPathKey) ?? configPathDefault
        return value.isEmpty ? configPathDefault : value
    }
}
