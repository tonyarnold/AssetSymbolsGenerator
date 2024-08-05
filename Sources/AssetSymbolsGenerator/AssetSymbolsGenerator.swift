import ArgumentParser
import Foundation
import SwiftFormat
import SwiftSyntax

// MARK: - AssetSymbolsGenerator
@main
struct AssetSymbolsGenerator: AsyncParsableCommand {
    @Argument(transform: { URL(fileURLWithPath: $0) })
    var path: URL

    @Option(name: [.short, .customLong("output")], help: "The path to output the result.", transform: { URL(fileURLWithPath: $0) })
    var outputPath: URL

    @Option(name: [.short, .customLong("access-level")], help: "The access level of the output constants.")
    var accessLevel = "public"

    @Option(name: [.short, .customLong("include-color-resources")], help: "Whether to include the ColorResource constants.")
    var includeColorResources = false

    @Option(name: [.short, .long], help: "The namespace to wrap the constants within.")
    var namespace: String?

    func validate() throws {
        guard path.pathExtension == "xcassets" else {
            throw Error.notAnAssetCatalog
        }
    }

    mutating func run() async throws {
        guard let catalog = try catalog(for: path, rootNamespace: namespace) else {
            return
        }

        var contents = """
        #if canImport(SwiftUI)
        public import SwiftUI
        #endif
        #if canImport(DeveloperToolsSupport)
        public import DeveloperToolsSupport
        #endif
        """

        if includeColorResources {
            contents += """

            #if SWIFT_PACKAGE
            private let resourceBundle = Foundation.Bundle.module
            #else
            private class ResourceBundleClass {}
            private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
            #endif

            // MARK: - Color Symbols -

            @available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
            extension ColorResource {

                \(catalog.recursiveColorCode(pathComponents: [], accessLevel: accessLevel))

            }
            """
        }

        contents += """

        #if canImport(SwiftUI)
        @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
        extension SwiftUI.Color {

            \(catalog.recursiveSwiftUIColorCode(pathComponents: [], accessLevel: accessLevel))

        }
        #endif
        """

        let configuration = Configuration()
        let formatter = SwiftFormatter(configuration: configuration)

        var buffer = ""
        try formatter.format(
            source: contents,
            assumingFileURL: outputPath,
            to: &buffer
        )

        if buffer != contents {
          let bufferData = buffer.data(using: .utf8)! // Conversion to UTF-8 cannot fail
          try bufferData.write(to: outputPath, options: .atomic)
        }
    }

    enum Error: Swift.Error {
        case notAnAssetCatalog
    }

    private func catalog(for path: URL, rootNamespace: String?) throws -> CatalogItem? {
        var providesNamespace = false

        // Read Contents.json
        let contentsURL = path.appendingPathComponent("Contents.json")
        if let contentsData = try? Data(contentsOf: contentsURL) {
            let contents = try JSONDecoder().decode(CatalogOptions.self, from: contentsData)
            providesNamespace = contents.properties?.providesNamespace ?? false
        }

        var colorsets: Set<String> = []
        var imagesets: Set<String> = []

        let contents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        for item in contents {
            guard item.hasDirectoryPath else {
                continue
            }

            if item.pathExtension == "colorset" {
                colorsets.insert(item.deletingPathExtension().lastPathComponent)
            } else if item.pathExtension == "imageset" {
                imagesets.insert(item.deletingPathExtension().lastPathComponent)
            }
        }

        let children = try childCatalogItems(for: path, rootNamespace: rootNamespace)

        return CatalogItem(
            name: path.deletingPathExtension().lastPathComponent,
            providesNamespace: providesNamespace,
            rootNamespace: rootNamespace,
            colorsets: colorsets,
            imagesets: imagesets,
            children: children
        )
    }

    private func childCatalogItems(for path: URL, rootNamespace: String?) throws -> [CatalogItem] {
        var items: [CatalogItem] = []

        let contents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

        for item in contents {
            guard item.hasDirectoryPath else {
                continue
            }

            if let catalogItem = try? catalog(for: item, rootNamespace: rootNamespace) {
                items.append(catalogItem)
            }
        }

        return items.sorted { $0.name > $1.name }
    }
}
