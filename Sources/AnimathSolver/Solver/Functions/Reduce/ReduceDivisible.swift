//
//  ReduceDivisible.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func reduceFirstDivisibleNodes(numNode: StepNode, denChain: [StepNode], numToDen: Bool, fnCtrl: [FnCtrl], sameFraction: Bool, _ steps: inout [StepModel]) {
        
        // Conditions
        if numNode.isBrackets(.notSingle(mayBeFraction: false)) {return}
        var multNode = StepNode()
        var divNode = StepNode()
        if numToDen {
            guard let denNode = denChain.first(where: {numNode.isDividableBy(node: $0, mayEqual: false) && (!sameFraction || $0.isInSameFraction(with: numNode, shouldBeSingle: true))}) else {return}
            multNode = numNode
            divNode = denNode
        } else {
            guard let denNode = denChain.first(where: {$0.isDividableBy(node: numNode, mayEqual: false) && (!sameFraction || $0.isInSameFraction(with: numNode, shouldBeSingle: true))}) else {return}
            multNode = denNode
            divNode = numNode
        }
        if [multNode, divNode].allWholeOrAllDecimal || !(divNode.isInSameFraction(with: multNode, shouldBeSingle: true) && !numToDen) {} else {return}
        if fnCtrl.isCheckAllowed {numNode.root.changeContent(); return}
        numNode.numeratorMultChain(termMix: false).setSurfedToTrue()
        denChain.setSurfedToTrue()
        multNode.isReduced = true
        divNode.isReduced = true
        
        // Mark and strike and explain
        let shouldSayDivide = sameFraction && numToDen && numNode.parentFraction!.isFraction(.single(simplest: false, for: .all)) && !numNode.isCoeff && !divNode.isCoeff
        steps.lastMarked = multNode.dynamicValue + divNode.dynamicValue + (shouldSayDivide ? numNode.parentFraction!.valueSK : [])
        steps.lastExplanation = shouldSayDivide ? "Divide \(multNode.valueKeys.str) by \(divNode.valueKeys.str)" : "Cancel out the common factor \(divNode.valueSK.strForExpl)"
        steps.lastStrikeKeys = [multNode.strikeKey, divNode.strikeKey]
        
        // Divide
        multNode.dynamicValue = [multNode,divNode.withOpChangeID(op: .divide)].getResultNodeForHighOp(returnSymbs: false).dynamicValue
        divNode.removeInFraction(isTerm: false, markedKeys: &steps.lastMarked)
        
        // mark and append
        steps.lastMarked.append(contentsOf: multNode.dynamicValue)
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // remove times one
        if divNode.parent!.hasParent {
            removeHighOpOne(node: divNode.parent!.parent!, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}
