import Foundation
import SwiftSyntax

class TokenVisitor : SyntaxVisitor {
    var tree = [Node]()
    var current: Node!

    override func visitPre(_ node: Syntax) {
        var syntax = "\(type(of: node))"
        if syntax.hasSuffix("Syntax") {
            syntax = String(syntax.dropLast(6))
        }

        let node = Node(text: syntax)
        if current == nil {
            tree.append(node)
        } else {
            current.add(node: node)
        }
        current = node
    }
    
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        current.text = token.text
        processToken(token)
        return .visitChildren
    }

    override func visitPost(_ node: Syntax) {
        current = current.parent
    }

    private func processToken(_ token: TokenSyntax) {
        var kind = "\(token.tokenKind)"
        if let index = kind.index(of: "(") {
            kind = String(kind.prefix(upTo: index))
        }
        if kind.hasSuffix("Keyword") {
            kind = "keyword"
        }
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
    let sourceFile = try! SyntaxTreeParser.parse(filePath)
    
    let visitor = TokenVisitor()
    sourceFile.walk(visitor)

    let tree = visitor.tree

    let codeBlockItemList = tree.first!.children.first(where: { $0.text == "CodeBlockItemList" })!
    let controllerClassDecl = codeBlockItemList.children.flatMap({ $0.children })
        .first(where: { $0.text == "ClassDecl" && $0.children.contains(where: { $0.text.contains("ViewController") }) })!

    let viewControllerClassName = controllerClassDecl.children.first(where: { $0.text.contains("ViewController") })!.text

    let initializerDecl = controllerClassDecl
        .children.first(where: { $0.text == "MemberDeclBlock" })!
        .children.first(where: { $0.text == "MemberDeclList" })!
        .children.flatMap({ $0.children }) // List 类型解包出 Item 的内容
        .first(where: { $0.text == "InitializerDecl" })!

    let initializerFunctionParameterList = initializerDecl
        .children.first(where: { $0.text == "ParameterClause" })!
        .children.first(where: { $0.text == "FunctionParameterList" })!
        .children.map { (functionParameter) -> RouteInfo.FunctionParameter in
            let name = functionParameter.children[0].text
            var simpleTypeIdentifierSuperNode = functionParameter.children.first(where: { $0.text == "SimpleTypeIdentifier" })
            var required = true
            if let optionalType = functionParameter.children.first(where: { $0.text == "OptionalType" }) {
                simpleTypeIdentifierSuperNode = optionalType.children.first(where: { $0.text == "SimpleTypeIdentifier" })
                required = false
            }
            let type = simpleTypeIdentifierSuperNode!.children.first!.text
            return RouteInfo.FunctionParameter(name: name, type: type, required: required)
    }

    return RouteInfo(viewControllerClassName: viewControllerClassName, initializerFunctionParameterList: initializerFunctionParameterList)
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

let routesContentDictionaryElementList: [DictionaryElementSyntax] = viewControllerURLInfoList.map { (routeInfo) -> DictionaryElementSyntax in
    let initializerFunctionParameterListString = routeInfo.initializerFunctionParameterList
        .map { (parameter) -> String in
            var result = "\n            \(parameter.name): "
            if parameter.required {
                var value = "queryItems.first(where: { $0.name == \"\(parameter.name)\" })!.value!"
                if parameter.type != "String" {
                    value = "\(parameter.type)(\(value))!"
                }
                result.append(value)
            } else {
                var value = "queryItems.first(where: { $0.name == \"\(parameter.name)\" })?.value"
                if parameter.type != "String" {
                    value = "\(value).flatMap(\(parameter.type).init)"
                }
                result.append(value)
            }
            return result
        }
        .joined(separator: ",")
    let result = "return \(routeInfo.viewControllerClassName)(\(initializerFunctionParameterListString)\n        )"
    return DictionaryElementSyntax { (builder: inout DictionaryElementSyntaxBuilder) in
        builder.useKeyExpression(SyntaxFactory.makeStringLiteralExpr(routeInfo.viewControllerClassName, leadingTrivia: .spaces(4)))
        builder.useColon(SyntaxFactory.makeColonToken())
        builder.useValueExpression(SyntaxFactory.makeClosureExpr(
            leftBrace: SyntaxFactory.makeLeftBraceToken(leadingTrivia: .spaces(1)),
            signature: SyntaxFactory.makeClosureSignature(
                capture: nil,
                input: SyntaxFactory.makeIdentifier("queryItems", leadingTrivia: .spaces(1), trailingTrivia: .spaces(1)),
                throwsTok: nil,
                output: nil,
                inTok: SyntaxFactory.makeInKeyword(trailingTrivia: .newlines(1))
            ),
            statements: SyntaxFactory.makeCodeBlockItemList([
                SyntaxFactory.makeCodeBlockItem(item: SyntaxFactory.makeIdentifier(result, leadingTrivia: .spaces(8)), semicolon: SyntaxFactory.makeIdentifier("", leadingTrivia: [.newlines(1), .spaces(4)]), errorTokens: nil)
                ]),
            rightBrace: SyntaxFactory.makeRightBraceToken())
        )
        builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: Trivia.newlines(1)))
    }
}

var routesSourceFile = SyntaxFactory.makeBlankSourceFile()
routesSourceFile = routesSourceFile.addCodeBlockItem(CodeBlockItemSyntax({ (builder) in
    builder.useItem(ImportDeclSyntax { (builder) in
        builder.useImportTok(SyntaxFactory.makeImportKeyword(trailingTrivia: .spaces(1)))
        builder.useImportKind(SyntaxFactory.makeIdentifier("UIKit", trailingTrivia: .newlines(2)))
    })
}))

routesSourceFile = routesSourceFile.addCodeBlockItem(CodeBlockItemSyntax({ (builder) in
    let variableDeclSyntax = VariableDeclSyntax { (builder) in
        builder.useLetOrVarKeyword(SyntaxFactory.makeLetKeyword(trailingTrivia: .spaces(1)))
        builder.addPatternBinding(SyntaxFactory.makePatternBinding(
            pattern: IdentifierPatternSyntax({ (builder) in
                builder.useIdentifier(SyntaxFactory.makeIdentifier("routes"))
            }),
            typeAnnotation: SyntaxFactory.makeTypeAnnotation(
                colon: SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)),
                type: SyntaxFactory.makeTypeIdentifier("[String: ([URLQueryItem]) -> UIViewController]", trailingTrivia: .spaces(1))
            ),
            initializer: InitializerClauseSyntax({ (builder) in
                builder.useEqual(SyntaxFactory.makeEqualToken(trailingTrivia: .spaces(1)))
                builder.useValue(SyntaxFactory.makeDictionaryExpr(
                    leftSquare: SyntaxFactory.makeLeftSquareBracketToken(trailingTrivia: .newlines(1)),
                    content: SyntaxFactory.makeDictionaryElementList(routesContentDictionaryElementList),
                    rightSquare: SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: .newlines(1))
                ))
            }),
            accessor: nil,
            trailingComma: nil
            )
        )
    }
    builder.useItem(variableDeclSyntax)
}))


print(routesSourceFile)
let routesSwiftOutputPath = URL(fileURLWithPath: arguments[2]) // $SRCROOT/routerbuilderapp/routerbuilder/routes.swift
try! routesSourceFile.description.write(to: routesSwiftOutputPath, atomically: true, encoding: .utf8)
