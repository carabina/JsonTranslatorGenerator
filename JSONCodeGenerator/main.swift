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
    var parameters: Set<String>

    var translationKey: String {
        let name = self.name.lowercasedFirstLetter().replacingOccurrences(of: "-", with: "")

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

        return "\(tabsString)static let \(translationKey) = \"\(key)\""
    }
    
    func extractParameter(str: String, startOut: inout Int) -> String? {
        let subStr = String(str[str.index(str.startIndex, offsetBy: startOut)..<str.endIndex])
        if let start = subStr.range(of: "["), let end = subStr.range(of: "]") {
            let startIndex = start.upperBound
            let endIndex = end.lowerBound
            let parameter = subStr[startIndex..<endIndex]
            
            startOut = startOut + Int(endIndex.encodedOffset) + 1
            return String(parameter)
        }
        
        return nil
    }
    
    func name(for value: String) -> String {
        return value.lowercased()
            .split(separator: "_")
            .map(String.init)
            .map { $0.capitalizingFirstLetter() }
            .joined()
            .lowercasedFirstLetter().replacingOccurrences(of: "-", with: "")
    }

    init(_ key: String, _ translations: Any) {
        self.key = key
        self.parameters = Set()
        
        name = key.lowercased()
                .split(separator: "_")
                .map(String.init)
                .map { $0.capitalizingFirstLetter() }
                .joined()
        
        if let trsnalationsMap = translations as? [String: Any] {
            if let translation = trsnalationsMap.first?.value as? String {
                var start = 0
                while let parameter = self.extractParameter(str: translation, startOut: &start) {
                    self.parameters.insert(String(parameter))
                }
            }
        }
    }
}

let keys = texts.map { TranslationKey($0, $1) }
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

text.append("// swiftlint:disable type_body_length")
text.append("// swiftlint:disable identifier_name")

text.append("enum TranslationsKeys {")

lines["AlbertGenerated"]?.forEach {
    text.append($0.line(withNumberOfTabs: 1))
}

//lines["AlbertGenerated"] = nil
//
//for (translationKey, translations) in lines {
//    text.append("    enum \(translationKey) {")
//    translations.forEach { text.append($0.line(withNumberOfTabs: 2)) }
//    text.append("    }")
//}

text.append("}\n")

text.append("""
protocol TranslationParameter {
    func translation(for key: String, parameters: [String: String]) -> String
}

"""
)

text.append("extension TranslationParameter {")
lines["AlbertGenerated"]?.forEach {
    let t = $0
    if t.parameters.count > 0 {
        var strParameter = "   func \(t.name.lowercasedFirstLetter())("
        let parameters = Array(t.parameters)
        
        strParameter += parameters.map{ parameter in
            let funcParameter = t.name(for: parameter)
            return "\(funcParameter): String"
            
            }.joined(separator: ",")
        
        strParameter += ") -> String {\n"
        strParameter += "       let parameters = [\n"
        
        strParameter += parameters.map{ parameter in
            let funcParameter = t.name(for: parameter)
            return "           \(funcParameter): \"\(parameter)\""
            
            }.joined(separator: ",\n")
        strParameter += "\n"
        
        strParameter += "       ]\n"
        strParameter += "       return translation(for: \"\(t.key)\", parameters: parameters)\n"
        strParameter += "   }\n"
        text.append(strParameter)
    }
}
text.append("}")
text.append("// swiftlint:enable type_body_length")
text.append("// swiftlint:enable identifier_name\n")

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
