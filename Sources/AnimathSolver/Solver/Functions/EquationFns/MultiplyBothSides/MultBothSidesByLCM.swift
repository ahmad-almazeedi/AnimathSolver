//
//  MultBothSidesByLCM.swift
//  Hulul
//
//  Created by Ahmad on 16/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func multBothSidesbyLCM(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if fnCtrl.isCheckAllowed && nodeL.children.first!.isCommaNode {return}
        if nodeL.children.isNumberWithX(mayBeDecimal: false, mayBeOneVar: true) && !nodeR.children.hasVarFlat || nodeR.children.isNumberWithX(mayBeDecimal: false, mayBeOneVar: true) && !nodeL.children.hasVarFlat {return}
        let allNodes = nodeL.children+nodeR.children
        if allNodes.contains(where: {$0.isFraction}) {} else {return}
        if allNodes.hasFraction(.notSingle(for: .denominator)) {return}
        if allNodes.hasBrackets({$0.hasFraction(part: .any, {$0.hasVarFlat})}) {return}
        if allNodes.allSymbs.shouldMoveAllToSide && nodeL.children.isSimplestForm && nodeR.children.isZero {}
        else {
            if allNodes.contains(where: {fraction1 in fraction1.isFraction && fraction1.hasVar && !fraction1.otherSide.children.allSymbsFlat.contains(where: {otherSideSymb in fraction1.allSymbsFlat.filter({$0.isVar}).contains(where: {$0.type?.key == otherSideSymb.type?.key})}) && allNodes.dropNode(node: fraction1).dropBrackets.filter({$0.hasCommonTerm(with: fraction1)}).contains(where: {fraction2 in
                if fraction2.isFraction && [fraction1,fraction2].denominatorsParents.nodesAreEqual {
                    return !allNodes.dropBrackets.dropNodes(nodes: [fraction1, fraction2]).contains(where: {$0.hasCommonTerm(with: fraction1) && (!$0.isFraction || ![fraction1,$0].denominatorsParents.nodesAreEqual)})
                } else {return false}
            })}) {return}
            if let fractionNode = allNodes.first(where: {$0.isFraction && $0.isMultipliedByBracketsOnly && !$0.multiplierBrkt!.children.hasFraction(flat: true)}) {
                if allNodes.isSimplestFormNegletTimesBracketAndVarFractionAddition {} else {return}
                if isReducible(node: fractionNode, fnCtrl: fnCtrl) {return}
            } else if let fractionWithVar = allNodes.first(where: {$0.isFraction(.hasVar(for: .numerator))}) {
                if fractionWithVar.numerator.count > 1 || allNodes.dropNode(node: fractionWithVar).dropBrackets.contains(where: {$0.hasVarFlat || $0.isFraction}) {} else {return}
                if nodeL.children.isSimplestFormNegletTimesBracketAndVarFractionAddition && nodeR.children.isSimplestFormNegletTimesBracketAndVarFractionAddition {} else {return}
            } else if let fractionWithVarInDen = allNodes.first(where: {$0.isFraction(.hasVar(for: .denominator))}) {
                if allNodes.dropNode(node: fractionWithVarInDen).hasVarFlat {} else {return}
            } else {return}
            if nodeL.children.isSimplestFormNegletTimesBracketAndVarFractionAddition && nodeR.children.isSimplestFormNegletTimesBracketAndVarFractionAddition {} else {return}
            if allNodes.onlyFractions.numeratorsParents.allSatisfy({$0.children.count == 1}) && allNodes.numeratorChain.nodesHaveEqualBase && !allNodes.numeratorChain.first!.valueIsOne {return}
        }
        let allNodesDropMultBrkt = allNodes.dropMultipliedBrackets
        let denChain = allNodesDropMultBrkt.denominatorChain
        if denChain.hasDecimal {return}
        if denChain.hasDirectRadical {
            if denChain.getCommonRadical != nil && denChain.allRadicals.dropFirst.map({$0.powerValue}).allSatisfy({$0 == denChain.allRadicals.first!.powerValue}) {} else {return}
        }
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        //
        while let decimalNode = allNodes.first(where: {$0.isDecimal}) {
            convertDecimalToFraction(node: decimalNode, fnCtrl: fnCtrl + [.force, .forceConvertDecimalToFraction, .moreCertainForceConvertDecimalToFraction], &steps)
        }
        
        // Mark and Explain
        steps.lastMarked = allNodesDropMultBrkt.flatSKsNoOps
        let multNode = allNodesDropMultBrkt.filter({$0.isFraction}).extractLCMvalue.newSKs.newNode
        multNode.directSymbs = allNodesDropMultBrkt.denominatorChain.symbsLCM
        multNode.radicalParent = allNodesDropMultBrkt.denominatorChain.first!.radicalParent
        steps.lastExplanation = "Multiply both sides by \(multNode.flatSKs(.dropOp).strForExpl) to get rid of the \(allNodesDropMultBrkt.filter({$0.isFraction}).count == 1 ? "fraction" : "fractions")"
        
        // Mult both sides
        multBothSidesBy(multNode, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.skipAddition], &steps)
    }
    
    func multBothSidesBy(_ multNode: StepNode, nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Set substeps
        steps.lastStepSubsteps = [steps.last!]
        
        // Mult both sides
        if [nodeL,nodeR].contains(where: {$0.children.count == 2 && $0.children.first!.isBrackets}) {
            appendHighOpOnBothSides(opNodes: [multNode], highOp: .times, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        } else {
            insertMultiplierAtFirstOnBothSides(multNodes: [multNode], nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // Evaluate Mult
        for root in [nodeL, nodeR] {
            iterationEngine(nodeL: root, nodeR: StepNode(), fnCtrl: fnCtrl + [.skipReduceExponentiable, .skipReduceToSimplify, .skipCommonFactor, .skipRemoveOneTimesBrkt], &steps.lastStepSubsteps)
            if let brktsNode = root.children.first(where: {$0.isBrackets}), root.children.count == 2 {
                distributeMultiplier(node: brktsNode, fnCtrl: fnCtrl + [.force, .forceDistribute, .skipDistributeEval], &steps.lastStepSubsteps)
            }
            surfAndEvaluate(parent: root, fnCtrl: fnCtrl + [.skipDistribute, .skipRemoveOneTimesBrkt], &steps.lastStepSubsteps)
        }
        
        //
        surfAndEvaluateAndApplyFnTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.skipDistribute, .skipAddition, .skipReduceExponentiable, .skipReduceToSimplify, .skipCommonFactor, .skipRemoveOneTimesBrkt, .skipCancelEqualTerms], &steps.lastStepSubsteps)
        
        // Append to main steps
        let newNodes = (nodeL.children+nodeR.children).dropMultipliedBrackets.dropZeros
        steps.lastMarked.append(contentsOf: multNode.hasTerm ? newNodes.flatSKsNoOps : newNodes.valuesSK)
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .cancelEqualTermsBothSides, &steps)
    }
}

extension CalcBrain {
    func willHaveFractionAfterDistribute(multNode: StepNode) -> Bool {
        var tmpSteps = [StepModel()]
        var tmpBrktNode = StepNode()
        if multNode.next.isBrackets(.multipliedByNonBracket) {
            let newParent = [multNode, multNode.next].clone(changeID: false, withParent: false)
            tmpBrktNode = newParent.children.last!
        } else if multNode.prev.isBrackets(.multipliedByNonBracket) {
            let newParent = [multNode.prev, multNode].clone(changeID: false, withParent: false)
            tmpBrktNode = newParent.children.first!
        } else {return false}
        distributeMultiplier(node: tmpBrktNode, fnCtrl: [.force, .skipPrintStep, .forceDistribute], &tmpSteps)
        return tmpBrktNode.level!.hasFraction(flat: true)
    }
    func willHaveOneSingleVarAfterDistribute(multNode: StepNode) -> Bool {
        var tmpSteps = [StepModel()]
        var tmpBrktNode = StepNode()
        if multNode.next.isBrackets(.multipliedByNonBracket) {
            let newParent = [multNode, multNode.next].clone(changeID: false, withParent: false)
            tmpBrktNode = newParent.children.last!
        } else if multNode.prev.isBrackets(.multipliedByNonBracket) {
            let newParent = [multNode.prev, multNode].clone(changeID: false, withParent: false)
            tmpBrktNode = newParent.children.first!
        } else {return false}
        guard tmpBrktNode.children.hasVar else {return false}
        distributeMultiplier(node: tmpBrktNode, fnCtrl: [.force, .skipPrintStep, .forceDistribute], &tmpSteps)
        return tmpBrktNode.level!.contains(where: {$0.isOneSingleVar(mayBeInSqrt: false) && !$0.isMultiplied})
    }
    func willHaveDecimalInEquation(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeR.isEmpty {return false}
        let swapped = nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone
        tmpSteps[0].nodeL = nodeLClone
        tmpSteps[0].dynamicNodeR = nodeRClone
        tmpSteps[0].nodeR = nodeRClone
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        surfAndEvaluateTillEnd(parent: nodeLClone, fnCtrl: fnCtrl + [.skipPrintStep, .forceDistribute], &tmpSteps)
        surfAndEvaluateTillEnd(parent: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .forceDistribute], &tmpSteps)
        addToBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep], &tmpSteps)
        surfAndEvaluateTillEnd(parent: nodeLClone, fnCtrl: fnCtrl + [.skipPrintStep, .forceDistribute], &tmpSteps)
        surfAndEvaluateTillEnd(parent: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .forceDistribute], &tmpSteps)
        return (nodeLClone.children+nodeRClone.children).hasDecimal
    }
}
