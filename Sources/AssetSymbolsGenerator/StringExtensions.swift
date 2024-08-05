import Foundation

extension String {
    var camelCased: String {
        guard !isEmpty else { return "" }
        let parts = components(separatedBy: .alphanumerics.inverted)
        let first = parts.first!.lowercasingFirst
        let rest = parts.dropFirst().map(\.uppercasingFirst)

        return ([first] + rest).joined()
    }

    var pascalCased: String {
        guard !isEmpty else { return "" }
        let parts = components(separatedBy: .alphanumerics.inverted)
        return parts.map(\.uppercasingFirst).joined()
    }

    var validSwiftTypeName: String {
        var modifiedName = pascalCased

        if let firstCharacter = modifiedName.unicodeScalars.first, CharacterSet.decimalDigits.contains(firstCharacter) {
            modifiedName = "_\(firstCharacter)" + modifiedName.dropFirst().uppercasingFirst
        }

        return modifiedName
    }

    var validSwiftVariableName: String {
        var modifiedName = camelCased

        if let firstCharacter = modifiedName.unicodeScalars.first, CharacterSet.decimalDigits.contains(firstCharacter) {
            modifiedName = "_\(firstCharacter)" + modifiedName.dropFirst().uppercasingFirst
        } else if self == "default" {
            modifiedName = "`" + modifiedName + "`"
        }

        return modifiedName
    }
}

extension StringProtocol {
    var lowercasingFirst: String { prefix(1).lowercased() + dropFirst() }
    var uppercasingFirst: String { prefix(1).uppercased() + dropFirst() }
}
