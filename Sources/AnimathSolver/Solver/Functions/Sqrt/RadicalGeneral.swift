//
//  GeneralRootFns.swift
//  Hulul
//
//  Created by Ahmad on 21/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func removeRadicalAndSetPow(radicalParent: StepNode, markedKeys: inout [StepKey], setCoeffPow: (StepNode) -> ()) {
        
        //
        var radCoeff: StepNode {radicalParent.coeffNode}
        let firstRadicand = radicalParent.children.first!
        
        //
        radicalParent.splitAtRadical(markedKeys: &markedKeys)
        
        //
        let newRadCoeff = radCoeff
        let originalOp = newRadCoeff.op
        newRadCoeff.removeRadical()
        newRadCoeff.staticID = firstRadicand.staticID
        newRadCoeff.staticIDForStepIncrement = firstRadicand.staticIDForStepIncrement // didn't test very well, maybe should remove
        newRadCoeff.content = firstRadicand.content
        newRadCoeff.op = originalOp
        
        //
        setCoeffPow(newRadCoeff)
        
        //
        firstRadicand.nodeProduct = newRadCoeff
    }
}

extension CalcBrain {
    func nthRootTimesEqualNthRootNTimes(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if radicalParent.exist && radicalParent.coeffNode.exist && !radicalParent.isPowered {} else {return}
        if radicalParent.children.isSimplestFormNegletPowered {} else {return}
        let multChainRadicals = radicalParent.coeffNode.multChain(forward: false).directRadicals
        let equalRadicalNodes = multChainRadicals.dropNode(node: radicalParent).filter({$0.exist && $0.isEqualTo(node: radicalParent)})
        let indexValue = radicalParent.indexSK.getInt
        if indexValue-1 <= equalRadicalNodes.count {} else {return}
        let nodesToCancel = [StepNode](equalRadicalNodes[0..<indexValue-1])
        let origFirstRadical = radicalParent.clone(changeID: false, withParent: false)
        
        //
        if !steps.first!.inMainSteps {
            setEvenRootOfNegativeToUndefined(nodeL: radicalParent.root, nodeR: radicalParent.otherSide, fnCtrl: fnCtrl, &steps)
            if steps.last!.nodeL.isUndefined {
                steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
                return
            }
        }
        
        // Mark and Explain
        steps.lastMarked = radicalParent.flatSKs + nodesToCancel.flatSKs
        let exprOrNumberStr1 = radicalParent.children.isWholeNumber(mayBeCoeff: false) ? "a number" : "an expression"
        let exprOrNumberStr2 = radicalParent.children.isWholeNumber(mayBeCoeff: false) ? "number" : "expression"
        steps.lastExplanation = indexValue == 2 ? "When a square root of \(exprOrNumberStr1) is multiplied by itself, the result is that \(exprOrNumberStr2)" : indexValue == 3 ? "When three cube roots of the same \(exprOrNumberStr2) are multiplied together, the result is that \(exprOrNumberStr2)" : "When an nth root of \(exprOrNumberStr1) is multiplied by itself n times, the result is that \(exprOrNumberStr2)"
        
        //
        nodesToCancel.removeRadicals()
        
        //
        radicalParent.extractRadicalContent(markedKeys: &steps.lastMarked)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: origFirstRadical.children.flatSKs.ids, mergesKeysIDs: nodesToCancel.map({$0.children.flatSKs.ids}))
    }
}

extension CalcBrain {
    func evaluateRoot(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if radicalParent.exist {} else {return}
        let firstRadicand = radicalParent.children.first!
        if firstRadicand.isCoeff {return}
        guard radicalParent.children.count == 1 && firstRadicand.isWholeNumber(mayBePowered: false, mayBeCoeff: false) else {return}
        if firstRadicand.isOne {return}
        let sqrtResult = pow(firstRadicand.valueDouble, 1/radicalParent.indexSK.getDouble).rounded
        guard sqrtResult.isWholeNumber else {return}
        
        // Mark and explain
        steps.lastMarked = radicalParent.opIndex + radicalParent.children.flatSKs(.dropPlus)
        let nthRootTitle = radicalParent.indexSK.keys == [.two] ? " square" : radicalParent.indexSK.keys == [.three] ? " cube" : ""
        steps.lastExplanation = "Evaluate the\(nthRootTitle) root"
        
        //
        steps.lastStepSubsteps = [steps.last!]
        
        //
        extractMinusFromRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        steps.lastStepSubsteps.lastMarked = firstRadicand.flatSKs
        steps.lastStepSubsteps.lastExplanation = rewriteInExponentialExplanation
        
        //
        var resultValueSK = sqrtResult.newSKs
        resultValueSK.replaceSimilarKeys(similarKeys: firstRadicand.valueSK)
        
        //
        firstRadicand.valueSK = resultValueSK
        firstRadicand.power = [StepNode(valueSK: radicalParent.indexSK.newSKs)]
        
        //
        steps.lastStepSubsteps.lastMarked.append(contentsOf: firstRadicand.flatSKs)
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        evaluateNthPowerInNthRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        steps.lastMarked.append(contentsOf: steps.lastStepSubsteps.allMarkedKeys)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func fractionPowerToRadical(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist || fnCtrl.contains(.skipPow) {return}
        guard let level = node.level else {return}
        guard node.isPowerer && level.isPosSimplestFraction else {return}
        var poweredNode = node.poweredNode
        if poweredNode.valueIsOne {
            removeOnePowered(node: poweredNode, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        if !fnCtrl.isForced {
            
            //
            node.pinRootExpr()
            if poweredNode.isBrackets {
                distributePowerIntoBrackets(node: poweredNode, fnCtrl: fnCtrl, &steps)
            } else if poweredNode.baseNode.parent!.isBrackets {
                distributePowerIntoBrackets(node: poweredNode.baseNode.parent!, fnCtrl: fnCtrl, &steps)
            }
            if node.pinnedRootDidChange {return}

            //
            node.pinRootExpr()
            multiplySameBaseWithFractionAsPower(node: poweredNode.baseNode, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
            
            //
            node.pinRootExpr()
            mergeRadicalsWithDifferentIndices(radicals: poweredNode.baseNode.multChain(forward: false).directRadicals.filter({$0.children.first!.hasEqualBaseIfExpo(with: poweredNode)}), fnCtrl: fnCtrl + [.forceMergeRadWithDiffIdx], &steps)
            if node.pinnedRootDidChange {return}

            //
            node.pinRootExpr()
            cancelDividerWithMultiplier(node: poweredNode.baseNode, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
            
            //
            if isReducible(node: poweredNode.baseNode, fnCtrl: fnCtrl) {return}
            else {
                if poweredNode.baseNode.isInDenominator && poweredNode.baseNode.parentFraction!.numeratorMultChain(termMix: true).contains(where: {!$0.power.isSimplestForm || $0.power.isFraction && !$0.power.isPosSimplestFraction}) {return}
                if poweredNode.baseNode.numeratorMultChain(termMix: true).contains(where: {!$0.power.isSimplestForm || $0.power.isFraction && !$0.power.isPosSimplestFraction}) {return}
            }
            if poweredNode.isSymb {
                if poweredNode.baseNode.multChain(forward: false).dropNode(node: poweredNode.baseNode).hasSymbTypeFlat(type: poweredNode.type?.key) {return}
            }
        }
                
        //
        steps.lastMarked = poweredNode.valueSK + node.flatSKs + (poweredNode.isBrackets ? poweredNode.children.flatSKs : [])
        steps.lastExplanation = "Use aᵐᐟⁿ = ⁿ√aᵐ to transform the expression"

        //
        if poweredNode.isTerm {
            if !poweredNode.coeffNode.isOneSingleTerm {
                poweredNode.coeffNode.splitTermsAt(poweredNode)
            }
            poweredNode = poweredNode.coeffNode
        } else if poweredNode.isCoeff {
            poweredNode.extractTerms()
        }
        let radicalCoeff = StepNode.newOneNodeWithSqrt(indexSK: node.denominator.first!.valueSK)
        radicalCoeff.op = poweredNode.op
        poweredNode.op = .plus
        poweredNode.insertAfter(radicalCoeff)
        node.poweredNode.removePower()
        poweredNode.remove()
        radicalCoeff.radicalParent!.children = [poweredNode]
        node.poweredNode.power = node.numerator
        radicalCoeff.radicalParent!.op.id = node.valueSK.first!.id
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        removePowerOne(node: poweredNode.baseOrTermNode, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func mergeDoubleRadical(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !radicalParent.exist || radicalParent.isPowered {return}
        if radicalParent.children.isOneSingleTerm && radicalParent.children.isPlus {} else {return}
        guard let innerRadical = radicalParent.children.first!.radicalParent, !innerRadical.isPowered else {return}
        if !innerRadical.children.isSimplestForm && innerRadical.children.isMultiNoHighOpChain {return}
        mergeDoubleRadical(radicalParent: innerRadical, fnCtrl: fnCtrl, &steps)
        let newIndexInt = radicalParent.indexInt*innerRadical.indexInt
        if newIndexInt > 99 {return}
        
        //
        radicalParent.pinRootExpr()
        mergeSameBaseInSqrt(radicalParent: innerRadical, fnCtrl: fnCtrl + [.skipMergeSameBaseInSqrtIfHasNonRootable], &steps)
        evaluateNthPowerInNthRoot(radicalParent: innerRadical, fnCtrl: fnCtrl, &steps)
        evaluateRoot(radicalParent: innerRadical, fnCtrl: fnCtrl, &steps)
        if radicalParent.pinnedRootDidChange {return}
        
        //
        if innerRadical.children.areAllRootables(indexValue: innerRadical.indexValue) {
            simplifyMultipleRadicands(radicalParent: innerRadical, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        steps.lastMarked = radicalParent.opIndex + innerRadical.opIndex
        steps.lastExplanation = "Use ᵐ√ ⁿ√a = ᵐⁿ√a to simplify the expression"
        
        //
        radicalParent.indexSK = newIndexInt.newSKs
        radicalParent.children = innerRadical.children
        steps.lastMarked.append(contentsOf: radicalParent.indexSK)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: [radicalParent.op.id], mergesKeysIDs: [[innerRadical.op.id]])
    }
}

extension CalcBrain {
    func setEvenRootOfNegativeToUndefined(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        if fnCtrl.contains(.skipSetNegRootToUndef) {return}
        for node in (nodeL.allRadicalsFlat + nodeR.allRadicalsFlat) {
            
            //
            if node.isEvenNegRootNoVarOrNotVarX {} else {continue}
            if !node.children.flatTree.contains(where: {$0.isEvenNegRootNoVarOrNotVarX}) {} else {continue}
            
            //
            for radicandNode in node.children.flatTree {
                detectDivideByZero(node: radicandNode, fnCtrl: fnCtrl, &steps)
                if steps.lastExplanation.hasSuffix("is undefined") && nodeL.forceStop {return}
            }
            
            //
            surfAndEvaluateAndApplyFnTillEnd(parent: node, fnCtrl: fnCtrl.drop(.setInMainSteps) + [.force, .skipSetNegRootToUndef, .skipExtractI], &steps)
            
            //
            let markedKeys = node.opIndex + node.children.flatSKs
            let squareOrEvenStr = node.indexInt == 2 ? "square" : "even"
            let explanation = "The \(squareOrEvenStr) root of a negative number does not exist in the set of real numbers"
            
            // Set Undefined
            setToUndefined(nodeL: nodeL, nodeR: nodeR, markedKeys: markedKeys, explanation: explanation, &steps)
            return
        }
    }
}

extension CalcBrain {
    func extractMinusFromRoot(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !radicalParent.exist || radicalParent.isPowered {return}
        if !radicalParent.indexIsEven && radicalParent.children.isMinus && !radicalParent.children.dropMinus.hasMinusFlatNoPow {} else {return}
        if radicalParent.children.isMultChain {} else {return}
        let firstRadicand = radicalParent.children.first!
        if firstRadicand.isFraction && firstRadicand.children.hasMinusFlatNoPow {return}
        var radCoeff: StepNode {radicalParent.coeffNode}
        
        //
        steps.lastMarked = [firstRadicand.op]
        steps.lastExplanation = "An odd root of a negative radicand is always a negative"
        
        //
        radicalParent.splitAtRadical(markedKeys: &steps.lastMarked)

        //
        if !radCoeff.isPlus {
            let newBrackets = StepNode.newBracketsNode
            radCoeff.insertAfter(newBrackets)
            newBrackets.op = radCoeff.op
            radCoeff.remove()
            newBrackets.children = [radCoeff]
            steps.lastMarked.append(contentsOf: newBrackets.valueSK)
        }
        
        //
        radCoeff.op = firstRadicand.op
        firstRadicand.op = .plus
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func mergeRadicalsOfFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !fnCtrl.isForced && node.isSurfed {return}
        if node.isFraction && node.numerator.isOneSingleRadical && node.denominator.isOneSingleRadical {} else {return}
        let numRadOpIdx = node.numerator.first!.radicalParent!.opIndex
        let denRadOpIdx = node.denominator.first!.radicalParent!.opIndex
        if numRadOpIdx.last!.key == denRadOpIdx.last!.key {} else {return}
        let newFraction = node.clone(changeID: false, withParent: false).withOp(.plus)
        let numRadParent = newFraction.numerator.first!.radicalParent!
        let denRadParent = newFraction.denominator.first!.radicalParent!
        numRadParent.extractPosAloneRadicalContent()
        denRadParent.extractPosAloneRadicalContent()
        if newFraction.isReducibleIsolatedFraction {} else {return}
        
        // Mark and Explain
        steps.lastMarked = node.flatSKs(.dropOp)
        let nthStr = numRadParent.indexInt == 2 ? "" : "ⁿ"
        let squareStr = numRadParent.indexInt == 2 ? "square " : ""
        steps.lastExplanation =  "Use \(nthStr)√a / \(nthStr)√b = \(nthStr)√(a/b) to divide the \(squareStr)roots."
        steps.lastNote = "where: a ≥ 0, b ≥ 0"
        
        // init newRadParent
        let newRadParent = StepNode.newOneNodeWithSqrt(indexSK: [.two]).radicalParent!
        if numRadOpIdx.count != 2 || numRadOpIdx.first!.key != .sqrt || !numRadOpIdx.last!.key.isNumberOrDot {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        newRadParent.op = numRadOpIdx.first!
        newRadParent.indexSK = numRadOpIdx.dropFirst
        newRadParent.children = [newFraction]
        
        //
        node.replace(with: newRadParent.coeffNode, withOp: true)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + (node.isInBrackets(.powered) ? [.skipRemoveUslessBrackets] : []))
        
        //
        steps.appendMergeIDs(originalKeysIDs: numRadOpIdx.ids, mergesKeysIDs: [denRadOpIdx.ids])
        
        //
        reduceFraction(node: newFraction, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func radicalToExponent(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if radicalParent.children.isMinus && radicalParent.indexIsEven {return}
        if radicalParent.isPowered {return}
        if !radicalParent.isSqrt || !radicalParent.children.isSingleNode {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        let firstRadicand = radicalParent.children.first!.baseOrTermNode
        
        //
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = radToExpExplanation
        
        //
        radicalParent.splitAtRadical(markedKeys: &steps.lastMarked)
        
        //
        let newFraction = StepNode.newFractionNode
        newFraction.valueSK[0].id = radicalParent.op.id
        newFraction.numerator = firstRadicand.isPowered ? firstRadicand.power : [1.newNode]
        newFraction.denominator = [radicalParent.indexSK.newNode]
        steps.lastMarked.append(contentsOf: newFraction.flatSKs)
        let newNode = radicalParent.children.first!.clone(changeID: false, withParent: false)
        newNode.removePower()
        newNode.baseOrTermNode.power = [newFraction]
        
        //
        newNode.op = radicalParent.coeffNode.op
        radicalParent.coeffNode.insertAfter(newNode)
        radicalParent.coeffNode.remove()
        
        //
        radicalParent.nodeProduct = newNode
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func factorPerfectSquareThenEvalOrSimpSqrt(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !radicalParent.exist || radicalParent.isPowered {return}
        if !fnCtrl.contains(.forceRadVarEval) && radicalParent.hasVarFlat && radicalParent.isEquation {return}
        if radicalParent.children.isSimplestFormMulti {} else {return}
        let clone = radicalParent.children.clone(changeID: false, withParent: false)
        var fakeSteps = [StepModel(dynamicExprs: [Expression()])]
        fakeSteps[0].prevExprs.nodeL = clone
        factorPolynomial(parent: clone, fnCtrl: fnCtrl + [.skipPrintStep], &fakeSteps)
        if clone.children.contains(where: {$0.isBrackets(.powered) && ($0.isRootableOrSimplifiable(indexValue: radicalParent.indexValue, isNotRootableIfMultiplied: false) || $0.powerValue.isMultipleOrDivider(of: radicalParent.indexValue))}) {} else {return}
        guard clone.children.isMultChain else {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        
        //
        factorPolynomial(parent: radicalParent, fnCtrl: fnCtrl, &steps)
        
        //
        if radicalParent.indexIsEven && radicalParent.children.isMinus {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
        }
    }
}
