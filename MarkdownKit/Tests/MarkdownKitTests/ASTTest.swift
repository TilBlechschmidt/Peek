//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 23.02.21.
//

import XCTest
import MarkdownKit
@testable import MarkdownKit

protocol ASTNode {
    func makeNode() -> Node
}

protocol ASTNodesConvertible {
    func asASTNodes() -> [ASTNode]
}

extension ASTNode {
    func asASTNodes() -> [ASTNode] {
        [self]
    }
}

extension Array: ASTNodesConvertible where Element: ASTNode {
    func asASTNodes() -> [ASTNode] {
        self
    }
}

@_functionBuilder
struct ASTBuilder {
    static func buildBlock(_ children: ASTNodesConvertible...) -> [ASTNode] {
        children.reduce([]) { $0 + $1.asASTNodes() }
    }
}

class ContainerASTNode: ASTNodesConvertible, ASTNode {
    let children: [ASTNode]

    var nodeVariant: NodeVariant {
        preconditionFailure("Should be overwritten by subclass!")
    }

    init(@ASTBuilder builder: () -> [ASTNode]) {
        children = builder()
    }

    func makeNode() -> Node {
        Node(consumedTokens: [], variant: nodeVariant, children: children.map { $0.makeNode() })
    }
}

class VariantBasedContainerASTNode<Variant>: ContainerASTNode {
    typealias V = Variant

    let variant: Variant

    init(variant: Variant, @ASTBuilder builder: () -> [ASTNode]) {
        self.variant = variant
        super.init(builder: builder)
    }
}

class CodeBlock: ContainerASTNode {
    override var nodeVariant: NodeVariant { MarkdownKit.CodeBlock(language: language) }

    let language: String

    init(language: String, @ASTBuilder builder: () -> [ASTNode]) {
        self.language = language
        super.init(builder: builder)
    }
}

class Container: VariantBasedContainerASTNode<MarkdownKit.Container.Variant> {
    override var nodeVariant: NodeVariant { MarkdownKit.Container(variant: variant) }

    // Required overrides due to automatic initializer inheritance being clueless in regards to @ASTBuilder
    override init(variant: V, @ASTBuilder builder: () -> [ASTNode]) {
        super.init(variant: variant, builder: builder)
    }
}

class Heading: ContainerASTNode {
    override var nodeVariant: NodeVariant { MarkdownKit.Heading(level: level) }

    let level: Int

    init(level: Int, @ASTBuilder builder: () -> [ASTNode]) {
        self.level = level
        super.init(builder: builder)
    }
}

class List: VariantBasedContainerASTNode<MarkdownKit.ListItem.Variant> {
    override var nodeVariant: NodeVariant { MarkdownKit.List(variant: variant) }

    // Required overrides due to automatic initializer inheritance being clueless in regards to @ASTBuilder
    override init(variant: V, @ASTBuilder builder: () -> [ASTNode]) {
        super.init(variant: variant, builder: builder)
    }
}

class ListItem: VariantBasedContainerASTNode<MarkdownKit.ListItem.Variant> {
    override var nodeVariant: NodeVariant { MarkdownKit.ListItem(variant: variant) }

    // Required overrides due to automatic initializer inheritance being clueless in regards to @ASTBuilder
    override init(variant: V, @ASTBuilder builder: () -> [ASTNode]) {
        super.init(variant: variant, builder: builder)
    }
}

class Paragraph: ContainerASTNode {
    override var nodeVariant: NodeVariant { MarkdownKit.Paragraph() }

    // Required overrides due to automatic initializer inheritance being clueless in regards to @ASTBuilder
    override init(@ASTBuilder builder: () -> [ASTNode]) {
        super.init(builder: builder)
    }
}

class ThematicBreak: VariantBasedContainerASTNode<MarkdownKit.ThematicBreak.Variant> {
    override var nodeVariant: NodeVariant { MarkdownKit.ThematicBreak(variant: variant) }

    // Required overrides due to automatic initializer inheritance being clueless in regards to @ASTBuilder
    override init(variant: V, @ASTBuilder builder: () -> [ASTNode]) {
        super.init(variant: variant, builder: builder)
    }
}

class CodeSpan: ContainerASTNode {
    override var nodeVariant: NodeVariant { MarkdownKit.CodeSpan() }

    // Required overrides due to automatic initializer inheritance being clueless in regards to @ASTBuilder
    override init(@ASTBuilder builder: () -> [ASTNode]) {
        super.init(builder: builder)
    }
}

class Emphasis: VariantBasedContainerASTNode<MarkdownKit.Emphasis.Variant> {
    override var nodeVariant: NodeVariant { MarkdownKit.Emphasis(variant: variant) }

    // Required overrides due to automatic initializer inheritance being clueless in regards to @ASTBuilder
    override init(variant: V, @ASTBuilder builder: () -> [ASTNode]) {
        super.init(variant: variant, builder: builder)
    }
}

class Text: ASTNodesConvertible, ASTNode {
    let content: Token.Variant

    init(_ tokenVariant: Token.Variant) {
        self.content = tokenVariant
    }

    static func from(_ string: Substring) -> [Text] {
        Lexer().tokenize(string: string).map { Text($0.variant) }
    }

    func makeNode() -> Node {
        Node(consumedTokens: [], variant: MarkdownKit.Text(content: content), children: [])
    }
}

class VerbatimText: Text {
    override func makeNode() -> Node {
        Node(consumedTokens: [], variant: MarkdownKit.VerbatimText(content: content), children: [])
    }
}

func XCTAssertEqual(_ a: NodeVariant, _ b: NodeVariant) {
    XCTAssert(a.isEqual(to: b))
}

// Compares nodes but ignores the .token attribute
func XCTAssertEqual(_ lhs: Node, _ rhs: Node) {
    XCTAssertEqual(lhs.variant, rhs.variant)
    XCTAssertEqual(lhs.children, rhs.children)
}

func XCTAssertEqual(_ lhs: [Node], _ rhs: [Node]) {
    XCTAssertEqual(lhs.count, rhs.count)
    for (lhsChild, rhsChild) in zip(lhs, rhs) {
        XCTAssertEqual(lhsChild, rhsChild)
    }
}

func XCTVerifyAST(input: String, _ astNodes: [ASTNode]) throws {
    let tokens = Lexer().tokenize(string: Substring(input))
    let parsedAST = try Parser().parse(tokens)
    let expectedAST = astNodes.map { $0.makeNode() }

    // Use this for additional debugging (no clue how to make XCTest capture this yet) :)
    print("Parsed AST:")
    for node in parsedAST {
        debugPrint(node)
    }
    print("Expected AST:")
    for node in expectedAST {
        debugPrint(node)
    }

    XCTAssertEqual(parsedAST, expectedAST)
}

func XCTVerifyAST(input: String, @ASTBuilder builder: () -> [ASTNode]) throws {
    try XCTVerifyAST(input: input, builder())
}
