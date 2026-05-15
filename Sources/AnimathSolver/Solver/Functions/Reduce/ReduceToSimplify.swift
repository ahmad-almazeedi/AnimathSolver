//
//  ReduceToSimplify.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func reduceFirstToSimplifyNodes(numNode: StepNode, denChain: [StepNode], fnCtrl: [FnCtrl], sameFraction: Bool, _ steps: inout [StepModel]) {
        
        // Conditions
        if numNode.isPowered || numNode.isBrackets(.notSingle(mayBeFraction: true)) {return}
        guard let denNode = denChain.first(where: {!$0.isPowered && !$0.isBrackets(.notSingle(mayBeFraction: true)) && !numNode.hasEqualBase(with: $0) && [numNode,$0].getGCD != nil && (!sameFraction || $0.isInSameFraction(with: numNode, shouldBeSingle: true))}) else {return}
        let gcd = [numNode,denNode].getGCD!
        if Int(gcd.str!) == nil {return}
        if fnCtrl.isCheckAllowed {numNode.root.changeContent(); return}
        numNode.numeratorMultChain(termMix: false).setSurfedToTrue()
        denChain.setSurfedToTrue()
        numNode.isReduced = true
        denNode.isReduced = true
        
        // Mark and strike and explain
        steps.lastMarked = numNode.dynamicValue + denNode.dynamicValue
        steps.lastExplanation = "Cancel out the common factor \(Int(gcd))" // determineMarkedNodes() is depending on this string
        steps.lastStrikeKeys = [numNode.strikeKey, denNode.strikeKey]
        
        // set substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // set new div nodes
        let numDivider = gcd.newSKs.newNode.withOp(.divide)
        let denDivider = gcd.newSKs.newNode.withOp(.divide)

        // insert divNodes
        numNode.insertAfter(numDivider)
        denNode.insertAfter(denDivider)
        
        // mark and append
        steps.lastStepSubsteps.lastMarked.append(contentsOf: numDivider.opValueSK + denDivider.opValueSK)
        steps.lastStepSubsteps.lastExplanation = "Divide both \(numNode.valueSK.strForExpl) and \(denNode.valueSK.strForExpl) by their greatest common factor \(numDivider.valueSK.strForExpl)" // Duplicate warning
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)

        // mark and explain mult division
        steps.lastStepSubsteps.lastMarked.append(contentsOf: numNode.dynamicValue+numDivider.opValueSK)
        steps.lastStepSubsteps.lastExplanation = "Divide the numbers"
 
        // divide mult
        numNode.dynamicValue = [numNode,numDivider].getResultNodeForHighOp(returnSymbs: false).dynamicValue
        numDivider.remove()
 
        // mark and append step
        steps.lastStepSubsteps.lastMarked.append(contentsOf: numNode.dynamicValue)
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)

        // mark and explain div division
        steps.lastStepSubsteps.lastMarked.append(contentsOf: denNode.dynamicValue+denDivider.opValueSK)
        steps.lastStepSubsteps.lastExplanation = "Divide the numbers"

        // divide div
        denNode.dynamicValue = [denNode,denDivider].getResultNodeForHighOp(returnSymbs: false).dynamicValue
        denDivider.remove()
                
        // mark and append step
        steps.lastStepSubsteps.lastMarked.append(contentsOf: denNode.dynamicValue)
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        // append in main steps
        steps.lastMarked.append(contentsOf: numNode.dynamicValue+denNode.dynamicValue)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
