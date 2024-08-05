import Foundation

struct CatalogItem {
    var name: String
    var providesNamespace: Bool
    let rootNamespace: String?
    var colorsets: Set<String>
    var imagesets: Set<String>
    var children: [CatalogItem]

    var namespace: String? {
        guard providesNamespace else {
            return nil
        }

        return name
    }

    var pathComponent: String? {
        guard
            providesNamespace,
                name.isEmpty == false
        else {
            return nil
        }

        return name + "/"
    }

    var enumerationName: String? {
        guard providesNamespace else {
            return nil
        }

        return name.validSwiftTypeName
    }

    func allColorPaths(pathComponents: [String]) -> [(variableName: String, path: [String])] {
        var localPath = pathComponents
        if let namespace {
            localPath.append(namespace)
        }
        return colorsets.map { ($0, localPath) }
    }

    func recursiveColorPaths() -> [String] {
        let localPath = pathComponent ?? ""
        var paths = colorsets.map { localPath + $0 }

        for child in children {
            let childPaths = child.recursiveColorPaths().map { localPath + $0 }
            paths.append(contentsOf: childPaths)
        }

        return paths
    }

    func recursiveImagePaths() -> [String] {
        let localPath: String = if let pathComponent {
            pathComponent + "/"
        } else {
            ""
        }

        var paths = imagesets.map { localPath + $0 }

        for child in children {
            let childPaths = child.recursiveImagePaths().map { localPath + $0 }
            paths.append(contentsOf: childPaths)
        }

        return paths
    }

    func swiftUIColorCode(pathComponents: [String], accessLevel: String) -> String {
        let tabs = String(repeating: "\t", count: pathComponents.count)
        var contents = ""
        for (name, colorPath) in allColorPaths(pathComponents: pathComponents) {
            let variableName = name.validSwiftVariableName
            let resourcePath = colorPath.map(\.pascalCased) + [variableName]

            contents += """

            \(tabs)/// The "\(resourcePath.joined(separator: "/"))" asset catalog color resource.
            \(tabs)\(accessLevel) static var \(variableName): SwiftUI.Color { .init(.\(resourcePath.joined(separator: "."))) }

            """
        }
        return contents
    }

    func recursiveSwiftUIColorCode(pathComponents: [String], accessLevel: String) -> String {
        let tabs = String(repeating: "\t", count: pathComponents.count)
        var resolvedPathComponents: [String]
        var contents = ""

        if let enumerationName {
            resolvedPathComponents = pathComponents + [name]
            contents = """

            \(tabs)/// The "\(resolvedPathComponents.joined(separator: "/"))\(name)" asset catalog resource namespace.
            \(tabs)\(accessLevel) enum \(enumerationName) {

            """
        } else {
            resolvedPathComponents = pathComponents
        }

        contents += swiftUIColorCode(pathComponents: pathComponents, accessLevel: accessLevel)
        for child in children {
            let childCode = child.recursiveSwiftUIColorCode(pathComponents: resolvedPathComponents, accessLevel: accessLevel)

            contents += """
            \(childCode)
            """
        }

        if enumerationName != nil {
            contents += """

            \(tabs)}

            """
        }
        return contents
    }

    func colorCode(pathComponents: [String], accessLevel: String) -> String {
        let tabs = String(repeating: "\t", count: pathComponents.count)
        var contents = ""
        for (name, colorPath) in allColorPaths(pathComponents: pathComponents) {
            let variableName = name.validSwiftVariableName
            let resourcePath = colorPath + [name]

            contents += """

            \(tabs)/// The "\(resourcePath.joined(separator: "/"))" asset catalog color resource.
            \(tabs)\(accessLevel) static let \(variableName) = ColorResource(name: "\(resourcePath.joined(separator: "/"))", bundle: resourceBundle)

            """
        }
        return contents
    }

    func recursiveColorCode(pathComponents: [String], accessLevel: String) -> String {
        let tabs = String(repeating: "\t", count: pathComponents.count)
        var contents = ""

        if let enumerationName {
            contents = """

            \(tabs)/// The "\(name)" asset catalog resource namespace.
            \(tabs)\(accessLevel) enum \(enumerationName) {

            """
        }

        contents += colorCode(pathComponents: pathComponents, accessLevel: accessLevel)
        for child in children {
            let childCode = child.recursiveColorCode(pathComponents: pathComponents, accessLevel: accessLevel)

            contents += """
            \(childCode)
            """
        }

        if enumerationName != nil {
            contents += """

            \(tabs)}

            """
        }
        return contents
    }
}
