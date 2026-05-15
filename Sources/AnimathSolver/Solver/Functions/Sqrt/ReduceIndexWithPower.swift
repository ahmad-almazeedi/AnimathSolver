//
//  ReduceIndexWithPower.swift
//  Hulul
//
//  Created by Ahmad on 25/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func reduceIndexWithPower(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        //
        if radicalParent.exist {} else {return}
        if radicalParent.isPowered {return}
        if radicalParent.children.isMultChain && !(fnCtrl.contains(.forceSkip) && !radicalParent.children.termMix.hasPowered) {} else {return}
        let firstRadicand = radicalParent.children.first!
        if firstRadicand.isMinus && radicalParent.indexIsEven {return}
        if firstRadicand.hasDirectRadical {return}
        if !radicalParent.children.hasTerm && radicalParent.children.hasOnlyNumbers && radicalParent.children.count > 1 && radicalParent.children.nodesHaveEqualValues {return}
        if radicalParent.children.hasRepeatedSymbType {return}
        
        //
        let indexSK = radicalParent.indexSK
        var gcdValue: Double = 0
        var toConvertToExpoNodes = [StepNode]()
        var powerValues = [Double]()
        let multChain = firstRadicand.multChain(forward: false)
        let radicandIsSingleNode = radicalParent.children.isSingleNode
        for radicandNode in multChain {
            var targetedRadicand = radicandNode.baseOrTermNode
            if targetedRadicand.isNumber(mayBePowered: false) && !targetedRadicand.isTerm {
                if let expoForm = targetedRadicand.getExponentialForm {
                    targetedRadicand = expoForm
                }
            }
            //
            if targetedRadicand.isPoweredByPosWholeNumber {} else {return}
            let radicandPower = targetedRadicand.power
            let powerValue = radicandPower.valueDouble
            let indexValue = indexSK.getDouble
            if indexValue == powerValue || powerValue.isMultiple(of: indexValue) {return}
            gcdValue = [indexValue, powerValue].gcd
            if gcdValue == 1 {return}
            if radicandNode.directSymbs.hasPoweredByNotWholeNumber {return} // used to be called hasPoweredByNegOrNotWholeNumber although works the same
            if radicandIsSingleNode {
                if radicandNode.directSymbs.contains(where: {$0.powerValue == indexValue || $0.powerValue.isMultiple(of: indexValue) || [$0.powerValue, indexValue].gcd == 1}) {return}
            } else {
                if radicandNode.directSymbs.contains(where: {$0.powerValue >= indexValue || [$0.powerValue, indexValue].gcd == 1}) {return}
            }
            powerValues.append(contentsOf: [powerValue] + radicandNode.directSymbs.powerValues)
            if !radicandNode.valueIsOne && !radicandNode.isPowered {
                toConvertToExpoNodes.append(radicandNode)
            }
        }
        let minPowerValue = powerValues.min()!
        if multChain.contains(where: {$0.isPowered && $0.powerValue != minPowerValue}) {return}
        if toConvertToExpoNodes.isEmpty && !radicalParent.children.termMix.powerValues.allValuesAreEqual {return}
        
        //
        for node in toConvertToExpoNodes {
            representNodeAsPowered(to: minPowerValue.int, node: node, fnCtrl: fnCtrl, &steps)
        }
        guard radicalParent.children.termMix.powerValues.allValuesAreEqual else {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        
        //
        mergePowersOfProduct(node: firstRadicand, fnCtrl: fnCtrl, &steps)
        
        //
        var radicandPower = firstRadicand.baseOrTermNode.power
        if firstRadicand.isInBrackets {
            radicandPower = firstRadicand.parent!.power
        }
        
        //
        steps.lastMarked = indexSK + radicandPower.flatSKs
        steps.lastExplanation = "Reduce the index of the radical and exponent with \(String(Int(gcdValue)))"
        steps.lastStrikeKeys = [radicandPower.first!.strikeKey, indexSK.strikeKey]
        
        //
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        //
        radicalToExponent(radicalParent: radicalParent, fnCtrl: fnCtrl + [.force, .forceRemoveTimesFromTerms], &steps.lastStepSubsteps)
        
        //
        let newPoweredNode = radicalParent.nodeProduct!.baseOrTermNode
        reduceFraction(node: newPoweredNode.power.first!, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps.lastStepSubsteps)
        steps.lastMarked.append(contentsOf: newPoweredNode.power.first!.numeratorAndDenominator.flatSKs)
        
        //
        fractionPowerToRadical(node: newPoweredNode.power.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        removePowerOne(node: newPoweredNode, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func mergePowersOfProduct(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let baseOrTermNode = node.baseOrTermNode
        if !baseOrTermNode.isPowered {return}
        let powerValue = baseOrTermNode.power.valueDouble
        let multChain = node.multChain(forward: false)
        let multChainTermMix = multChain.termMix
        if multChainTermMix.count > 1 {} else {return}
        if multChainTermMix.contains(where: {$0.powerValue != powerValue}) {return}
        if multChain.hasBrackets({$0.count > 1}) {return}
        
        //
        let originalMultChain = multChain.clone(changeID: false, withParent: false).children

        //
        steps.lastMarked = multChainTermMix.map({$0.power.flatSKs}).flatMap({$0})
        steps.lastExplanation = "Use aⁿ bⁿ = (ab)ⁿ to rewrite the expression"
        
        //
        multChain.setBrackets(extrctOp: true)
        if let innerBrackets = multChain.first(where: {$0.isBrackets}) {
            node.parent!.valueSK = innerBrackets.valueSK
            steps.lastMarked.append(contentsOf: multChainTermMix.flatSKs)
        }
        steps.lastMarked.append(contentsOf: baseOrTermNode.parent!.valueSK)
        node.parent!.power = multChain.first!.baseOrTermNode.power
        
        //
        multChainTermMix.removePowers()
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: originalMultChain.first!.baseOrTermNode.power.flatSKs.ids, mergesKeysIDs: originalMultChain.symbMix.dropNode(node: originalMultChain.first!.baseOrTermNode).map({$0.power.flatSKs.ids}))
    }
    
    func convertToExponentialForm(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if node.isWholeNumber(mayBePowered: true, mayBeCoeff: true) {} else {return}
        guard let expoForm = node.getExponentialForm else {return}
        
        //
        steps.lastMarked = node.valueSK
        steps.lastExplanation = rewriteInExponentialExplanation
  
        //
        if node.isPowered {
            node.extractTerms()
            node.setBracketsAndExtractPower()
            steps.lastMarked.append(contentsOf: node.parent!.valueSK)
            node.content = expoForm.dropTerms.content
            node.op = .plus
        } else {
            node.content = expoForm.content
        }
        
        //
        steps.lastMarked.append(contentsOf: node.valueSKpow)

        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if node.isInBrackets {
            distributePowerIntoBrackets(node: node.parent!, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}
