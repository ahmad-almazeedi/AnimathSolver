//
//  MoveCoeff.swift
//  Hulul
//
//  Created by Ahmad on 17/01/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func moveCoeff(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditiond
        if fnCtrl.isCheckAllowed && nodeL.children.first!.isCommaNode {return}
        var allNodes: [StepNode] {nodeL.children + nodeR.children}
        if allNodes.allSymbs.shouldMoveAllToSide {return}
        if nodeL.children.isSimplestFormNegletTimesBracket {} else {return}
        if nodeL.children.isNumberWithX(mayBeDecimal: true, mayBeOneVar: false) || nodeL.children.count == 2 && nodeL.children.contains(where: {$0.isNumber(mayBePowered: false) && !$0.isOne && ($0.hasVar || $0.multiplierBrkt != nil && $0.multiplierBrkt!.isPowered && $0.multiplierBrkt!.children.hasVar)}) && nodeL.children.hasBrackets(.simplest) {} else {return}
        if nodeR.children.isSimplestForm {} else {return}
        if nodeL.children.hasBrackets(.any) && distributeAllowed(node: nodeL.children.first(where: {$0.isBrackets(.any)})!, fnCtrl: fnCtrl) && !nodeR.children.isFraction {return}
        if fractionAdditionAllowed(node: nodeR.children.first!, fnCtrl: fnCtrl) {return}
        if nodeR.hasVar && !(nodeL.children.hasDirectRadVar && noFractionsAfterMoveCoeff(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl)) {return}
//        if nodeR.children.isMulti && nodeR.children.hasFraction(flat: false) && allNodes.getGCD != nil {return}
        if nodeL.children.isMinus && nodeR.children.isMinus && allNodes.count == 2 {return}
        let isVarwithBrktCoeff = nodeL.children.hasBrackets(.any) && nodeL.children.contains(where: {$0.isOneSingleVar(mayBeInSqrt: true)})
        if isVarwithBrktCoeff && nodeL.children.first(where: {$0.isBrackets})!.hasVarFlat {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}

        // Extract Coeff
        let tmpCoeffNode = isVarwithBrktCoeff ? nodeL.children.first(where: {$0.isBrackets(.any)})! : nodeL.children.first(where: {!$0.isBrackets(.any)})!
        tmpCoeffNode.changeStaticIDWithChildren()
        let CoeffNode = tmpCoeffNode.clone(changeID: false, withParent: false).withOp(isVarwithBrktCoeff ? .plus : tmpCoeffNode.op)
        if !isVarwithBrktCoeff {
            CoeffNode.removeVar()
        }
        if CoeffNode.isMinus && nodeR.children.isFraction {CoeffNode.flipSign()}
        
        // Mark and append
        steps.lastMarked = CoeffNode.flatSKs(.dropPlus)
        steps.lastExplanation = "Divide both sides by \(steps.lastMarked.filter({!$0.key.isParenthesis}).strForExpl)"

        // Init SubSteps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastMarked = nodeL.rootStepExpr + nodeR.rootStepExpr
        
        // Divide both sides
        appendHighOpOnBothSides(opNodes: [CoeffNode], highOp: .divide, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // Evaluate Division
        if nodeL.children.last!.isBrackets(.notSingle(mayBeFraction: false)) || isVarwithBrktCoeff {
            determineChainSign(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            convertDivisionToFraction(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            determineChainSign(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            reduceFraction(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force, .forceReduce], &steps.lastStepSubsteps)
        } else {
            determineChainSign(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            cancelDividerWithMultiplier(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            convertDivisionToFraction(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            determineChainSign(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            reduceFraction(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force, .forceReduce], &steps.lastStepSubsteps)
            removeHighOpOne(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        }
        if CoeffNode.isMinus && nodeR.children.first!.isFraction {
            steps.setToUnableToSolve(nodeL: nodeL.root, nodeR: nodeR.otherSide)
            return
        }
        if !nodeR.children.first!.isBrackets(.hasFraction(fractionCase: .any)) {
            convertDivisionToFraction(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force, .skipDivToFracIfDividedHasFraction], &steps.lastStepSubsteps)
            convertDivisionToFraction(node: nodeR.children.last!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            determineChainSign(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            mergeWithFraction(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force, .forceMerge], &steps.lastStepSubsteps)
        }
        
        // change ID to animate
        nodeR.children.matchIDsOfSameStaticID(with: [CoeffNode], markedKeys: &steps.lastMarked, inStepsView: false)
        if CoeffNode.isMinus && nodeR.children.isMinus {
            nodeR.children.op = CoeffNode.op
        }
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Distribute divider
        if nodeR.children.last!.isDivide {
            distributeDivider(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force], &steps)
        } else if nodeR.children.isFraction {
            let fractionNode = nodeR.children.first!
            determineChainSign(node: fractionNode, fnCtrl: fnCtrl + [.force], &steps)
            reduceFraction(node: fractionNode, fnCtrl: fnCtrl + [.force], &steps)
            convertDecimalsInFraction(node: fractionNode, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}

extension CalcBrain {
    func moveCoeffAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeLClone = nodeL.clone(changeID: false, withParent: true)
        let nodeRClone = nodeR.clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        moveCoeff(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func noFractionsAfterMoveCoeff(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if fnCtrl.contains(.noFractionAfterMoveCoeffTrue) {return true}
        else if fnCtrl.contains(.noFractionAfterMoveCoeffFalse) {return false}
        let nodeLClone = nodeL.clone(changeID: false, withParent: true)
        let nodeRClone = nodeR.clone(changeID: false, withParent: true)
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        moveCoeff(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: [.skipPrintStep, .noFractionAfterMoveCoeffTrue], &tmpSteps)
        surfAndEvaluateAndApplyFnTillEnd(parent: nodeRClone, fnCtrl: [.skipPrintStep, .noFractionAfterMoveCoeffTrue], &tmpSteps)
        return !nodeRClone.children.hasFraction(flat: true)
    }
}
