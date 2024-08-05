import Foundation

struct CatalogOptions: Decodable {
    var info: Info
    var properties: Properties?

    struct Info: Decodable {
        var author: String
        var version: Int
    }

    struct Properties: Decodable {
        var generateSwiftAssetSymbolExtensions: String?
        var preservesVectorRepresentation: Bool?
        var providesNamespace: Bool?

        private enum CodingKeys: String, CodingKey {
            case generateSwiftAssetSymbolExtensions = "generate-swift-asset-symbol-extensions"
            case preservesVectorRepresentation = "preserves-vector-representation"
            case providesNamespace = "provides-namespace"
        }
    }
}
