//
//  Preferences.swift
//  drone-project
//
//  Created by klab on 2021/01/06.
//

import Foundation

class Preferences: Codable {
    
    var serverIPAddr = ""
    var serverPort = ""
    var serverStreamPort = ""
    
    class func save(_ pref: Preferences) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Preferences.plist")
        do {
            let data = try encoder.encode(pref)
            try data.write(to: path)
        } catch {
            print(error)
        }
    }
    
    class func load() -> Preferences {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Preferences.plist")
        if let xml = FileManager.default.contents(atPath: path.path),
            let pref = try? PropertyListDecoder().decode(Preferences.self, from: xml) {
            return pref
        }
        return Preferences()
    }
}
