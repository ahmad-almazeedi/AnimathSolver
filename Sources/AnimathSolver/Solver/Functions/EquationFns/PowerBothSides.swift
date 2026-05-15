//
//  PowerBothSides.swift
//  Hulul
//
//  Created by Ahmad on 23/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Darwin

extension CalcBrain {
    func powerBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        nodeL.pinRootExpr()
        powBothRadicals(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        if nodeL.pinnedRootDidChange || nodeL.forceStop {return}
        
        nodeL.pinRootExpr()
        moveIndexAsPow(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        if nodeL.pinnedRootDidChange || nodeL.forceStop {return}
        
        powerBothSidesGeneral(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func powBothRadicals(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if nodeL.children.isPlus && nodeR.children.isPlus && nodeL.children.isOneSingleTerm && nodeR.children.isOneSingleTerm {} else {return}
        guard let lhsRadical = nodeL.children.first!.radicalParent, !lhsRadical.isPowered else {return}
        guard let rhsRadical = nodeR.children.first!.radicalParent, !rhsRadical.isPowered else {return}
        var hasEqualIndices: Bool {lhsRadical.indexInt == rhsRadical.indexInt}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        //
        if lhsRadical.indexIsEven && !rhsRadical.children.hasVarOrNotVarXFlat && nodeR.children.resultValue() < 0 || rhsRadical.indexIsEven && !lhsRadical.children.hasVarOrNotVarXFlat && nodeL.children.resultValue() < 0 {
            findApproximateValue(nodes: nodeL.children, fnCtrl: fnCtrl, steps: &steps)
            findApproximateValue(nodes: nodeR.children, fnCtrl: fnCtrl, steps: &steps)
            steps.setEquationIsFalseForRad(nodeL: nodeL, nodeR: nodeR)
            return
        }
        
        //
        if !hasEqualIndices && (lhsRadical.isDoubleRadical || rhsRadical.isDoubleRadical) {
            lhsRadical.pinRootExpr()
            rhsRadical.pinRootExpr()
            mergeDoubleRadical(radicalParent: lhsRadical, fnCtrl: fnCtrl, &steps)
            mergeDoubleRadical(radicalParent: rhsRadical, fnCtrl: fnCtrl, &steps)
            if lhsRadical.pinnedRootDidChange || rhsRadical.pinnedRootDidChange {return}
        } else if (!lhsRadical.hasVarFlat || !rhsRadical.hasVarFlat) && !hasEqualIndices {return}
                
        //
        for node in (lhsRadical.children+rhsRadical.children) {
            reorderTermsFromIn(node: node, fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        let hasFractionInRadical = [lhsRadical,rhsRadical].hasFraction(flat: true)
        let indexInt = [lhsRadical.indexInt, rhsRadical.indexInt].lcm
        let isSqrt = indexInt == 2
        
        //
        steps.lastMarked = lhsRadical.opIndex + rhsRadical.opIndex
        steps.lastExplanation = isSqrt ? "Square both sides of the equation to get rid of the square roots" : "Raise both sides of the equation to the power of \(indexInt) to get rid of the roots"
        
        //
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastExplanation = isSqrt ? "Square both sides of the equation" : "Raise both sides of the equation to the power of \(indexInt)"
        
        //
        lhsRadical.power = [indexInt.newNode]
        rhsRadical.power = [indexInt.newNode]
        steps.lastStepSubsteps.lastMarked = lhsRadical.power.flatSKs+rhsRadical.power.flatSKs
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        for radParent in [lhsRadical, rhsRadical] {
            evaluateNthRootToTheNthPower(radicalParent: radParent, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            simplifyNthRootToTheMthPower(radicalParent: radParent, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        }
        
        //
        if !hasEqualIndices {
            steps.lastMarked.append(contentsOf: steps.lastStepSubsteps.allMarkedKeys)
        }
        
        //
        if hasFractionInRadical {
            steps.lastStepLastSubsteps.removeAll()
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + (hasEqualIndices ? [] : [.forceFlatSubsteps]))
    }
}

extension CalcBrain {
    func moveIndexAsPow(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if nodeL.children.isOneSingleTerm && nodeL.children.isPlus && nodeR.children.isSimplestForm {} else {return}
        guard let radicalParent = nodeL.children.first!.radicalParent, !radicalParent.isPowered && radicalParent.children.hasVarFlat else {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        //
        if radicalParent.indexIsEven && !nodeR.children.hasVarOrNotVarXFlat && nodeR.children.resultValue() < 0 {
            findApproximateValue(nodes: nodeR.children, fnCtrl: fnCtrl, steps: &steps)
            steps.setEquationIsFalseForRad(nodeL: nodeL, nodeR: nodeR)
            return
        }
        
        //
        nodeL.pinRootExpr()
        factorPerfectSquareThenEvalOrSimpSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        if nodeL.pinnedRootDidChange {return}
        
        //
        mergeDoubleRadical(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        
        //
        for node in radicalParent.children {
            reorderTermsFromIn(node: node, fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        let indexInt = radicalParent.indexInt
        let isSqrt = indexInt == 2
        var rhsFirstChild: StepNode {nodeR.children.first!.baseOrTermNode}
        
        //
        steps.lastMarked = radicalParent.opIndex
        steps.lastExplanation = isSqrt ? "Square both sides of the equation to get rid of the square root" : "Raise both sides of the equation to the power of \(indexInt) to get rid of the root"
        
        // Set substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastMarked.removeAll()
        steps.lastStepSubsteps.lastExplanation = isSqrt ? "Square both sides of the equation" : "Raise both sides of the equation to the power of \(indexInt)"
        
        //
        radicalParent.power = [indexInt.newNode]
        if nodeR.children.shouldSetBrktIfPowered {
            nodeR.children.setBrackets()
            steps.lastStepSubsteps.lastMarked.append(contentsOf: nodeR.children.first!.valueSK)
            steps.lastMarked.append(contentsOf: nodeR.children.first!.valueSK)
        }
        rhsFirstChild.power = [indexInt.newNode]
        steps.lastStepSubsteps.lastMarked.append(contentsOf: radicalParent.power.flatSKs+rhsFirstChild.power.flatSKs)
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        evaluateNthRootToTheNthPower(radicalParent: radicalParent, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        
        //
        rhsFirstChild.power.first!.valueSK = radicalParent.indexSK
        steps.lastMarked.append(contentsOf: rhsFirstChild.power.flatSKs)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        distributePowerIntoBrackets(node: rhsFirstChild, fnCtrl: fnCtrl + [.force], &steps)
        determineSignOfPoweredBrackets(node: rhsFirstChild, fnCtrl: fnCtrl + [.force], &steps)
        removeZeroPowered(node: rhsFirstChild, fnCtrl: fnCtrl, &steps)
        evaluatePow(node: rhsFirstChild, fnCtrl: fnCtrl + [.force], &steps)
    }
}

extension CalcBrain {
    func powerBothSidesGeneral(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if nodeL.children.count == 1 && nodeL.children.isPlus && nodeL.children.isSimplestForm && nodeR.children.isSimplestForm {} else {return}
        guard let radicalParent = nodeL.children.first!.radicalParent, !radicalParent.isPowered && radicalParent.children.hasVarFlat else {return}
        if moveCoeffAllowed(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl) {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        //
        if radicalParent.indexIsEven && !nodeR.children.hasVarOrNotVarXFlat && nodeR.children.resultValue() < 0 {
            findApproximateValue(nodes: nodeR.children, fnCtrl: fnCtrl, steps: &steps)
            steps.setEquationIsFalseForRad(nodeL: nodeL, nodeR: nodeR)
            return
        }
        
        //
        mergeDoubleRadical(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        
        //
        for node in radicalParent.children {
            reorderTermsFromIn(node: node, fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        divideBothSidesByGCD(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.forceDivideBothSides], &steps)
        
        //
        var indexInt = radicalParent.indexInt
        if let rhsRadVar = nodeR.children.first!.radicalParent, rhsRadVar.hasVarFlat && nodeR.children.count == 1 {
            indexInt = [rhsRadVar.indexInt, radicalParent.indexInt].lcm
        }
        let isSqrt = indexInt == 2
        var rhsFirstChild: StepNode {nodeR.children.first!.baseOrTermNode}
        var lhsFirstChild: StepNode {nodeL.children.first!.baseOrTermNode}
        
        //
        steps.lastMarked = nodeL.children.flatSKs+nodeR.children.flatSKs
        let pluralStr = nodeR.children.count == 1 && nodeR.children.first!.hasDirectRadVar ? "s" : ""
        steps.lastExplanation = isSqrt ? "Square both sides of the equation to get rid of the square root\(pluralStr)" : "Raise both sides of the equation to the power of \(indexInt) to get rid of the root\(pluralStr)"
        
        // Set substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastMarked.removeAll()
        steps.lastStepSubsteps.lastExplanation = isSqrt ? "Square both sides of the equation" : "Raise both sides of the equation to the power of \(indexInt)"
        
        //
        for root in [nodeL, nodeR] {
            if root.children.shouldSetBrktIfPowered {
                root.children.setBrackets()
                steps.lastStepSubsteps.lastMarked.append(contentsOf: root.children.first!.valueSK)
                steps.lastMarked.append(contentsOf: root.children.first!.valueSK)
            }
        }
        rhsFirstChild.power = [indexInt.newNode]
        lhsFirstChild.power = [indexInt.newNode]
        steps.lastStepSubsteps.lastMarked.append(contentsOf: lhsFirstChild.power.flatSKs+rhsFirstChild.power.flatSKs)
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        for root in [nodeL, nodeR] {
            surfAndEvaluateAndApplyFnTillEnd(parent: root, fnCtrl: fnCtrl + [.skipFlattenning, .skipSymbMultOrOrder], &steps.lastStepSubsteps)
            surfAndEvaluateAndApplyFnTillEnd(parent: root, fnCtrl: fnCtrl + [.skipFlattenning, .skipSymbMultOrOrder, .forceRadVarEval], &steps.lastStepSubsteps)
        }
        
        //
        steps.lastMarked.append(contentsOf: nodeL.children.flatSKs+nodeR.children.flatSKs)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func powerBothSidesAllowed(nodeL: StepNode, nodeR: StepNode, dynamicSwap: Bool, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let swapped = dynamicSwap && nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        powerBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func powerBothSidesAllowedDroppedMinus(nodeL: StepNode, nodeR: StepNode, dynamicSwap: Bool, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let swapped = dynamicSwap && nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        if !nodeLClone.children.isMinus {return false}
        nodeLClone.children.first!.op = .plus
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        nodeLClone.pinRootExpr()
        powerBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func powBothRadicalsAllowed(nodeL: StepNode, nodeR: StepNode, dynamicSwap: Bool, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let swapped = dynamicSwap && nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        powBothRadicals(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
}
