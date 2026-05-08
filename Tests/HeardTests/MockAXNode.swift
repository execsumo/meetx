import Foundation
import HeardCore

/// JSON-decodable AX tree node for RosterReader tests.
/// Maps directly to the fixture JSON schema:
///   { "role": "AXGroup", "identifier": "roster-list", "children": [...] }
public struct MockAXNode: Codable {
    public var role: String?
    public var identifier: String?
    public var description: String?
    public var value: String?
    public var title: String?
    public var children: [MockAXNode]?

    public init(
        role: String? = nil,
        identifier: String? = nil,
        description: String? = nil,
        value: String? = nil,
        title: String? = nil,
        children: [MockAXNode]? = nil
    ) {
        self.role = role
        self.identifier = identifier
        self.description = description
        self.value = value
        self.title = title
        self.children = children
    }
}

extension MockAXNode: AXNode {
    public var axRole: String?        { role }
    public var axIdentifier: String?  { identifier }
    public var axDescription: String? { description }
    public var axValue: String?       { value }
    public var axTitle: String?       { title }
    public var axChildren: [any AXNode]? { children?.map { $0 as any AXNode } }
}

/// Load a MockAXNode tree from a JSON fixture file relative to this source file.
public func loadFixture(_ filename: String) throws -> MockAXNode {
    let fixturesDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")
    let url = fixturesDir.appendingPathComponent(filename)
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(MockAXNode.self, from: data)
}
