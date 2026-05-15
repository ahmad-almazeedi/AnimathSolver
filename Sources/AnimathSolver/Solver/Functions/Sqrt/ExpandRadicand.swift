//
//  ExpandRadicand.swift
//  Hulul
//
//  Created by Ahmad on 10/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func expandSimplifiableRadicands(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        for node in radicalParent.children.dropFractions.termMix {
            if node.isPowered {
                expandSimplifiablePoweredRadicand(radicalParent: radicalParent, node: node, fnCtrl: fnCtrl, &steps)
            } else if !node.isTerm && node.isWholeNumber(mayBeCoeff: true) {
                if node.isRootable(indexValue: radicalParent.indexValue) {
                    if !radicalParent.indexIsTwo {
                        rewriteInExpnential(radicalParent: radicalParent, node: node, fnCtrl: fnCtrl, &steps)
                    }
                } else {
                    expandSimplifiableNonPoweredRadicand(radicalParent: radicalParent, node: node, fnCtrl: fnCtrl, &steps)
                }
            }
        }
    }
    
    private func rewriteInExpnential(radicalParent: StepNode, node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        let expoBaseDouble = pow(node.valueDouble, 1/radicalParent.indexSK.getDouble).rounded
        guard expoBaseDouble.isWholeNumber else {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        
        //
        steps.lastMarked = node.valueSK
        steps.lastExplanation = rewriteInExponentialExplanation
        
        //
        var resultValueSK = expoBaseDouble.newSKs
        resultValueSK.replaceSimilarKeys(similarKeys: node.valueSK)
        
        //
        node.valueSK = resultValueSK
        node.power = [StepNode(valueSK: radicalParent.indexSK.newSKs)]
        
        //
        steps.lastMarked.append(contentsOf: node.valueSKpow)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func expandSimplifiablePoweredRadicand(radicalParent: StepNode, node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if node.isPoweredByWholeNumber {} else {return}
        if node.isSqrt || node.isBrackets(.hasFraction(fractionCase: .any)) {return}
        if node.isVar && radicalParent.coeffNode.isEquation {return}
        let nodePowerInt = Int(node.powerValue)
        if nodePowerInt > radicalParent.indexInt {} else {return}
        if nodePowerInt.isMultiple(of: radicalParent.indexInt) {return}
        
        //
        steps.lastMarked = node.flatSKs
        steps.lastExplanation = "Rewrite the exponent as a sum where one of the addends is a multiple of the root index"
        
        // replace radicand with factors
        let firstFactorPowerValue = nodePowerInt-nodePowerInt%radicalParent.indexInt
        let secondFactorPowerValue = nodePowerInt-firstFactorPowerValue
        let originalPowerSKs = node.power.first!.valueSK
        node.power = [firstFactorPowerValue.newNode, secondFactorPowerValue.newNode]
        if originalPowerSKs.count == 2 && node.power.last!.valueSK.count == 1 {
            node.power.last!.valueSK.replaceSimilarKeys(similarKeys: [originalPowerSKs.last!])
        }
        steps.lastMarked.append(contentsOf: node.power.flatSKs)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if node.isTerm {
            node.baseNode.splitTermsAt(node)
        } else {
            node.extractTerms()
        }
        
        //
        steps.lastMarked = node.flatSKs
        steps.lastExplanation = "Use aᵐ⁺ⁿ = aᵐ × aⁿ to expand the expression"
        
        // replace radicand with factors
        var firstFactor = StepNode()
        var secondFactor = StepNode()
        if node.isSymb {
            let newOneNode = StepNode.newOneNode
            newOneNode.directSymbs = [node.clone(changeID: false, withParent: false), node.cloneWithChangedStaticIDs]
            firstFactor = newOneNode.directSymbs.first!
            secondFactor = newOneNode.directSymbs.last!
            node.coeffNode.insertAfter(newOneNode)
            newOneNode.op = node.coeffNode.op
            node.coeffNode.remove()
        } else {
            firstFactor.staticID = node.staticID
            firstFactor.staticIDForStepIncrement = node.staticIDForStepIncrement // didn't test very well, maybe should remove
            firstFactor.valueSK = node.valueSK
            secondFactor.valueSK = node.valueSK.newSKs
            if node.isBrackets {
                firstFactor.children = node.children
                secondFactor.children = node.cloneWithChangedStaticIDs.children
            }
            secondFactor.op = .times
            node.insertAfter(contentsOf: [firstFactor.baseNode, secondFactor.baseNode])
            firstFactor.op = node.op
            node.remove()
        }
        firstFactor.power = [node.power.first!]
        secondFactor.power = [node.power.last!]
        
        //
        steps.lastMarked.append(contentsOf: firstFactor.flatSKs+secondFactor.flatSKs)
        [firstFactor,secondFactor].replaceSimilarKeys(with: node.flatSKsNoPow.dropFirstIfOp, withPow: false)
        steps.lastStep.appendCloneIDs(originalKeysIDs: firstFactor.flatSKsNoPow.dropFirstIfOp.ids, clonesKeysIDs: [secondFactor.flatSKsNoPow.dropFirstIfOp.ids])
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        removePowerOne(node: secondFactor, fnCtrl: fnCtrl, &steps)
        
        //
        secondFactor.isTarget = true
    }
    
    func expandSimplifiableNonPoweredRadicand(radicalParent: StepNode, node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if node.isRootableIfMultiplied {return}
        if let radicalParentParent = radicalParent.coeffNode.parent, radicalParentParent.isSqrt && radicalParentParent.children.isMultChain && !radicalParentParent.children.hasRootableOrSimplifiable(indexValue: radicalParentParent.indexValue, isNotRootableIfMultiplied: true) {
            if !radicalParentParent.dontHaveRootableAndWillHaveRootableOrSimplifiable {return}
        }
        guard let twoFactors = node.valueSK.getInt.primeFactors.simplifyToTwoFactors(withIndex: radicalParent.indexSK.getInt) else {return}
        
        //
        node.extractTerms()
        
        //
        steps.lastMarked = node.flatSKs
        steps.lastExplanation = "Rewrite \(node.valueSK.strForExpl) as a product of two factors, where the root of one of them can be evaluated"
        
        // replace radicand with factors
        let firstFactor = StepNode(valueSK: twoFactors.0.newSKs)
        let secondFactor = StepNode(valueSK: twoFactors.1.newSKs).withOp(.times)
        node.insertAfter(contentsOf: [firstFactor, secondFactor])
        firstFactor.op = node.op
        node.remove()
        
        //
        steps.splitNodeIntoTwoNodes(node: node, split1: firstFactor, split2: secondFactor)
        
        //
        steps.lastMarked.append(contentsOf: firstFactor.flatSKs+secondFactor.flatSKs)

        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if !radicalParent.indexIsTwo {
            rewriteInExpnential(radicalParent: radicalParent, node: firstFactor, fnCtrl: fnCtrl, &steps)
        }
    }
}
