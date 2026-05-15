//
//  FirstEngineNoSteps.swift
//  Hulul
//
//  Created by Ahmad on 20/12/2020.
//  Copyright © 2020 Ahmad. All rights reserved.
//


extension CalcBrain {
    func firstEngineNoSteps(nodeL: StepNode, nodeR: StepNode) {
        addMissingBrackets(nodeL: nodeL, nodeR: nodeR)
        parenthesizeAttachedMinusNoSteps(nodeL: nodeL, nodeR: nodeR)
        removeExtras(nodeL: nodeL, nodeR: nodeR)
        if nodeL.resultCase == .unableToSolve {return}
        removeRedundantBracketsNoSteps(nodeL: nodeL, nodeR: nodeR)
        removeWholeExprExternalBracketsNoSteps(nodeL: nodeL, nodeR: nodeR)
        removeTimesFromTermsFromOutNoStep(nodeL: nodeL, nodeR: nodeR)
    }
}
extension CalcBrain {
     func removeExtras(nodeL: StepNode, nodeR: StepNode) {
        if nodeR.children.isSemiEmpty || nodeR.children.flatKeys == [.minus] {
            nodeR.children = []
        }
        repeat {
            nodeL.pinRootExpr()
            nodeR.pinRootExpr()
            for node in nodeL.flatTree + nodeR.flatTree {
                if !node.exist && !node.op.key.isPowOrSqrt {continue}
                if node.isFraction(.empty(for: .all)) {
                    if node.isLast && !(!nodeR.isEmpty && node.parent!.id == nodeL.id) {
                        node.remove()
                    } else {
                        nodeL.isIncomplete = true
                        nodeR.isIncomplete = true
                        return
                    }
                } else if node.isFraction(.empty(for: .any)) {
                    if node.denominator.isEmptyOrSemiEmpty {
                        node.removeDenominator()
                    } else {
                        nodeL.isIncomplete = true
                        nodeR.isIncomplete = true
                        return
                    }
                } else if node.op.key == .pow && (node.children.isSemiEmpty || node.children.isEmpty) {
                    node.parent!.powerParent = nil
                } else if node.op.key == .pow && node.parent!.isEmptyOrSemiEmpty {
                    nodeL.isIncomplete = true
                    nodeR.isIncomplete = true
                    return
                } else if node.op.key == .pow && !(node.children.isFilledWithEmpties || node.children.hasVarOrIFlat) && node.children.resultValue() > 999 {
                    nodeL.resultCase = .unableToSolve
                    nodeR.resultCase = .unableToSolve
                    return
                } else if node.op.key == .sqrt && (node.children.isFilledWithEmpties || node.indexSK.isEmpty || node.indexSK.first!.key.isOpenCurlyBrkt) {
                    nodeL.isIncomplete = true
                    nodeR.isIncomplete = true
                    if node.baseNode.isOneSingleRadical {
                        node.baseNode.remove()
                    } else {
                        node.remove()
                    }
                } else if !node.op.key.isPowOrSqrt && !node.isLast && node.valueSK.isEmpty {
                    nodeL.isIncomplete = true
                    nodeR.isIncomplete = true
                    return
               } else if node.valueKeys == [.minus] {
                   if node.isLast {
                       node.remove()
                   } else {
                       nodeL.isIncomplete = true
                       nodeR.isIncomplete = true
                       return
                   }
               } else if !node.isSymb && node.isTimesOrDivide && node.isFirst {
                    nodeL.isIncomplete = true
                    nodeR.isIncomplete = true
                    return
               } else if node.valueSK.isEmpty || node.valueKeys == [.minus] || node.valueSK.contains(where: {$0.key.isOpenBracket}) && (node.children.isSemiEmpty || node.children.isEmpty) {
                    node.remove()
                } else if node.valueKeys.last! == .dot {
                    node.valueSK.removeLast()
                } else if !node.isSqrt && node.valueKeys.first! == .dot {
                    node.valueSK.insert(.zero, at: 0)
                } else if !node.isSqrt && node.valueKeys.contains(.dot) && node.valueKeys.split(separator: .dot).last!.last!.isZero {
                    while node.valueKeys.contains(.dot) && node.valueKeys.split(separator: .dot).last!.last!.isZero {
                        node.valueSK.removeLast()
                    }
                    if node.valueKeys.last! == .dot {
                        node.valueSK.removeLast()
                    }
                } else if node.valueKeys.first!.isZero && node.valueSK.count > 1 && node.valueKeys[1] != .dot {
                    while node.valueKeys.first!.isZero && node.valueSK.count > 1 && node.valueKeys[1] != .dot {
                        node.valueSK.removeFirst()
                    }
                }
            }
        } while nodeL.pinnedRootDidChange || nodeR.pinnedRootDidChange
    }
    
    private func addMissingBrackets(nodeL: StepNode, nodeR: StepNode) {
        for node in nodeL.flatTree + nodeR.flatTree {
            if node.hasParent && node.parent!.isBrackets(.openNotEmpty) && !node.parent!.valueSK.first!.isHiddenBracket {
                node.parent!.valueKeys.append(.closeBracket)
            }
        }
    }
    
    private func removeRedundantBracketsNoSteps(nodeL: StepNode, nodeR: StepNode) {
        for node in nodeL.flatTree + nodeR.flatTree {
            if !node.isSqrt && node.isBrackets(.complete) && !node.valueSK.first!.isHiddenBracket && !node.isPowered && node.children.isBrackets(.complete) && !node.children.first!.valueSK.first!.isHiddenBracket && !node.children.first!.isPowered && node.children.isPlus {
                node.children.op = node.op
                node.insertBefore(node.children.first!)
                node.remove()
            }
        }
    }
    
    private func removeWholeExprExternalBracketsNoSteps(nodeL: StepNode, nodeR: StepNode) {
        if nodeL.children.isBrackets(.complete) && nodeL.children.isPlus && !nodeL.children.first!.isPowered {
            nodeL.children.first!.justRemoveBrackets()
        }
        if nodeR.children.isBrackets(.complete) && nodeR.children.isPlus && !nodeR.children.first!.isPowered {
            nodeR.children.first!.justRemoveBrackets()
        }
    }
    
    private func parenthesizeAttachedMinusNoSteps(nodeL: StepNode, nodeR: StepNode) {
        for node in nodeL.flatTree + nodeR.flatTree {
            if !node.valueSK.isEmpty && node.valueKeys.first!.isMinus {
                let newBracketsNode = StepNode.newBracketsNode
                newBracketsNode.op = node.op
                newBracketsNode.children = [StepNode(op: node.valueSK.first!, valueSK: [StepKey](node.valueSK.dropFirst()))]
                if node.isPowered {
                    newBracketsNode.children.first!.power = node.power
                }
                newBracketsNode.children.first!.radicalParent = node.radicalParent
                if node.hasDirectSymbs {
                    newBracketsNode.children.first!.directSymbs = node.directSymbs
                } else if node.hasChild {
                    newBracketsNode.children.first!.children = node.children
                }
                node.insertBefore(newBracketsNode)
                node.remove()
            }
        }
    }
}
