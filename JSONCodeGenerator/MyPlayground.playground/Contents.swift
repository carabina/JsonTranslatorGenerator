//: Playground - noun: a place where people can play

import UIKit

var fileURL = Bundle.main.url(forResource: "translations", withExtension: "json")
var json = [String: Any]()
do {
    if let url = fileURL {
        let content = try Data(contentsOf: url)
        json = try JSONSerialization.jsonObject(with: content) as! [String: Any]
        
    }
} catch {
    print("Couldn't read json file: \(error)")
}

let texts = json["texts"] as! [String: Any]

var result = ""

result += """
struct TranslationKey {
    let key: String
    
    init(_ key: String) {
        self.key = key
    }
}
"""

var rootFolder = [String: Any]()

let separate = "CONTACT_FORM_EU_VAT_NUMBER_FIELD_TITLE-ASD".components(separatedBy: ["_"])

texts.forEach { key, _ in
    let paths = key.components(separatedBy: ["_"])
}

func putSubFolder(paths: [String], folder: [String: Any]) {
    paths.forEach { path in
        if let existedPath = folder[path] {
        } else {
            folder[path] = [String: Any]()
        }
    }
}
