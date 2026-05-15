//
//  MultiplyBothSides.swift
//  Hulul
//
//  Created by Ahmad on 24/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func multiplyBothSidesCases(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if nodeL.forceStop {return}
        multBothSidesToRemoveDenominatorOtherIsZero(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        removeAllDenominators(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        multBothSidesByFraction(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        xMultiplication(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        multBothSidesSinglebyLCM(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        multBothSidesByNegativeOneForBrkt(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        multBothSidesbyLCM(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func multBothSidesToGetRidOfDecimals(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        if nodeL.children.isSimplestFormNegletTimesBracket && nodeR.children.isSimplestFormNegletTimesBracket {} else {return}
        if nodeL.allNodes.hasBrackets(.powered) {return}
        let allNodes = nodeL.children + nodeR.children
        if allNodes.hasFraction(flat: false) {return}
        if allNodes.hasDecimal && (allNodes.hasBrackets(.any) || allNodes.allSymbs.shouldMoveAllToSide) {} else {return}
        
        //
        let gcdNode = allNodes.filter({$0.isDecimal}).max(by: {$0.afterDotCount < $1.afterDotCount})!.cloneWithChangedStaticIDs
            
        //
        let multNode = gcdNode.tenPoweredToDecimalCount
        gcdNode.valueSK = (gcdNode.valueDouble*multNode.valueDouble).newSKs
        
        // Mark and explain
        steps.lastMarked = allNodes.dropBrackets.dropZeros.flatSKsNoTerms(.dropOp).filter({!$0.key.isOp})
        steps.lastExplanation = "Multiply both sides by \(multNode.flatSKs(.dropOp).strForExpl) to get rid of decimals"
        
        //
        multBothSidesBy(multNode, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func isMultBothSidesCommonConditions(nodeL: StepNode, nodeR: StepNode) -> Bool {
        if nodeL.children.isNumberWithX(mayBeDecimal: false, mayBeOneVar: true) && !nodeR.children.hasVarFlat || nodeR.children.isNumberWithX(mayBeDecimal: false, mayBeOneVar: true) && !nodeL.children.hasVarFlat {return false}
        if nodeL.children.isSimplestFormNegletTimesBracket && nodeR.children.isSimplestFormNegletTimesBracket {} else {return false}
        let allNodes = nodeL.children + nodeR.children
        if allNodes.contains(where: {$0.isFraction}) {} else {return false}
        return true
    }
    func multBothSidesAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let swapped = nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        multiplyBothSidesCases(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func removeAllDenominatorsAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let swapped = nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        removeAllDenominators(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func multBothSidesByFractionAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let swapped = nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        determineChainSignTillEnd(node: nodeLClone, fnCtrl: fnCtrl + [.skipPrintStep, .skipMultBothSidesBySingleCheck], &tmpSteps)
        determineChainSignTillEnd(node: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .skipMultBothSidesBySingleCheck], &tmpSteps)
        nodeLClone.pinRootExpr()
        multBothSidesByFraction(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func multBothSidesBySingleAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let swapped = nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        multBothSidesSinglebyLCM(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func willMultBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeR.isEmpty {return false}
        let nodeTuple = surfAndEvaluateOutput(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.skipCancelIfWillRemain])
        return multBothSidesAllowed(nodeL: nodeTuple.nodeL, nodeR: nodeTuple.nodeR, fnCtrl: [])
    }
}
