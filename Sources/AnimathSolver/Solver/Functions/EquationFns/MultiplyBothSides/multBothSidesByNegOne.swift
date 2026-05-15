//
//  multBothSidesByNegOne.swift
//  Hulul
//
//  Created by Ahmad on 09/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func isMultBothSidesByNegativeOne(mainSide: StepNode, otherSide: StepNode) -> Bool {
        if mainSide.children.hasVar && !otherSide.children.hasVar {} else {return false}
        if mainSide.children.count == 1 && otherSide.children.count == 1 {} else {return false}
        if mainSide.children.isBrackets(.simplest) && mainSide.children.isBrackets(.notSingle(mayBeFraction: true)) {} else {return false}
        if mainSide.children.isMinus && !mainSide.children.first!.children.contains(where: {$0.symbIsVar && $0.isMinus}) {} else {return false}
        return true
    }

    func multBothSidesByNegativeOneForBrkt(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if fnCtrl.isCheckAllowed && nodeL.children.first!.isCommaNode {return}
        if nodeL.children.hasVar && !nodeR.children.hasVar || nodeR.children.hasVar && !nodeL.children.hasVar {} else {return}
        let mainSide = nodeL.children.hasVar ? nodeL : nodeR
        let otherSide = nodeL.children.hasVar ? nodeR : nodeL
        if isMultBothSidesByNegativeOne(mainSide: mainSide, otherSide: otherSide) {} else {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}

        // Set
        let node = mainSide.children.first!
        let otherSideIsZero = otherSide.children.isZero
        var otherSideIsMinusOrZero: Bool {otherSide.children.isMinus || otherSideIsZero}
        
        // Mark and explain and potential strikethrough
        steps.lastMarked = [node.op]
        steps.lastExplanation = "Multiply both sides by -1"
        if otherSideIsMinusOrZero {
            steps.lastMarked.append(otherSide.children.op)
            steps.lastStrikeKeys = [nodeL.children.op.strikeKey, nodeR.children.op.strikeKey]
            steps.lastExplanation += " to cancel the negative sign\(otherSideIsZero ? "" : "s")"
        }
        
        // Init sub steps
        steps.lastStepSubsteps = [steps.last!]

        // Append -1 on both sides
        appendHighOpOnBothSides(opNodes: [.newOneNode.withOp(.minus)], highOp: .times, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
       
        // Evaluate LHS
        determineChainSign(node: node, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        removeHighOpOne(node: node.level!.last!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        removeBrackets(node: node, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        
        // Evaluate RHS
        removeTimesOrDividedZero(node: otherSide.children.first!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        determineChainSign(node: otherSide.children.first!, fnCtrl: fnCtrl + [.force] + (otherSideIsZero ? [] : [.forceMoveMinusOut]), &steps.lastStepSubsteps)
        removeHighOpOne(node: otherSide.children.last!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        evaluateMult(node: otherSide.children.first!, fnCtrl: fnCtrl + [.force, .skipSymbMultOrOrder], &steps.lastStepSubsteps)

        // Change rhs rign ID if appropriate
        if otherSideIsMinusOrZero && !otherSideIsZero {
            otherSide.children.op = steps.lastMarked.first!
        }
        
        // append main step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
