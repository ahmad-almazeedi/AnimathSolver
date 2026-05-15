//
//  LatexNode.swift
//  AnimathSolver
//
//  Minimal stub for the LaTeX rendering type. The original iOS app
//  uses LatexNode for OCR/preview features; the solver itself does
//  not depend on its contents. This stub keeps `Expression.nodes`
//  compilable without dragging the renderer into the core package.
//
//  If you want a real LaTeX rendering pipeline, replace this file.
//

import Foundation

struct LatexNode {
    var id: Int32 = Int32.random
    var content: String = ""

    static func emptyBox() -> LatexNode {
        LatexNode()
    }

    func withID(_ id: Int32) -> LatexNode {
        var n = self
        n.id = id
        return n
    }
}

extension Array where Element == LatexNode {
    var isEmptyOrBox: Bool { isEmpty || allSatisfy { $0.content.isEmpty } }
    var containsArabic: Bool { false }
    var latexStr: String? { isEmpty ? nil : map(\.content).joined() }

    func explStr() -> String { map(\.content).joined() }
    var nestedFractionCountForLatex: Double { 0 }
}

extension Array where Element == Expression {
    var nestedFractionCountForLatex: Double { 0 }
}

extension String {
    var dropBoxes: String { self }
}
