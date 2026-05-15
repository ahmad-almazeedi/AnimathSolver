//
//  Expression.swift
//  Animath
//
//  Created by Ahmad on 09/09/2024.
//

import Foundation

struct Expression: Identifiable {
    var id = Int32.random
    var nodeL = StepNode()
    var nodeR = StepNode(valueKeys: [.typedEqual])
    var nodes = [LatexNode]()

    //
    static func withEmptyBox(withID id: Int32 = Int32.random) -> Expression {
        var expr = Expression()
        expr.nodes = [.emptyBox().withID(id)]
        return expr
    }

    //
    mutating func reset(preserveID: Bool = false) {
        if !preserveID {
            id = Int32.random
        }
        nodeL = StepNode()
        nodeR = StepNode(valueKeys: [.typedEqual])
        nodes = [LatexNode]()
    }
}

extension Expression {
    func flatSKs(dropEqual: Bool, opCase: StepNode.OpPrintCase = .any) -> [StepKey] {
        nodeL.children.flatSKs(opCase)+(nodeL.isEquation ? ((dropEqual ? [] : nodeR.valueSK) + (nodeR.children.flatSKs(opCase))) : [])
    }
    var flatSKsForAI: [StepKey] {
        nodeL.children.flatSKs(.dropPlusNotPlusMinus)+(nodeL.isEquation ? (nodeR.valueSK + (nodeR.children.flatSKs(.dropPlusNotPlusMinus))) : [])
    }
    var AIStr: String {
        if nodes.isEmpty {
            return flatSKsForAI.strForExpl
        } 
        return nodes.explStr().dropBoxes
    }
    var finetuningStr: String {
        AIStr.enumerated().map { index, char in
            if char.isOp {
                if index == 0 {
                    return "\(char)"
                } else if AIStr[AIStr.index(AIStr.startIndex, offsetBy: index - 1)].isOp {
                    return " \(char)"
                } else {
                    return " \(char) "
                }
            } else {
                return "\(char)"
            }
        }
        .joined(separator: "")
        .regulerXs
        .replacingOccurrences(of: "×", with: "*")
        .replacingOccurrences(of: "−", with: "-")
        .replacingOccurrences(of: "  ", with: " ")
    }
    var isDisequation: Bool {
        flatSKs(dropEqual: false).keys.contains(.notEqual)
    }
    func isFirst(in equations: [Expression]) -> Bool {
        id == equations.first?.id
    }
    func idx(in equations: [Expression]) -> Int? {
        equations.firstIndex(where: {$0.id == self.id})
    }
    var containsArabic: Bool {
        nodes.containsArabic
    }
    var nodesAreEmpty: Bool {
        nodeL.isEmpty && nodes.isEmptyOrBox
    }
}

extension Array where Element == Expression {
    var nodeL: StepNode {
        get {
            return first!.nodeL
        }
        set {
            self[0].nodeL = newValue
        }
    }
    var nodeR: StepNode {
        get {
            return first!.nodeR
        }
        set {
            self[0].nodeR = newValue
        }
    }
    var allNodes: [StepNode] {
        nodeL.children+nodeR.children
    }
    func flatSKs(dropComma: Bool = false, dropEqual: Bool, opCase: StepNode.OpPrintCase = .any) -> [StepKey] {
        var tmpWholeExpr = [StepKey]()
        for equation in self {
            tmpWholeExpr.append(contentsOf: equation.flatSKs(dropEqual: dropEqual, opCase: opCase) + (dropComma ? [] : [.comma]))
        }
        if !dropComma {
            tmpWholeExpr.removeLast()
        }
        return tmpWholeExpr
    }
    var flatSKsMatrix: [[StepKey]] {
        var tmpWholeExpr = [[StepKey]]()
        for equation in self {
            tmpWholeExpr.append(equation.flatSKs(dropEqual: false, opCase: .dropPlus))
        }
        return tmpWholeExpr
    }
    var AIStr: String {
        map({$0.AIStr}).joined(separator: ", ")
    }
    var latexStr: String? {
        if contains(where: {$0.nodes.latexStr == nil}) {return nil}
        return map({$0.nodes.latexStr!}).joined(separator: ", ")
    }
    var latexOrAIStr: String {
        latexStr ?? AIStr
    }
    var finetuningStrs: [String] {
        map({$0.finetuningStr})
    }
    var isEmptyOrNodesEmpty: Bool {
        isEmpty || allSatisfy({$0.nodesAreEmpty}) // CHECK: used to be this: 'isEmpty || allSatisfy({$0.nodeL.isEmpty && $0.nodes.isEmpty})' changed it without testing
    }
    func setToBeHiddenOpIDsToZero() {
        for expr in self {
            expr.nodeL.setToBeHiddenOpIDsToZero()
            expr.nodeR.setToBeHiddenOpIDsToZero()
        }
    }

    var containsArabic: Bool {
        contains { $0.containsArabic }
    }
    
    var equationsLengthForStepNodes: Double {
        map({$0.nodeL.childrenExprCharsWidth + ($0.nodeL.isEquation ? (1.25 + $0.nodeR.childrenExprCharsWidth) : 0)}).reduce(0, +) + Double(count-1)*1.9
    }
}
