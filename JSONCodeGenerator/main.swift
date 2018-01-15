//
//  main.swift
//  JSONCodeGenerator
//
//  Created by Vladyslav Zavalykhatko on 20/10/2017.
//  Copyright © 2017 HatCom. All rights reserved.
//

import Foundation

func readJSON() -> Any? {
    guard CommandLine.arguments.count > 1 else { exit(-1) }
    let path = CommandLine.arguments[1]
    let url = URL(fileURLWithPath: path)
    if url.path.count > 0 {
        do {
            let content = try Data(contentsOf: url)
            return try JSONSerialization.jsonObject(with: content)
        } catch {
            print("Couldn't read json file: \(error)")
        }
    }

    return nil
}

guard
        let json = readJSON() as? [String: Any],
        let texts = json["texts"] as? [String: Any]
        else {
    exit(-1)
}

struct TranslationKey {
    static private let subEnumKeySeparator = Character("|")
    let key: String
    let name: String

    var translationKey: String {
        let name = self.name.lowercasedFirstLetter()

        guard let idx = name.index(of: TranslationKey.subEnumKeySeparator) else { return name }

        return String(name[name.index(after: idx)...])
    }

    var subEnumKey: String? {
        guard let idx = name.index(of: TranslationKey.subEnumKeySeparator) else { return nil }

        return String(name[..<idx])
    }

    func line(withNumberOfTabs tabs: Int) -> String {
        let oneTab = "    "
        var tabsString = ""

        for _ in 0..<tabs {
            tabsString += oneTab
        }

        return "\(tabsString)static let \(translationKey) = Translations.Key(\"\(key)\")"
    }

    init(_ key: String) {
        self.key = key
        name = key.lowercased().characters
                .split(separator: "_")
                .map(String.init)
                .map { $0.capitalizingFirstLetter() }
                .joined()
    }
}

let keys = texts.keys.map { TranslationKey($0) }
var lines = [String: [TranslationKey]]()

lines["AlbertGenerated"] = [TranslationKey]()

keys.forEach { key in
    let subEnumKey = key.subEnumKey ?? "AlbertGenerated"

    if lines[subEnumKey] == nil {
        lines[subEnumKey] = [TranslationKey]()
    }

    lines[subEnumKey]?.append(key)
}

var text = [String]()

text.append("extension Translations.Key {")

lines["AlbertGenerated"]?.forEach {
    text.append($0.line(withNumberOfTabs: 1))
}

lines["AlbertGenerated"] = nil

for (translationKey, translations) in lines {
    text.append("    enum \(translationKey) {")
    translations.forEach { text.append($0.line(withNumberOfTabs: 2)) }
    text.append("    }")
}

text.append("}")

let joined = text.joined(separator: "\n")

let outputPath: String

if CommandLine.arguments.count > 2 {
    outputPath = CommandLine.arguments[2].appending("/TranslationJSON.generated.swift")
    try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: CommandLine.arguments[2]),
            withIntermediateDirectories: true
    )
} else {
    outputPath = "/TranslationJSON.generated.swift"
}

try? joined.write(toFile: outputPath, atomically: true, encoding: .utf8)
