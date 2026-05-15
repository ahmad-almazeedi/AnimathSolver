//
//  MergeRadicals.swift
//  Hulul
//
//  Created by Ahmad on 25/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func multRadicals(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if fnCtrl.contains(.skipSymbMultOrOrder) {return}
        if node.isNumber(mayBePowered: true) {} else {return}
        var timesDefaultChain = node.timesDefaultChain
        var allRadicalNodes = timesDefaultChain.directRadicals
        if allRadicalNodes.hasFraction(flat: true) {return}
        if allRadicalNodes.filter({$0.indexSK.keys == allRadicalNodes.first!.indexSK.keys}).count < 2 {return}
        if timesDefaultChain.first!.hasDirectRadical && !timesDefaultChain.first!.isOneRadical && timesDefaultChain.dropFirst.contains(where: {$0.hasDirectRadical && !$0.isOneTerm}) {return}
        if !fnCtrl.isForced && allRadicalNodes.contains(where: {!$0.children.isSimplestForm}) {return}
        timesDefaultChain.dropFirst.filter({!$0.isOneTerm}).splitAtEachRadical()
        timesDefaultChain = node.timesDefaultChain
        allRadicalNodes = timesDefaultChain.directRadicals
        let radicalNodes = allRadicalNodes.filter({$0.indexSK.keys == allRadicalNodes.first!.indexSK.keys})
        if radicalNodes.hasPowered {return}
        if radicalNodes.count < 2 {return}
        if radicalNodes.filter({$0.children.isMultChain}).contains(where: {radParent in radParent.children.withEachTermExtracted.dropOnes.contains(where: {$0.baseOrTermNode.isRootableOrSimplifiable(indexValue: radParent.indexValue, isNotRootableIfMultiplied: false)})}) {return}
        
        //
        node.pinRootExpr()
        nthRootTimesEqualNthRootNTimes(radicalParent: radicalNodes.first!, fnCtrl: fnCtrl + [.force], &steps)
        if node.pinnedRootDidChange {return}
        
        //
        var mainRadical = radicalNodes.first!
        let radsHasVarFlat = radicalNodes.hasVarFlat
        if let lastRadical = timesDefaultChain.last!.radicalParent, !(!radsHasVarFlat && radicalNodes.contains(where: {$0.coeffNode.hasVar})) && (lastRadical.isAfterSymbs || lastRadical.coeffNode.isOneSingleTerm) && lastRadical.hasSameIndex(with: radicalNodes.last!) && (!(radicalNodes.first!.coeffNode.isEqualTo(node: node) && radicalNodes.first!.coeffNode.isOneSingleTerm) || radsHasVarFlat) {
            mainRadical = radicalNodes.last!
        }
        
        // Compute Power first
        if node.isPowered {
            evaluatePow(node: node, fnCtrl: fnCtrl, &steps)
        }
        
        //
        let mainRadicalParent = mainRadical.parent!
        mergeRadicals(radicalNodes: radicalNodes, mainRadical: mainRadical, fnCtrl: fnCtrl, &steps)
        
        //
        surfAndEvaluate(parent: mainRadical.exist ? mainRadical : mainRadicalParent, fnCtrl: fnCtrl, &steps)
        
        // Redo for other symbs
        multRadicals(node: node, fnCtrl: fnCtrl, &steps)
    }
    
    func mergeRadicals(radicalNodes: [StepNode], mainRadical: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Mark and explain
        steps.lastMarked = radicalNodes.flatSKs
        let nthStr = mainRadical.indexInt == 2 ? "" : "ⁿ"
        let squareStr = mainRadical.indexInt == 2 ? "square " : ""
        steps.lastExplanation =  "Use \(nthStr)√a \(nthStr)√b = \(nthStr)√ab to multiply the \(squareStr)roots."
        steps.lastNote = "where: a ≥ 0, b ≥ 0"
        
        // join under same root
        if !radicalNodes.first!.children.isHighOpChain {
            radicalNodes.first!.children.setBrackets()
        }
        mainRadical.children = radicalNodes.first!.children + radicalNodes.dropFirst.map({($0.children.isPosHighOpChain ? $0.children : [$0.children.parenthesized]).withOp($0.coeffNode.op)}).flatMap({$0})
        
        // change op
        var newMainOp: StepKey?
        if mainRadical.isEqualTo(node: radicalNodes.last!) && radicalNodes.first!.coeffNode.isOneSingleTerm && !radicalNodes.first!.coeffNode.isTimes {
            newMainOp = radicalNodes.first!.coeffNode.op
        }
        
        // Remove radicals
        steps.lastMarked.append(contentsOf: mainRadical.children.flatSKs)
        var newMultChain = mainRadical.coeffNode.multChain(forward: false)
        radicalNodes.dropNode(node: mainRadical).removeNodesFromParent()
        mainRadical.coeffNode.multChain(forward: false).filter({$0.isOne}).removeNodesFromParent()
        newMultChain.removeAll(where: {!$0.exist})
        
        //
        if let newMainOp = newMainOp {
            if let firstNonRadical = newMultChain.first(where: {!$0.isOneSingleRadical}) {
                firstNonRadical.op = newMainOp
            } else {
                mainRadical.coeffNode.op = newMainOp
            }
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: mainRadical.opIndex.ids, mergesKeysIDs: radicalNodes.dropNode(node: mainRadical).map({$0.opIndex.ids}))
    }
}

extension CalcBrain {
    func mergeRadicalsWithDifferentIndices(radicals: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if radicals.isEmpty || radicals.isSurfed || !fnCtrl.contains(.forceMergeRadWithDiffIdx) && radicals.count < 2 || radicals.contains(where: {!$0.children.isSingleNode}) {return}
        if radicals.hasPowered {return}
        guard Set(radicals.map({$0.indexInt})).count == radicals.count else {return}
        guard radicals.map({$0.children.first!.baseOrTermNode}).nodesHaveEqualBaseIfExpo else {return}
        
        //
        let multChain = radicals.first!.coeffNode.multChain(forward: false)
        let firstNode = multChain.first!
        firstNode.pinRootExpr()
        multDefault(node: firstNode, fnCtrl: fnCtrl, &steps)
        if firstNode.pinnedRootDidChange {return}
        
        //
        for radical in radicals {
            radicalToExponent(radicalParent: radical, fnCtrl: fnCtrl, &steps)
        }
        
        //
        multiplySameBaseWithFractionAsPower(node: radicals.first!.nodeProduct!, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func multiplySameBaseWithFractionAsPower(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        guard node.exist else {return}
        let multChainMix = node.multChain(forward: false).symbMix
        if let selectedNode = multChainMix.first(where: {selectedNode in
            multChainMix.dropNode(node: selectedNode).contains(where: {!selectedNode.isBrackets({!$0.hasVarOrNotVarXFlat && $0.resultValue() < 0}) && selectedNode.hasEqualBaseIfExpo(with: $0) && $0.power.isPosSimplestFraction})
        }) {
            let toSimplifyPoweredsByFraction = multChainMix.filter({selectedNode.hasEqualBaseIfExpo(with: $0) && $0.power.isPosSimplestFraction})
            if toSimplifyPoweredsByFraction.isEmpty || fnCtrl.contains(.skipMergeSameBaseIfAlone) && toSimplifyPoweredsByFraction.count == 1 {return}
            node.pinRootExpr()
            simplifyPoweredsByFraction(nodes: toSimplifyPoweredsByFraction, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        } else if node.power.isPosSimplestFraction {
            simplifyPoweredsByFraction(nodes: [node], fnCtrl: fnCtrl, &steps)
            return
        }
                
        //
        guard let firstSameBase = multChainMix.first(where: {firstSameBase in multChainMix.dropNode(node: firstSameBase).contains(where: {firstSameBase.hasEqualBaseIfExpo(with: $0) && $0.power.isPosSimplestFraction})}) else {return}
        let multchainFltrd = multChainMix.filter({firstSameBase.hasEqualBaseIfExpo(with: $0) && $0.power.isPosSimplestFraction})
        if multchainFltrd.isEmpty {return}
        
        //
        if multchainFltrd.count > 1 {} else {return}
        
        //
        node.pinRootExpr()
        multDefault(node: node, fnCtrl: fnCtrl, &steps)
        if node.pinnedRootDidChange {return}

        //
        let firstBaseOrTerm = multchainFltrd.first!
        multchainFltrd.extractEachTerm()
        
        //
        steps.lastMarked = multchainFltrd.flatSKs(.dropOp)
        steps.lastExplanation = multTermsWithSameBaseExpl
        
        //
        firstBaseOrTerm.power = multchainFltrd.map({$0.power}).flatMap({$0})
        
        //
        multchainFltrd.dropFirst.removeNodesFromParent()
        firstBaseOrTerm.baseNode.multChain(forward: true).onlyOnes.removeNodesFromParent()
        
        // mark and append step
        steps.lastMarked.append(contentsOf: firstBaseOrTerm.power.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: firstBaseOrTerm.flatSKsNoPow.dropFirstIfOp.ids, mergesKeysIDs: multchainFltrd.dropFirst.map({$0.flatSKsNoPow.dropFirstIfOp.ids}))
        
        // Evaluate Addition
        fractionAddition(node: firstBaseOrTerm.power.first!, fnCtrl: fnCtrl + [.force, .forcePowerAddition], &steps)
        reduceFraction(node: firstBaseOrTerm.power.first!, fnCtrl: fnCtrl + [.force], &steps)
        removePowerOne(node: firstBaseOrTerm, fnCtrl: fnCtrl + [.force], &steps)
        
        //
        multiplySameBaseWithFractionAsPower(node: firstBaseOrTerm.baseNode, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func simplifyPoweredsByFraction(nodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let firstNode = nodes.first!
        if !firstNode.isNumber(mayBePowered: true) || firstNode.valueIsOne || firstNode.isTerm {return}
        
        
        firstNode.pinRootExpr()
        for node in nodes {
            if node.valueIsOne {
                steps.setToUnableToSolve(nodeL: nodes.root, nodeR: nodes.root.otherSide)
                return
            }
            let indexValue = node.power.first!.denominator.first!.valueDouble
            if pow(node.valueDouble, 1/indexValue).isWholeNumber {} else {continue}
            simplifyPoweredByFraction(node: node, indexValue: indexValue, fnCtrl: fnCtrl, &steps)
        }
        if firstNode.pinnedRootDidChange {return}
        
        //
        if nodes.count == 1 {
            guard let indexValue = firstNode.getExponentialForm?.powerValue else {return}
            if firstNode.power.first!.denominator.first!.valueSK.getInt.isMultiple(of: Int(indexValue)) {} else {return}
            simplifyPoweredByFraction(node: firstNode, indexValue: indexValue, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        var leastBaseNode = nodes.min(by: {$0.valueDouble < $1.valueDouble})!
        if nodes.dropNode(node: leastBaseNode).contains(where: {!$0.valueDouble.logBase(leastBaseNode.valueDouble).isWholeNumber}) {
            leastBaseNode = leastBaseNode.getExponentialForm!.valueSK.newNode
        }
        
        //
        for node in nodes {
            if node.valueDouble > leastBaseNode.valueDouble {
                let indexValue = node.valueDouble.logBase(leastBaseNode.valueDouble)
                simplifyPoweredByFraction(node: node, indexValue: indexValue, fnCtrl: fnCtrl, &steps)
            }
        }
    }
    private func simplifyPoweredByFraction(node: StepNode, indexValue: Double, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let sqrtResult = pow(node.valueDouble, 1/indexValue).rounded
        
        //
        node.extractTerms()
        node.setBracketsAndExtractPower()
                
        //
        steps.lastMarked = node.valueSK + node.parent!.valueSK
        steps.lastExplanation = rewriteInExponentialExplanation
        
        //
        var resultValueSK = sqrtResult.newSKs
        resultValueSK.replaceSimilarKeys(similarKeys: node.valueSK)
        
        //
        node.valueSK = resultValueSK
        node.power = [StepNode(valueSK: [indexValue.newSKs.first!])]
        
        //
        steps.lastMarked.append(contentsOf: node.flatSKs)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        node.nodeProduct = node.parent!
        
        //
        distributePowerIntoBrackets(node: node.parent!, fnCtrl: fnCtrl + [.force], &steps)
    }
}

extension CalcBrain {
    func mergeNonRadWithRad(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if radicalParent.exist {} else {return}
        if radicalParent.children.count == 1 && radicalParent.children.isSimplestFormNegletSimplifiableRadicand {} else {return}
        let firstRadicand = radicalParent.children.first!
        if firstRadicand.isMinus && firstRadicand.directVars.isEmpty {return}
        if firstRadicand.hasDirectRadical && !firstRadicand.isOneSingleTerm {} else {return}
        
        //
        firstRadicand.pinRootExpr()
        mergeDoubleRadical(radicalParent: firstRadicand.radicalParent!, fnCtrl: fnCtrl, &steps)
        simplifyRoot(radicalParent: firstRadicand.radicalParent!, fnCtrl: fnCtrl, &steps)
        if let childRadicalParent = firstRadicand.radicalParent!.children.first!.radicalParent {
            evaluateRoot(radicalParent: childRadicalParent, fnCtrl: fnCtrl, &steps)
        }
        if firstRadicand.pinnedRootDidChange {return}
        
        //
        let indexInt = firstRadicand.radicalParent!.indexInt
        firstRadicand.extractRadical()
        
        //
        steps.lastExplanation = "Use a = ⁿ√aⁿ to transform the expression"
        
        //
        if firstRadicand.shouldSetBrktIfPowered {
            firstRadicand.setSelfToBrackets()
        }
        
        //
        firstRadicand.baseOrTermNode.power = [indexInt.newNode]
        
        //
        let newOneRadical = StepNode.newOneNodeWithSqrt(indexSK: indexInt.newSKs)
        firstRadicand.replace(with: newOneRadical, withOp: true)
        newOneRadical.radicalParent!.children = [firstRadicand.withOp(.plus)]
        steps.lastMarked = newOneRadical.flatSKs
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        let multChainRadicals = newOneRadical.multChain(forward: false).directRadicals
        mergeRadicals(radicalNodes: multChainRadicals, mainRadical: multChainRadicals.first!, fnCtrl: fnCtrl + [.force], &steps)
        
        //
        surfAndEvaluateTillEnd(parent: multChainRadicals.first!, fnCtrl: fnCtrl + [.force, .skipRadicalEval, .skipRadicalSimplifying], &steps)
        
        //
        mergeDoubleRadical(radicalParent: radicalParent, fnCtrl: fnCtrl + [.force], &steps)
    }
}
