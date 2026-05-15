//
//  RemoveAllDen.swift
//  Hulul
//
//  Created by Ahmad on 01/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    
    private func isMultBothSidesToRemoveDenominatorOtherIsZero(nodeL: StepNode, nodeR: StepNode) -> Bool {
        if nodeL.children.isZero && !nodeR.children.isZero || !nodeL.children.isZero && nodeR.children.isZero {} else {return false}
        let mainNode = nodeR.children.isZero ? nodeL : nodeR
        if mainNode.children.isFraction(part: .denominator, {!$0.hasFraction(flat: true) && $0.isSimplestForm}) {} else {return false}
        return true
    }
    
    func multBothSidesToRemoveDenominatorOtherIsZero(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !isMultBothSidesToRemoveDenominatorOtherIsZero(nodeL: nodeL, nodeR: nodeR) {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}

        // Init
        var mainNode = nodeR.children.isZero ? nodeL : nodeR
        
        //
        if mainNode.children.isMinus {
            flipsSignsIfNegX(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.forceFlipSigns], &steps)
        }
        
        //
        mainNode = nodeR.children.isZero ? nodeL : nodeR
        let otherNode = nodeR.children.isZero ? nodeR : nodeL
        let fractionNode = mainNode.children.first!

        // Mark and explain and strike
        steps.lastMarked = fractionNode.denominator.flatSKs(.dropPlus)
        let denTitle = fractionNode.denominator.count == 1 ? steps.lastMarked.strForExpl : "(\(steps.lastMarked.strForExpl))"
        steps.lastExplanation = "Since the other side is 0, remove \(denTitle) by multiplying it on both sides"
        steps.lastStrikeKeys = [fractionNode.denominator.count == 1 ? fractionNode.denominator.first!.baseOrTermNode.strikeKey : fractionNode.denominator.parent!.strikeKey]

        // Substeps
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastMarked.removeAll()

        // Action Part
        let multNodes = fractionNode.denominator
        appendHighOpOnBothSides(opNodes: multNodes, highOp: .times, nodeL: mainNode.root, nodeR: otherNode.root, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        cancelEqualExprsDenAndMult(node: fractionNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        removeTimesOrDividedZero(node: otherNode.children.first!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // Appen to main steps
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    private func cancelEqualExprsDenAndMult(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Mark, Explain, and Strike
        let level = node.level!
        steps.lastMarked = node.denominator.flatSKs(.dropPlus) + level.last!.flatSKs(.dropOp)
        let commonFactorStr = node.denominator.flatSKs(.dropPlus).strForExpl
        steps.lastExplanation = "Cancel out \(commonFactorStr) and \(commonFactorStr)"

        steps.lastStrikeKeys = [node.children.last!.strikeKeyWithSymb, level.last!.strikeKeyWithSymb]
        
        // remove
        let numerator = node.numerator
        node.insertBefore(contentsOf: numerator)
        level.last!.remove()
        node.remove()
        
        // Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

