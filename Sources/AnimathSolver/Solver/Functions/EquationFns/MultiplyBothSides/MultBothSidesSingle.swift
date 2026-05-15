//
//  MultBothSidesSingle.swift
//  Hulul
//
//  Created by Ahmad on 01/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func multBothSidesSinglebyLCM(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        // Conditions
        if fnCtrl.isCheckAllowed && nodeL.children.first!.isCommaNode {return}
        if isMultBothSidesCommonConditions(nodeL: nodeL, nodeR: nodeR) {} else {return}
        let allNodes = nodeL.children + nodeR.children
        guard let fractionNode = allNodes.dropMultipliedBrackets.sorted(by: {$0.allSymbs.filter({$0.isVar}).count > $1.allSymbs.filter({$0.isVar}).count}).first(where: {$0.isFraction}) else {return}
        if fractionNode.denominator.hasOnlyNumbers && !(!fnCtrl.isForced && fractionNode.denominator.hasDecimal) {} else {return}
        let mainSide = fractionNode.isLeft ? nodeL : nodeR
        let otherSide = fractionNode.isLeft ? nodeR : nodeL
        guard fractionNode.level!.dropMultipliedBrackets.count == 1 else {return}
        if otherSide.children.isSimplestFormNegletTimesBracket {} else {return}
        if mainSide.children.hasBrackets(.any) && otherSide.children.hasBrackets(.any) {return}
        if !mainSide.hasVarFlat && otherSide.hasVarFlat || otherSide.children.hasFraction(flat: true) && (mainSide.children.hasBrackets(.any) || mainSide.hasVarFlat && otherSide.hasVarFlat) {return} // consider: 15(5x+3)=4/3
        if otherSide.children.contains(where: {$0.isFraction && $0.isMultipliedByBracketsOnly}) {return}
        if isReducible(node: fractionNode, fnCtrl: fnCtrl) {return}
        if (nodeL.children.isMinus || nodeL.children.hasFraction(.hasSingleNegative)) && (nodeR.children.isMinus || nodeR.children.hasFraction(.hasSingleNegative)) {return}
        if divideBothSidesAllowedExceptMoveCoeff(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.divBothForHighDegOrNoBrkt]) {return}
//        if !allNodes.hasVarFlat && [fractionNode].resultValue().count <= 5 {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}

        // Set
        let otherSideIsMulti = otherSide.children.count > 1 || otherSide.children.first!.isFraction && otherSide.children.first!.numerator.count > 1
        let multNode = fractionNode.denominator.clone(changeID: false, withParent: false).children
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Mark and explain
        steps.lastMarked = multNode.flatSKs
        steps.lastExplanation = "Multiply both sides by \(multNode.flatSKs(.onlyMinus).strForExpl)"
        
        // Append Multipliers
        var didInsert = false
        if multNode.count == 1 && !mainSide.children.isMinus && !otherSide.children.isMinus && (otherSideIsMulti || otherSide.children.first!.isOneTerm || multNode.isMinus)  {
            insertMultiplierAtFirstOnBothSides(multNodes: multNode, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            didInsert = true
        } else {
            appendHighOpOnBothSides(opNodes: multNode, highOp: .times, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            if multNode.isMulti {
                steps.lastMarked.append(contentsOf: steps.lastStepSubsteps[steps.lastStepSubsteps.count-2].markedKeys)
            }
        }
        
        // Reduce main side
        determineChainSign(node: mainSide.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        reduceFraction(node: mainSide.children.first!, fnCtrl: fnCtrl + [.force, .forceReduce, .skipRemoveOneTimesBrkt], &steps.lastStepSubsteps)
        
        // Merge fraction with multiplier on the other side if fraction
        if !didInsert && willHaveFractionAfterReduce(node: otherSide.children.first!, fnCtrl: fnCtrl) {
            mergeWithFraction(node: otherSide.children.first!, fnCtrl: fnCtrl + [.force, .forceMerge], &steps.lastStepSubsteps)
        }
        removeOneTerm(node: otherSide.children.first!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // Set multNode from the other side
        otherSide.children.matchIDsOfSameStaticID(with: multNode, markedKeys: &steps.lastMarked, inStepsView: false)
        
        // Append main step
        appendStep(&steps, fnCtrl: fnCtrl)

        //
        var otherSideFirst: StepNode {otherSide.children.first!}
        if isReducible(node: otherSideFirst, fnCtrl: fnCtrl + [.force]) {return}
        if otherSide.children.directRadicals.count > 1 {return}
        evaluateMult(node: otherSideFirst.isFraction ? otherSideFirst.numerator.first! : otherSideFirst, fnCtrl: fnCtrl + [.force], &steps)
    }
}

extension CalcBrain {
    func willHaveWholeNumberAfterMultSingleLCM(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeLClone = nodeL.clone(changeID: false, withParent: true)
        let nodeRClone = nodeR.clone(changeID: false, withParent: true)
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        multBothSidesSinglebyLCM(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep], &tmpSteps)
        surfAndApplyFnBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep], surfFnCases: .reduce, &tmpSteps)
        return !nodeLClone.children.isFraction && !nodeRClone.children.isFraction && nodeLClone.children.isSimplestForm && nodeRClone.children.isSimplestForm
    }
}
