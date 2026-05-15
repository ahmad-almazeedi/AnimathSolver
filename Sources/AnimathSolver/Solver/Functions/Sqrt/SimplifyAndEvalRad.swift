//
//  SimplifyAndEvaluateRadicals.swift
//  Hulul
//
//  Created by Ahmad on 05/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func simplifyAndEvaluateRadicals(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.exist || fnCtrl.contains(.skipRadicalEval) {return}
        if node.hasDirectRadical {} else {return}
        if !fnCtrl.isForced && powerBothSidesAllowed(nodeL: node.root, nodeR: node.otherSide, dynamicSwap: true, fnCtrl: fnCtrl) {return}
        let radicalMultChain = node.multChain(forward: true).directRadicals
        if radicalMultChain.contains(where: {radicalParent in
            !radicalParent.children.isMultChainOrSimplestForm ||
            radicalParent.children.contains(where: {$0.isFraction && !($0.numerator.isMultChainOrSimplestForm && $0.denominator.isMultChainOrSimplestForm)}) ||
            radicalParent.children.contains(where: {$0.isDecimal || !$0.power.isSimplestForm}) ||
            radicalParent.children.hasDirectRadical({$0.children.areAllRootables(indexValue: $0.indexValue) || $0.children.hasSimplifiableWillBeRootableForParentSqrt}) && !radicalParent.isDoubleRadical ||
            radicalParent.children.isMinus && radicalParent.children.dropFirst.hasMinusFlatNoPow && !radicalParent.children.isSimplestFormMulti
        }) {return}
        
        //
        for radicalParent in radicalMultChain {
            if !fnCtrl.contains(.forceRadVarEval) && radicalParent.isRadVarInEqWithConditions {continue}
            simplifyAndEvaluateRadical(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        }
        
        //
        if !node.exist || node.isSurfed {return}
        let newRadicalMultChain = node.multChain(forward: false).directRadicals
        for radicalParent in newRadicalMultChain {
            mergeDoubleRadical(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        }
        mergeRadicalsWithDifferentIndices(radicals: newRadicalMultChain, fnCtrl: fnCtrl, &steps)
    }
        
    func simplifyAndEvaluateRadical(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
      
        //
        if fnCtrl.contains(.skipRadicalEval) {return}
        if !fnCtrl.isForced && radicalParent.isSurfed || !radicalParent.coeffNode.exist {return}
                
        // Powered Radical
        evaluatePow(node: radicalParent.coeffNode, fnCtrl: fnCtrl, &steps)
        extractIFromSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        factorPerfectSquareThenEvalOrSimpSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        nthRootTimesEqualNthRootNTimes(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        evaluateNthRootToTheNthPower(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        simplifyNthRootToTheMthPower(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        getPowerOutsideRadical(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        mergeDoubleRadical(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        
        // Split Fraction
        if !radicalParent.exist || !radicalParent.isSqrt {return}
        let rootableNodes = radicalParent.rootableOrSimplifiableNodes(indexValue: radicalParent.indexValue)
        let rootableFractions = rootableNodes.onlyFractions
        if !rootableFractions.isEmpty {
            splitRadicalContent(rootableNodes: rootableNodes, fnCtrl: fnCtrl, &steps)
            distributeRadicalsOnFractions(rootableNodes: rootableFractions, fnCtrl: fnCtrl, &steps)
        }
        
        // Simplify and evaluate
        evaluateNthPowerInNthRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        evaluateMultipleOfNthPowerInNthRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        mergeSameBaseInSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        evaluateRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        simplifyRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        surfAndApplyFnTillEnd(parent: radicalParent, surfFnCases: .reduce, fnCtrl: fnCtrl, &steps)
        simplifyMultipleRadicands(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        extractMinusFromRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        reduceIndexWithPower(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        simplifyExponentiablePoweredRadicand(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        mergeNonRadWithRad(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
    }
}
