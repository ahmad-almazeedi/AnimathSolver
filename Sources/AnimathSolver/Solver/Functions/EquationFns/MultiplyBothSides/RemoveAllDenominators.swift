//
//  RemoveAllDenominators.swift
//  Hulul
//
//  Created by Ahmad on 24/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func removeAllDenominators(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if nodeL.children.isNumberWithX(mayBeDecimal: false, mayBeOneVar: true) && !nodeR.children.hasVarFlat || nodeR.children.isNumberWithX(mayBeDecimal: false, mayBeOneVar: true) && !nodeL.children.hasVarFlat {return}
        if nodeL.children.isSimplestFormNegletTimesBracketForRemoveAllDens && nodeR.children.isSimplestFormNegletTimesBracketForRemoveAllDens {} else {return}
        let allNodes = nodeL.children + nodeR.children
        if allNodes.contains(where: {$0.isFraction}) {} else {return}
        let allNodesNoTimeBrkt = allNodes.dropMultipliedBrackets
        if allNodesNoTimeBrkt.hasOnlyFractions {} else {return}
        if allNodesNoTimeBrkt.contains(where: {!$0.denominator.isSimplestForm}) {return}
        let denominators = allNodesNoTimeBrkt.map({$0.denominator.parent!})
        if denominators.nodesAreEqual {} else {return}
        if denominators.first!.children.count != 1 && allNodesNoTimeBrkt.count > 2 {return}
        if let fractionWithVar = allNodesNoTimeBrkt.first(where: {$0.numerator.hasVar}) {
            if fractionWithVar.numerator.first!.valueKeys == fractionWithVar.denominator.first!.valueKeys {return}
        }
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        // Mark and Explain
        steps.lastMarked = denominators.flatSKs
        steps.lastExplanation = "Multiply both sides by \(denominators.first!.children.flatSKs(.dropOp).strForExpl) to get rid of the fractions"
        steps.lastStrikeKeys = denominators.map({$0.children.count == 1 ? $0.children.first!.strikeKey : $0.strikeKey})
        
        // Set substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Mult both sides
        let multNode = denominators.first!.children.clone(changeID: true, withParent: false).children
        insertMultiplierAtFirstOnBothSides(multNodes: multNode, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // Evaluate Mult
        if nodeL.children.hasFraction(flat: false) {
            reduceFraction(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force, .forceReduce, .skipReduceSameFraction, .skipRemoveOneTimesBrkt], &steps.lastStepSubsteps)
        } else {
            distributeMultiplier(node: nodeL.children[1], fnCtrl: fnCtrl + [.force, .forceDistribute, .skipReduceSameFraction], &steps.lastStepSubsteps)
        }
        if nodeR.children.hasFraction(flat: false) {
            reduceFraction(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force, .forceReduce, .skipReduceSameFraction, .skipRemoveOneTimesBrkt], &steps.lastStepSubsteps)
        } else {
            distributeMultiplier(node: nodeR.children[1], fnCtrl: fnCtrl + [.force, .forceDistribute, .skipReduceSameFraction], &steps.lastStepSubsteps)
        }
        surfAndEvaluateAndApplyFnTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: [.skipDistribute, .skipAddition, .skipReduceToSimplify, .skipCommonFactor, .skipReduceExponentiable, .skipReduceSameFraction, .skipRemoveTimesOne, .skipRemoveOneTimesBrkt], &steps.lastStepSubsteps)
        
        // Append to main steps
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
