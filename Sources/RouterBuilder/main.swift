import Foundation
import SwiftSyntax

class TokenVisitor : SyntaxVisitor {

    var currentViewControllerSyntax: ClassDeclSyntax?

    var initializerDeclSyntax: InitializerDeclSyntax?

    var routeInfo: RouteInfo?

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if (node.identifier.text.hasSuffix("ViewController")) {
            currentViewControllerSyntax = node
        }
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if (currentViewControllerSyntax == node) {
            currentViewControllerSyntax = nil
        }
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let currentViewControllerSyntax = currentViewControllerSyntax else {
            return .skipChildren
        }
        guard (node.parameters.parameterList.first?.type?.firstToken?.text != "NSCoder") else {
            return .skipChildren
        }
        let initializerFunctionParameterList: [RouteInfo.FunctionParameter] = node.parameters.parameterList.map { (functionParameterSyntax: FunctionParameterSyntax) in
            let typeSyntax: TypeSyntax = functionParameterSyntax.type!

            let name = functionParameterSyntax.firstName!.text
            let type = typeSyntax.firstToken!.text
            let required: Bool = typeSyntax.lastToken!.text != "?"

            return RouteInfo.FunctionParameter(name: name, type: type, required: required)
        }
        routeInfo = RouteInfo(
            viewControllerClassName: currentViewControllerSyntax.identifier.text,
            initializerFunctionParameterList: initializerFunctionParameterList
        )
        return .skipChildren
    }

}

class Node : Encodable {
    var text: String
    var children = [Node]()
    weak var parent: Node?

    enum CodingKeys : CodingKey {
        case text
        case children
        case range
        case token
    }

    init(text: String) {
        self.text = text
    }

    func add(node: Node) {
        node.parent = self
        children.append(node)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(children, forKey: .children)
    }
}

struct RouteInfo: Encodable {

    let viewControllerClassName: String

    struct FunctionParameter: Encodable {
        let name: String
        let type: String
        let required: Bool
        let value = ""
    }

    let initializerFunctionParameterList: [FunctionParameter]

}

func getViewControllerRouteInfo(filePath: URL) -> RouteInfo {
    let sourceFile = try! SyntaxParser.parse(filePath)
    let visitor = TokenVisitor()
    visitor.walk(sourceFile)
    return visitor.routeInfo!
}

let arguments = Array(CommandLine.arguments.dropFirst())
let folderPath = URL(fileURLWithPath: arguments[0]) // $SRCROOT/Resources
let files = try! FileManager.default.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: [], options: [])

let viewControllerURLInfoList = files.map(getViewControllerRouteInfo)

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let json = String(data: try! encoder.encode(viewControllerURLInfoList), encoding: .utf8)!

let outputPath = URL(fileURLWithPath: arguments[1]) // $SRCROOT/web/src/appRoutes.json
try! json.write(to: outputPath, atomically: true, encoding: .utf8)
