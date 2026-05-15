//
//  FlipSignsIfNegX.swift
//  Hulul
//
//  Created by Ahmad on 03/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func flipsSignsIfNegX(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        let allNodes = nodeL.children + nodeR.children
        let mainNode = nodeL.children.hasVar || !allNodes.hasVarFlat ? nodeL : nodeR
        let otherNode = mainNode.isLeft ? nodeR : nodeL
        var shouldMoveAllToSide: Bool {allNodes.allSymbs.shouldMoveAllToSide}
        if shouldMoveAllToSide && !fnCtrl.contains(.forceFlipSigns) {
            if nodeR.children.isZero {} else {return}
            if nodeL.children.isSimplestForm {} else {return}
            if nodeL.children.getGCD == nil {} else {return}
            if nodeL.children.areDegreeOrdered {} else {return}
            if nodeL.children.first!.isMinus {} else {return}
        } else if !fnCtrl.contains(.forceFlipSigns) {
            if nodeL.children.isMinus && powerBothSidesAllowedDroppedMinus(nodeL: nodeL, nodeR: nodeR, dynamicSwap: true, fnCtrl: fnCtrl + [.noFractionAfterMoveCoeffFalse]) {}
            else {
                if nodeL.children.hasVar && nodeR.children.hasVar && !(nodeR.children.isFraction) {return}
                if nodeL.children.isSimplestFormNegletTimesBracket && nodeR.children.isSimplestFormNegletTimesBracket {} else {return}
                if nodeL.children.isMinus && nodeR.children.isMinus && allNodes.count == 2 {} else {
                    if mainNode.children.count == 1 && !mainNode.children.first!.isBrackets(.any) && mainNode.children.isSimplestForm && mainNode.children.hasVar && mainNode.children.isMinus && (mainNode.isLeft || xMultAllowed(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl)) {} else {return}
                    if mainNode.children.first!.isNumber(mayBePowered: false) && !mainNode.children.first!.isOneSingleVar(mayBeInSqrt: true) && otherNode.children.hasOnlyNumbers {return}
                    if mainNode.children.isSinglePosFractionWithX && otherNode.children.isSinglePosFractionOrNumber || otherNode.children.isSinglePosFractionWithX && mainNode.children.isSinglePosFractionOrNumber {return}
                }
            }
        }
        
        // mark and explain
        let originalLowOps = allNodes.flatSKs.getOps.dropHighOps
        steps.lastMarked = allNodes.getOps.filter({!$0.key.isHighOp})
        let oneSideIsZero = nodeL.children.isZero || nodeR.children.isZero
        let useStrikeThrough = allNodes.count == 2 && (oneSideIsZero || nodeR.children.isMinus)
        steps.lastExplanation = "Multiply both sides by -1" + (useStrikeThrough ? " to cancel the negative sign\(oneSideIsZero ? "" : "s")" : "")
        steps.lastStrikeKeys = useStrikeThrough ? [nodeL.children.op.strikeKey, nodeR.children.op.strikeKey] : []
        let negativeKey = mainNode.children.op
        
        // init substeps
        steps.lastStepSubsteps = [steps.last!]
        
        // append -1 both sides
        insertMultiplierAtFirstOnBothSides(multNodes: [StepNode.newOneNode.withOp(.minus)], nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // Evaluate
        if shouldMoveAllToSide {
            removeHighOpOne(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            removeNegativeBrackets(node: nodeL.children.last!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            removeTimesOrDividedZero(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        } else {
            surfAndEvaluateAndApplyFnTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.skipRemoveTimesOne], &steps.lastStepSubsteps)
        }
        
        // Change (-) ID
        if otherNode.children.isMinus && otherNode.children.count == 1 {
            otherNode.children.first!.op = negativeKey
        }
        
        // next mark and append step
        steps.lastMarked.append(contentsOf: (mainNode.children+otherNode.children).getOps.dropHighOps.filter({!originalLowOps.contains($0)}))
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
