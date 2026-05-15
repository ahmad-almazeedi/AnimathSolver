//
//  SimplifyRoot.swift
//  Hulul
//
//  Created by Ahmad on 17/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func simplifyRoot(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !radicalParent.exist || fnCtrl.contains(.skipRadicalSimplifying) {return}
        if radicalParent.isPowered {return}
        let firstRadicand = radicalParent.children.first!
        if firstRadicand.isPlus {} else {return}
        if firstRadicand.isFraction || firstRadicand.baseOrTermNode.isSqrt {return}
        if radicalParent.children.count == 1 && (firstRadicand.isWholeNumber(mayBePowered: true, mayBeCoeff: true) || firstRadicand.isBrackets) {} else {return}
        if fnCtrl.isForced {} else {
            if let radicalParentParent = radicalParent.coeffNode.parent, radicalParentParent.isSqrt && radicalParentParent.children.isMultChain && !radicalParentParent.children.hasRootableOrSimplifiable(indexValue: radicalParentParent.indexValue, isNotRootableIfMultiplied: true) {
                if !radicalParentParent.dontHaveRootableAndWillHaveRootableOrSimplifiable {return}
            }
        }
        
        //
        simplifyPoweredRoot(radicalParent: radicalParent, firstRadicand: firstRadicand, fnCtrl: fnCtrl, &steps)
        simplifyNonPoweredRoot(radicalParent: radicalParent, firstRadicand: firstRadicand, fnCtrl: fnCtrl, &steps)
    }
    func simplifyPoweredRoot(radicalParent: StepNode, firstRadicand: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !firstRadicand.isCoeff || firstRadicand.isOneSingleTerm {} else {return}
        if firstRadicand.isBrackets({$0.hasFraction(.any) || $0.isMinus}) {return}
        let targetedRadicand = firstRadicand.baseOrTermNode
        if targetedRadicand.isSqrt {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        if targetedRadicand.isPowered && targetedRadicand.power.isWholeNumber(mayBeCoeff: false) {} else {return}
        if radicalParent.children.hasVarFlat && radicalParent.coeffNode.isEquation {return}
        let firstRadPowInt = Int(targetedRadicand.powerValue)
        if firstRadPowInt > radicalParent.indexInt {} else {return}
        if firstRadPowInt.isMultiple(of: radicalParent.indexInt) {return}
        
        //
        radicalParent.pinRootExpr()
        reduceIndexWithPower(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        if radicalParent.pinnedRootDidChange {return}
        
        //
        let originalRadicalOp = radicalParent.op
        let originalRadicalIndex = radicalParent.indexSK
        let originalRadicandPowerSKs = targetedRadicand.power.first!.valueSK
        
        // Mark and explain
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Simplify the radical"
        
        //
        steps.lastStepSubsteps = [steps.last!]
        
        //
        expandSimplifiablePoweredRadicand(radicalParent: radicalParent, node: targetedRadicand, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        let firstFactor = radicalParent.children.first!.baseOrTermNode
        var secondFactor = StepNode()
        if firstFactor.isSymb {
            secondFactor = radicalParent.children.first!.directSymbs.last!
        } else {
            secondFactor = radicalParent.children.last!
        }
        
        //
        splitRadicalContent(rootableNodes: [firstFactor], fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        evaluateNthPowerInNthRoot(radicalParent: firstFactor.baseNode.parent!, fnCtrl: fnCtrl + [.skipFlattenning], &steps.lastStepSubsteps)
        evaluateMultipleOfNthPowerInNthRoot(radicalParent: firstFactor.baseNode.parent!, fnCtrl: fnCtrl + [.skipFlattenning], &steps.lastStepSubsteps)
        
        //
        if secondFactor.isPowered {
            for i in 0..<secondFactor.power.first!.valueSK.count {
                secondFactor.power.first!.valueSK[i].id = originalRadicandPowerSKs[i].id
            }
            secondFactor.power.first!.valueSK.replaceSimilarKeys(similarKeys: originalRadicandPowerSKs)
        }
        secondFactor.baseNode.parent!.op = originalRadicalOp
        secondFactor.baseNode.parent!.indexSK = originalRadicalIndex
        steps.lastMarked.append(contentsOf: steps.lastStepSubsteps.allMarkedKeys)
        steps.lastStep.appendCloneIDs(originalKeysIDs: firstFactor.valueSK.ids, clonesKeysIDs: [secondFactor.valueSK.ids])
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if let firstFactor = firstFactor.nodeProduct {
            evaluatePow(node: firstFactor, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
    func simplifyNonPoweredRoot(radicalParent: StepNode, firstRadicand: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if radicalParent.exist && firstRadicand.exist {} else {return}
        if !firstRadicand.isPlus || firstRadicand.isCoeff || firstRadicand.isPowered || firstRadicand.isBrackets {return}
        guard firstRadicand.valueSK.canBeInt else {return}
        if firstRadicand.valueSK.getInt.primeFactors.simplifyToTwoFactors(withIndex: radicalParent.indexSK.getInt) == nil {return}
        let coeffWasTime = radicalParent.coeffNode.isTimes || !(radicalParent.parent!.isOneTerm && radicalParent.isBeforeSymbs)
                
        // Mark and explain
        let originalStepExprNoIndex = radicalParent.children.flatSKs(.dropOp)
        let originalRadicalOp = radicalParent.op
        let originalRadicalIndex = radicalParent.indexSK
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Simplify the radical"
        
        //
        steps.lastStepSubsteps = [steps.last!]
        
        //
        expandSimplifiableNonPoweredRadicand(radicalParent: radicalParent, node: firstRadicand, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        let firstFactor = radicalParent.children.first!
        let secondFactor = radicalParent.children.last!
        
        //
        splitRadicalContent(rootableNodes: [firstFactor, secondFactor], fnCtrl: fnCtrl, &steps.lastStepSubsteps)

        //
        evaluateNthPowerInNthRoot(radicalParent: firstFactor.parent!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        evaluateRoot(radicalParent: firstFactor.parent!, fnCtrl: fnCtrl + [.skipFlattenning], &steps.lastStepSubsteps)
        
        //
        [firstFactor.parent!.coeffNode, secondFactor].replaceSimilarKeys(with: originalStepExprNoIndex, withPow: false)
        secondFactor.parent!.op = originalRadicalOp
        secondFactor.parent!.indexSK = originalRadicalIndex
        steps.lastMarked.append(contentsOf: firstFactor.parent!.coeffNode.opValueSK(coeffWasTime ? .any : .dropOp)+secondFactor.parent!.flatSKs(.dropOp))
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func simplifyExponentiablePoweredRadicand(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !radicalParent.exist {return}
        if radicalParent.isPowered || !radicalParent.children.isMultChain {return}
        var enteredLoop = false
        while let poweredRadicand = radicalParent.children.first(where: {poweredRadicand in
            if poweredRadicand.isWholeNumber(mayBePowered: true, mayBeCoeff: true) && poweredRadicand.isPoweredByWholeNumber {} else {return false}
            if poweredRadicand.powerValue >= radicalParent.indexValue {return false}
            guard let exponentiandNode = poweredRadicand.getExponentialForm else {return false}
            if exponentiandNode.powerValue*poweredRadicand.powerValue < radicalParent.indexValue {return false}
            return true
        }) {
            
            //
            enteredLoop = true
            let exponentiandNode = poweredRadicand.getExponentialForm!
            
            //
            steps.lastMarked = poweredRadicand.valueSK
            steps.lastExplanation = rewriteInExponentialExplanation
            
            //
            poweredRadicand.replace(with: exponentiandNode, withOp: true)
            exponentiandNode.extractTerms()
            exponentiandNode.setSelfToBrackets(extractOp: true)
            steps.lastMarked.append(contentsOf: exponentiandNode.flatSKs)
            exponentiandNode.power = poweredRadicand.power
            
            //
            appendStep(&steps, fnCtrl: fnCtrl)
            
            //
            distributePowerIntoBrackets(node: exponentiandNode, fnCtrl: fnCtrl + [.force], &steps)
        }
        guard enteredLoop else {return}
        
        //
        mergeSameBaseInSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
    }
}
