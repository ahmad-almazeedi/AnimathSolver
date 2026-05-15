//
//  EvaluateMult.swift
//  Hulul
//
//  Created by Ahmad on 14/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func evaluateMult(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        reorderTermsFromOut(node: node, fnCtrl: fnCtrl, &steps)
        multDefault(node: node, fnCtrl: fnCtrl, &steps)
        multRadicals(node: node, fnCtrl: fnCtrl, &steps)
        multSameBase(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func multDefault(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        guard let level = node.level else {return}
        if node.isPowered || node.isDivide || node.isOneTerm {return}
        if node.isBrackets || node.isFraction {return}
        if fnCtrl.isForced {} else {
            if node.isSurfed {return}
            if node.isInDividedMultChain && !fnCtrl.isForced {return}
            if node.parent!.isDivide && level.isMultChain {return}
            if let parentFraction = node.parentFraction {
                if parentFraction.isFraction(.hasBrackets(.notSimplest, for: .any)) {return}
                if parentFraction.isInMultChainNoBrackets(.notSingle(mayBeFraction: true)) && parentFraction.isFraction(.onlyTimes) && !parentFraction.isFraction(.hasFraction) {return}
                if isReducible(node: parentFraction, fnCtrl: [.skipCommonFactor]) {return}
            }
            let multChain = node.multChain(forward: false)
            if multChain.isEmpty || !node.isFirstInMultChainNoBracketsNoOneTerms {return}
            if multChain.hasFraction(flat: false) || multChain.hasPowered {return}
            if multChain.radicalMix.hasBrackets(.notSimplest) || multChain.hasBrackets(.single(mayBePowered: true)) {return}
            if isDetermineChainSign(node: multChain.first!, fnCtrl: []) {return}
        }
        let defaultChain = fnCtrl.targetOnly ? node.timesDefaultChain.filter({$0.isTarget}) : node.timesDefaultChain
        if defaultChain.count > 1 {} else {return}
        
        // Extrac Radicals
        defaultChain.dropFirst.filter({!$0.isOneTerm}).splitAtEachRadical()
        
        // Evaluate
        multValues(node: node, fnCtrl: fnCtrl, &steps)
        if fnCtrl.targetOnly {return}
        multRadicals(node: node, fnCtrl: fnCtrl, &steps)
        multSameBase(node: node, fnCtrl: fnCtrl, &steps)
    }
    private func multValues(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        var defaultChain = fnCtrl.targetOnly ? node.timesDefaultChain.filter({$0.isTarget}) : node.timesDefaultChain
        if defaultChain.filter({!$0.isOneTerm}).count > 1 {} else {return}
        if defaultChain.contains(where: {$0.isDivide}) {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        defaultChain.removeAll(where: {$0.isOneTerm || $0.isBrackets})
        
        //
        if let radicalParent = node.parent, radicalParent.isSqrt {
            node.pinRootExpr()
            mergeSameBaseInSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        if defaultChain.hasLongDecimal {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        
        //
        let shouldMarkOp = node.isPlus && defaultChain.hasNegative
        let originalSKs = defaultChain.flatSKsNoTerms(.any)
        
        //
        if fnCtrl.targetOnly {
            multiplyTargetsOnly(node: node, defaultChain: defaultChain, fnCtrl: fnCtrl, &steps)
        } else {
            if let oneNode = defaultChain.first(where: {$0.isOne}) {
                removeHighOpOne(node: oneNode, fnCtrl: fnCtrl, &steps)
                return
            }
            subMultiplying(node: node, defaultChain: defaultChain, fnCtrl: fnCtrl, &steps)
        }
        
        // Nextmark and append
        if let nodeProduct = node.nodeProduct {
            nodeProduct.valueSK.replaceSimilarKeys(similarKeys: originalSKs)
            steps.lastMarked.append(contentsOf: nodeProduct.flatSKsNoTerms(shouldMarkOp ? .any : .dropOp))
        } else {
            steps.lastMarked.append(contentsOf: (node.flatSKsNoTerms(shouldMarkOp ? .any : .dropOp)))
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func multiplyTargetsOnly(node: StepNode, defaultChain: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // set condition if positive and contains negative
        let shouldMarkOp = node.isPlus && defaultChain.hasNegative
        
        // Preserve Symbols
        let symbNodes = defaultChain.allSymbs
        
        // get result node
        let resultNode = defaultChain.getResultNodeForHighOp(returnSymbs: false)
        
        // Mark and explain
        steps.lastMarked = defaultChain.filter({!$0.isOneTerm}).flatSKsNoTerms(shouldMarkOp ? .any : .dropOp)
        steps.lastExplanation = defaultChain.count > 2 ? calcProdExpl : "Multiply the numbers"
        
        // Replace nodes with result
        node.level!.replaceNodesWithResult(nodes: defaultChain, resultNode: resultNode)
        if fnCtrl.targetOnly {
            for symbNode in symbNodes {
                symbNode.isTarget = true
            }
        }
        if node.isCoeff {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        node.directSymbs = symbNodes
    }
    
    func subMultiplying(node: StepNode, defaultChain: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // set condition if positive and contains negative
        let shouldMarkOp = node.isPlus && defaultChain.hasNegative
        
        // Mark & Explain
        let multChain = node.multChain(forward: true)
        let splittedChain = multChain.split(whereSeparator: {$0.isBrackets})
        let shouldMarkSymbs = multChain.hasBrackets(.any) && splittedChain.count > 1 && [StepNode](splittedChain.last!).hasSymb
        steps.lastMarked = shouldMarkSymbs ? defaultChain.flatSKs(shouldMarkOp ? .any : .dropOp) : defaultChain.filter({!$0.isOneTerm}).flatSKsNoTerms(shouldMarkOp ? .any : .dropOp)
        steps.lastExplanation = calcProdExpl
        
        // Substeps
        steps.lastStepSubsteps = [steps.last!]
        
        //
        var tmpDefaultChain = defaultChain.reoderedWithDecimalsFirst
        
        while tmpDefaultChain.count > 1 {
            
            //
            var isPowerOf10 = false
            var multiplierNode = StepNode()
            if let tmpMultiplierNode = tmpDefaultChain.first(where: {multiplierNode in
                tmpDefaultChain.dropNode(node: multiplierNode).contains(where: {
                    let resultValue = $0.valueDouble*multiplierNode.valueDouble
                    return resultValue != 1 && log10(resultValue).isWholeNumber
                })
            }) {
                isPowerOf10 = true
                multiplierNode = tmpMultiplierNode
            } else if let tmpMultiplierNode = tmpDefaultChain.first(where: {multiplierNode in
                tmpDefaultChain.dropNode(node: multiplierNode).contains(where: {
                    let resultValue = $0.valueDouble*multiplierNode.valueDouble
                    return resultValue.truncatingRemainder(dividingBy: 10) == 0 || [$0, multiplierNode].hasDecimal && resultValue.isWholeNumber
                })
            }) {
                multiplierNode = tmpMultiplierNode
            } else {
                multiplierNode = tmpDefaultChain.first!
            }
            var multiplicandNode = tmpDefaultChain.dropNode(node: multiplierNode).first(where: {
                let resultValue = $0.valueDouble*multiplierNode.valueDouble
                if isPowerOf10 {
                    return resultValue != 1 && log10(resultValue).isWholeNumber
                } else {
                    return resultValue.truncatingRemainder(dividingBy: 10) == 0 || [$0, multiplierNode].hasDecimal && resultValue.isWholeNumber
                }
            }) ?? defaultChain.dropNode(node: multiplierNode).filter({$0.exist}).first!
            
            //
            if multiplierNode.idx! > multiplicandNode.idx! {
                let holder = multiplierNode
                multiplierNode = multiplicandNode
                multiplicandNode = holder
            }
            
            // set to evaluate nodes
            let subNodes = [multiplierNode, multiplicandNode]
            
            //
            if multiplierNode.isFirstIn(in: defaultChain) && multiplicandNode.isFirstIn(in: defaultChain.dropFirst.filter({$0.exist})) {
                steps.lastStepSubsteps.lastExplanation = "Multiply the numbers"
            } else {
                steps.lastStepSubsteps.lastExplanation = subNodes.hasDecimal ? "Multiply the decimal by a number so that the result equals a whole number" : "To make the calculation easier, first multiply the numbers that result in multiples of 10"
            }
            
            // Preserve Symbols
            let symbs = subNodes.allSymbs
            let radicalParent = multiplierNode.radicalParent
            
            // get result node
            let resultNode = subNodes.getResultNodeForHighOp(returnSymbs: false)
            
            // Mark and explain
            steps.lastStepSubsteps.lastMarked = subNodes.filter({!$0.isOneTerm}).flatSKsNoTerms(shouldMarkOp ? .any : .dropOp)
            
            // Replace nodes with result
            multiplierNode.level!.replaceNodesWithResult(nodes: subNodes, resultNode: resultNode)
            if multiplierNode.isCoeff {
                steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
                return
            }
            multiplierNode.directSymbs = symbs
            multiplierNode.radicalParent = radicalParent
            
            // Nextmark and append
            steps.lastStepSubsteps.lastMarked.append(contentsOf: multiplierNode.flatSKsNoTerms(shouldMarkOp ? .any : .dropOp))
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipRemoveUslessBrackets])
            
            //
            if let oneNode = tmpDefaultChain.first(where: {$0.isOne}), tmpDefaultChain.count > 2 {
                removeHighOpOne(node: oneNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            }
            
            // Extract Radicals
            defaultChain.dropFirst.splitAtEachRadical()
            
            //
            tmpDefaultChain.removeAll(where: {!$0.exist})
            
            //
            node.nodeProduct = multiplierNode
        }
    }
}

extension CalcBrain {
    func mergeSameBaseInSqrt(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !radicalParent.isSqrt {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        guard radicalParent.exist else {return}
        let firstRadicand = radicalParent.children.first!
        guard let level = firstRadicand.level else {return}
        guard !fnCtrl.targetOnly && level.isMultChain else {return}
        
        //
        let indexValue = firstRadicand.parent!.indexValue
        let multChain = firstRadicand.multChain(forward: false).filter({$0.isNumber(mayBePowered: true)})
        let multChainTermMix = multChain.filter({$0.isNumber(mayBePowered: true)}).termMix
        let chainValuesKeys = multChainTermMix.valuesKeys
        if fnCtrl.contains(.skipMergeSameBaseInSqrtIfHasNonRootable) && chainValuesKeys.dropRedundants.contains(where: { uniqueValueKeys in
            if chainValuesKeys.filter({$0 == uniqueValueKeys}).count < 2 {return true}
            let toMergeNodes = radicalParent.children.termMix.filter({$0.valueKeys == uniqueValueKeys})
            let nodeFreq = toMergeNodes.powerSum
            if indexValue != nodeFreq {return true}
            return false
        }) {return}
        let uniqueValuesKeys = chainValuesKeys.dropRedundants.filter({ uniqueValueKeys in
            if chainValuesKeys.filter({$0 == uniqueValueKeys}).count < 2 {return false}
            let toMergeNodes = radicalParent.children.termMix.filter({$0.valueKeys == uniqueValueKeys})
            let nodeFreq = toMergeNodes.powerSum
            if indexValue <= nodeFreq || [indexValue,nodeFreq].gcd != 1 {} else {return false}
            if !toMergeNodes.first!.isTerm && toMergeNodes.first!.dropPower(withParent: true).isRootable(indexValue: indexValue) && (indexValue == nodeFreq || [indexValue,nodeFreq].gcd == 1) {return false}
            return true
        })
        if uniqueValuesKeys.filter({!$0.contains(where: {$0.isTerm})}).isEmpty && multChain.count > 1 && !multChain.dropTerms.hasRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false) {return}
 
        //
        for uniqueValueKeys in uniqueValuesKeys {
        
            //
            let toMergeNodes = radicalParent.children.termMix.filter({$0.valueKeys == uniqueValueKeys})
            let nodeFreq = toMergeNodes.powerSum

            //
            if !toMergeNodes.hasPowered && indexValue > nodeFreq && indexValue.isMultiple(of: nodeFreq) && toMergeNodes.first!.isRootable(indexValue: (indexValue/nodeFreq).rounded()) {return}
            if nodeFreq != indexValue {
                radicalParent.pinRootExpr()
                reduceIndexWithPower(radicalParent: radicalParent, fnCtrl: fnCtrl + [.forceSkip], &steps)
                if radicalParent.pinnedRootDidChange {return}
            }
            multSameBase(nodes: toMergeNodes, fnCtrl: fnCtrl, &steps)
        }
    }
}
