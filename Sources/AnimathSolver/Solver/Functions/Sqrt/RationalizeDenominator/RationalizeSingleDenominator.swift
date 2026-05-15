//
//  RationalizeDenominator.swift
//  Hulul
//
//  Created by Ahmad on 22/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func rationalizeSingleDenominator(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.exist || fnCtrl.contains(.skipRationalizeDen) {return}
        if !fnCtrl.isForced && node.isSurfed {return}
        if node.isFraction(.simplest(for: .numerator)) && node.denominator.count == 1 {} else {return}
        if !fnCtrl.contains(.forceRationalizeDen) && (node.isMultipliedOrDivided || node.isInFraction && !node.level!.isMultiNoHighOpChain || node.numerator.isFraction) {return}
        guard let radicalParent = node.denominator.first!.radicalParent else {return}
        if radicalParent.children.hasFraction(flat: true) {return}
        let indexValue = radicalParent.indexValue
        if radicalParent.children.hasRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false) {return}
        if node.isReducibleFraction {return}
        if willMultBothSides(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl + [.skipRationalizeDen]) {return}
        if fnCtrl.isCheckAllowed {node.changeContent(); return}
        
        //
        if let parent = node.parent, parent.isBrktsNotSqrt {
            node.pinRootExpr()
            distributePowerIntoFraction(node: parent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        transformToExpoToRationalizeDen(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        
        //
        let originalFraction = node.clone(changeID: false, withParent: false)
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Rationalize the denominator"
        steps.lastStep.shouldShowMainStep = true

        //
        steps.lastStepSubsteps = [steps.last!]
        
        //
        let newFraction = StepNode.newFractionNode.withOp(.times)
        newFraction.numerator = [.newOneNode.withRadical(radical: radicalParent.cloneWithChangedStaticIDs)]
        newFraction.denominator = [.newOneNode.withRadical(radical: radicalParent.cloneWithChangedStaticIDs)]
        if indexValue != 2 {
            var radicandPowerValue = 1.0
            if !radicalParent.children.isSingleNode && radicalParent.children.shouldSetBrktIfPowered {
                newFraction.numerator.first!.radicalParent!.children.setBrackets()
                newFraction.denominator.first!.radicalParent!.children.setBrackets()
            } else {
                radicandPowerValue = radicalParent.children.first!.baseOrTermNode.powerValue
            }
            let newPowerValue = indexValue-radicandPowerValue
            newFraction.numerator.first!.radicalParent!.children.first!.baseOrTermNode.power = [newPowerValue.newNode]
            newFraction.denominator.first!.radicalParent!.children.first!.baseOrTermNode.power = [newPowerValue.newNode]
            if newPowerValue == 1 {
                newFraction.numerator.first!.radicalParent!.children.first!.baseOrTermNode.removePower()
                newFraction.denominator.first!.radicalParent!.children.first!.baseOrTermNode.removePower()
            }
        }
        
        //
        steps.lastStepSubsteps.lastMarked = newFraction.flatSKs
        let newFractionClone = newFraction.clone(changeID: false, withParent: false)
        let radBrktsID = Int32.random
        if newFraction.numerator.first!.radicalParent!.children.isBrackets {
            newFractionClone.numerator.first!.radicalParent!.valueSK = newFractionClone.numerator.first!.radicalParent!.valueSK.map({$0.key.isBracket ? $0.withID(radBrktsID) : $0})
            newFractionClone.denominator.first!.radicalParent!.valueSK = newFractionClone.denominator.first!.radicalParent!.valueSK.map({$0.key.isBracket ? $0.withID(radBrktsID) : $0})
        }
        steps.lastStepSubsteps.lastExplanation = "Multiply the fraction by\n\(newFractionClone.flatSKs(.dropOp).filter({!$0.key.isCurlyBrkt && $0.id != radBrktsID}).strForExpl.withPaddedFractions)"
        
        //
        node.insertAfter(newFraction)
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        node.isTarget = true
        newFraction.isTarget = true
        mergeWithFraction(node: node, fnCtrl: fnCtrl + [.force, .forceMerge, .targetOnly], &steps.lastStepSubsteps)
        
        //
        if indexValue == 2 {
            nthRootTimesEqualNthRootNTimes(radicalParent: node.denominator.first!.radicalParent!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        } else {
            let denRadicals = node.denominator.directRadicals
            if denRadicals.count != 2 {
                steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
                return
            }
            denRadicals.last!.coeffNode.op.changeID()
            mergeRadicals(radicalNodes: denRadicals, mainRadical: denRadicals.first!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            let firstRadicand = node.denominator.first!.radicalParent!.children.first!
            if !firstRadicand.isSingleNode && firstRadicand.shouldSetBrktIfPowered {
                firstRadicand.setBrackets()
            }
            multSameBase(nodes: node.denominator.first!.radicalParent!.children.baseOrTermNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            evaluateNthPowerInNthRoot(radicalParent: node.denominator.first!.radicalParent!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        //
        let newNumRadParent = node.numerator.directRadicals.first(where: {$0.staticID == newFraction.numerator.first!.radicalParent!.staticID})!
        newNumRadParent.op = originalFraction.denominator.first!.radicalParent!.op
        steps.lastStep.appendCloneIDs(originalKeysIDs: originalFraction.denominator.first!.radicalParent!.children.flatSKs(.dropOp).ids, clonesKeysIDs: [newNumRadParent.childrenOrGrandChildren.flatSKs(.dropOp).ids])
        let origDenRadParent = originalFraction.denominator.first!.radicalParent!
        let origDenRadChildren = origDenRadParent.children
        let denNoPowIds = origDenRadChildren.flatSKsNoPow.dropFirstIfOp.ids
        if let numRadBrkts = newNumRadParent.children.first(where: {$0.isBrackets}) {
            steps.lastStep.appendCloneIDs(originalKeysIDs: [denNoPowIds.first!, denNoPowIds.last!], clonesKeysIDs: [numRadBrkts.valueSK.ids])
        } else if newNumRadParent.children.first!.baseOrTermNode.isPowered {
            if origDenRadChildren.first!.baseOrTermNode.isPowered {
                newNumRadParent.children.first!.baseOrTermNode.power.first!.valueSK[0].id = origDenRadChildren.first!.baseOrTermNode.power.first!.valueSK.last!.id
            } else {
                steps.lastStep.appendCloneIDs(originalKeysIDs: [denNoPowIds.last!], clonesKeysIDs: [[newNumRadParent.children.first!.baseOrTermNode.power.first!.valueSK.first!.id]])
            }
        }
        newNumRadParent.indexSK = origDenRadParent.indexSK
        steps.lastMarked.append(contentsOf: newFraction.flatSKs + node.denominator.dropFirst.getOps + newNumRadParent.flatSKs)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        multRadicals(node: node.numerator.first!, fnCtrl: fnCtrl + [.force], &steps)
    }
    
    private func transformToExpoToRationalizeDen(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if radicalParent.children.isWholeNumber(mayBeCoeff: false) {} else {return}
        let radicand = radicalParent.children.first!
        let indexValue = radicalParent.indexValue
        guard let exponentialNode = radicand.getExponentialForm else {return}
        let powerValue = exponentialNode.powerValue
        guard indexValue > powerValue else {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        
        //
        steps.lastMarked = radicand.flatSKs + exponentialNode.flatSKs
        steps.lastExplanation = rewriteInExponentialExplanation
        
        //
        exponentialNode.replaceSimilarKeys(with: radicand.flatSKs, withPow: false)
        radicand.content = exponentialNode.content
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func multSameBase(nodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if nodes.nodesHaveEqualBase && nodes.hasOnlyTimes {} else {return}
        let firstNode = nodes.first!
        
        //
        steps.lastMarked = nodes.flatSKsNoTerms(.dropOp)
        steps.lastExplanation = nodes.first!.isTerm ? calcProdExpl : multToExpFormExpl
        
        //
        steps.lastStepSubsteps = [steps.last!]
        
        // Mark and explain
        let nodesNotPowered = nodes.filter({!$0.isPowered})
        steps.lastStepSubsteps.lastMarked = nodesNotPowered.flatSKsNoTerms(.dropOp)
        steps.lastStepSubsteps.lastExplanation = setExponentToOneExplanation
        
        // Set power to one
        if !nodesNotPowered.isEmpty {
            for tmpNode in nodesNotPowered {
                tmpNode.power = [.newOneNode]
            }
            
            // Nextmark and append step
            steps.lastStepSubsteps.lastMarked.append(contentsOf: nodesNotPowered.flatSKsNoTerms(.dropOp))
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        }
        
        //
        steps.lastStepSubsteps.lastMarked = nodes.flatSKsNoTerms(.dropOp)
        steps.lastStepSubsteps.lastExplanation = multTermsWithSameBaseExpl
        
        //
        firstNode.power.append(contentsOf: nodes.dropFirst.map({$0.power}).flatMap({$0}))
        if !nodes.first!.isTerm {nodes.extractTermsFromEachCoeff()}
        let baseNodes = nodes.baseNodes.dropRedundants(ignoreOp: false)
        nodes.dropFirst.removeNodesFromParent()
        baseNodes.onlyOnes.removeNodesFromParent()
        steps.lastStepSubsteps.lastMarked.append(contentsOf: firstNode.power.flatSKs)

        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        steps.lastStepSubsteps.appendMergeIDs(originalKeysIDs: firstNode.valueSK.ids, mergesKeysIDs: nodes.dropFirst.map({$0.valueSK.ids}))
        if firstNode.hasChild {
            steps.lastStepSubsteps.appendMergeIDs(originalKeysIDs: firstNode.children.flatSKsNoTerms(.any).ids, mergesKeysIDs: nodes.dropFirst.map({$0.children.flatSKsNoTerms(.any).ids}))
        }
        
        // Evaluate Addition
        evaluateAddition(node: firstNode.power.first!, fnCtrl: fnCtrl + [.force, .forcePowerAddition, .skipFlattenning], &steps.lastStepSubsteps)
        
        //
        steps.lastMarked.append(contentsOf: firstNode.power.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: firstNode.valueSK.ids, mergesKeysIDs: nodes.dropFirst.map({$0.valueSK.ids}))
    }
}
