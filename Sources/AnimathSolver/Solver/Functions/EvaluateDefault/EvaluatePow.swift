//
//  EvaluatePow.swift
//  Hulul
//
//  Created by Ahmad on 25/07/2021.
//  Copyright © 2021 Ahmad. =All rights reserved.
//

import Foundation

extension CalcBrain {    
    func evaluatePow(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist || fnCtrl.contains(.skipPow) && !fnCtrl.contains(.semiForceEvalPow) {return}
        if node.isTerm || node.isDivide || node.isBrackets {return}
        if !node.isDecimal && node.isPoweredByWholeNumber && !node.power.isMinus {} else {return}
        if node.powerValue == 0 {return}
        if fnCtrl.isForced {} else {
            if node.isSurfed {return}
            if let radicalParent = node.parent, radicalParent.isSqrt {
                if node.level!.isMultChain && node.isRootableOrSimplifiable(indexValue: radicalParent.indexValue, isNotRootableIfMultiplied: false) {return}
                if radicalParent.coeffNode.isInDenominator && rationalizeDenominatorAllowed(node: radicalParent.parentFractionGeneral!, fnCtrl: fnCtrl) {return}
                let radicalMultChain = radicalParent.coeffNode.multChain(forward: false).directRadicals
                node.pinRootExpr()
                mergeRadicalsWithDifferentIndices(radicals: radicalMultChain, fnCtrl: fnCtrl, &steps)
                if node.pinnedRootDidChange {return}
            }
            if node.isInBrackets && !node.parent!.isSqrt && node.parent!.isPowered && node.isAlone {return} // consider this: 7/(7^2 * x)^2
            if node.isInDividedMultChain {return}
            if node.parent!.isDivide && node.level!.isMultChain {return}
            if let parentFraction = node.parentFraction {
                if parentFraction.isInBrackets && parentFraction.parent!.isPowered {return}
                if parentFraction.isFraction(.hasBrackets(.notSimplest, for: .any)) {return}
                if parentFraction.isInDividedMultChain {return}
                if willBeReducible(node: parentFraction, fnCtrl: fnCtrl + [.skipPow]) {return}
            }
            let multChain = node.multChain(forward: false)
            if !multChain.isEmpty && willBeReducible(node: multChain.first!, fnCtrl: fnCtrl + [.skipPow]) {return}
            let baseMultChain = node.parentFraction?.multChain(forward: false) ?? multChain
            if (baseMultChain.numeratorChain+baseMultChain.denominatorChain).hasNegPower {return}
        }
        if !fnCtrl.contains(.semiForceEvalPow) && willRootBothSides(nodeL: node.root, nodeR: node.otherSide, targetNode: node, fnCtrl: fnCtrl) {return}

        //
        if node.isInBrackets && node.parent!.isBrackets(.single(mayBePowered: true)) {
            if removeBracketsAllowed(node: node.parent!, fnCtrl: fnCtrl) {return}
        } else if node.valueIsOne {
            removeOnePowered(node: node, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        if let radicalParent = node.parent, radicalParent.isSqrt {
            node.pinRootExpr()
            simplifyExponentiablePoweredRadicand(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
            node.pinRootExpr()
            simplifyMultipleRadicands(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        }
        
        // Error if big power
        let tmpPowerValue = node.powerValue
        if !tmpPowerValue.isWholeNumber {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide.root)
            return
        } else if (Int(tmpPowerValue) + node.valueKeys.split(separator: .dot).first!.count) > 12 {
            let calcBrain = CalcBrain()
            let resultDouble = calcBrain.getResultByExecute(exprKeys: node.valueSKpow.keys, precision: 20)
            if resultDouble.isInfinite {
                steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide.root)
                return
            } else if resultDouble.count > 19 {
                steps[0].note = "..."
                return
            }
        }
        
        // Preserve to replace with result IDs
        let baseValueSK = node.dynamicNode.valueSK
                
        // Mark and explain
        steps.lastMarked = node.dynamicNode.flatSKsNoTerms(.dropOp)
        steps.lastExplanation = "Evaluate the power" // determineMarkedNodes() is depending on this string
        
        // set substeps
        steps.lastStepSubsteps = [steps.last!]
        
        // mark and explain
        steps.lastStepSubsteps.lastMarked = node.dynamicNode.valueSKpow
        steps.lastStepSubsteps.lastExplanation = "\(node.dynamicNode.valueSKpow.stringWithSinglePower) means \(node.dynamicNode.valueSK.strForExpl) is multiplied by itself \(node.dynamicNode.power.first!.valueSK.strForExpl) times"
        
        // append multiples
        let dynamicNode = node.dynamicNode
        let powerValue = dynamicNode.power.first!.valueSK.getInt
        for i in 0..<powerValue-1 {
            let multNode = dynamicNode.clone(changeID: true, withParent: true).withOp(.times)
            steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: dynamicNode.valueSK.ids, clonesKeysIDs: [multNode.valueSK.ids])
            steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [dynamicNode.valueSK.first!.id], clonesKeysIDs: [[multNode.op.id]])
            if multNode.isNumber(mayBePowered: true) {
                multNode.removeSymbs()
            }
            multNode.removePower()
            steps.lastStepSubsteps.lastMarked.append(contentsOf: multNode.flatSKs(.any))
            multNode.isTarget = true
            dynamicNode.insertAfter(multNode)
            if i == 0 && dynamicNode.isCoeff {
                if let radicalParent = dynamicNode.radicalParent {
                    multNode.radicalParent = radicalParent
                    dynamicNode.removeRadical()
                }
                multNode.directSymbs = dynamicNode.directSymbs
                dynamicNode.removeSymbs()
            }
        }
        dynamicNode.isTarget = true
        dynamicNode.removePower()

        // Append step
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.keepTargets])
        
        // evaluate mult
        determineChainSign(node: dynamicNode, fnCtrl: fnCtrl + [.force, .targetOnly, .keepTargets], &steps.lastStepSubsteps)
        multDefault(node: dynamicNode, fnCtrl: fnCtrl + [.force, .skipSymbMultOrOrder, .targetOnly, .keepTargets], &steps.lastStepSubsteps)

        // Animate
        dynamicNode.valueSK.replaceSimilarKeys(similarKeys: baseValueSK)
        
        // append to main step
        steps.lastMarked.append(contentsOf: dynamicNode.valueSK)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

