//
//  RemoveOne.swift
//  Hulul
//
//  Created by Ahmad on 22/05/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func removeHighOpOne(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        removeOneTerm(node: node, fnCtrl: fnCtrl, &steps)
        removeDenominatorIfOne(node: node, fnCtrl: fnCtrl, &steps)
        removeOneTimesBracket(node: node, fnCtrl: fnCtrl, &steps)
        removeTimesOne(node: node, fnCtrl: fnCtrl, &steps)
        removeOneTimes(node: node, fnCtrl: fnCtrl, &steps)
        removeOnePowered(node: node, fnCtrl: fnCtrl, &steps)
        removePowerOne(node: node, fnCtrl: fnCtrl, &steps)
        removeRadicalOneOrZero(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    
    func removeOneTerm(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isOneTerm && node.showOneTerm {} else {return}
        
        //
        removeOnePowered(node: node, fnCtrl: fnCtrl, &steps)
        
        // Switch showOneTerm false
        node.showOneTerm = false
        
        // Mark and explain
        let shouldMergeTermWithPrev = node.shouldMergeTermWithPrev
        steps.lastMarked = [node.firstValueSK] + (shouldMergeTermWithPrev ? [node.op] : [])
        let isOneSingleVar = !shouldMergeTermWithPrev && node.hasVar && node.hasSingleSymb
        steps.lastExplanation = isOneSingleVar ? "When a term has a coefficient of 1, it doesn't have to be written" : "Any expression multiplied by 1 remains the same"
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
    }
    func removeOneTimesBracket(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist || fnCtrl.contains(.skipRemoveOneTimesBrkt) {return}
        if node.isOneTimesBracket && node.next.isBrackets(.complete) && node.next.noHighOpAfter {} else {return} // removed the condition of inBrktIsPlus for a reason
        
        // Mark and Explain
        if !fnCtrl.isSkipAppendStep {
            steps.lastMarked = node.opValueSK(node.next.children.isPlus ? .dropOp : .any) + (node.next.noHighOpAfter ? node.next.opValueSK : [])
            steps.lastExplanation = "Any expression multiplied by 1 remains the same"
        }
        
        // Remove
        node.next.op = node.op
        node.next.justRemoveBrackets()
        node.remove()
        
        // Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func removeTimesOne(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist || fnCtrl.contains(.skipRemoveTimesOne) {return}
        if node.prev.isBrackets(.any) && fnCtrl.contains(.skipRemoveOneTimesBrkt) {return}
        if node.isPowered {return}
        if node.isOne(opCase: .timesOrDivide) {} else {return}
        
        //
        removeTimesOne(node: node.next, fnCtrl: fnCtrl, &steps)
        
        // Mark and explain
        if !fnCtrl.isSkipAppendStep {
            steps.lastMarked = node.opValueSK
            let numberOrExprStr = node.prev.isNumberNotPoweredNotCoeff ? "number" : "expression"
            let opTitle = node.isDivide ? "divided" : "multiplied"
            steps.lastExplanation = "Any \(numberOrExprStr) \(opTitle) by 1 remains the same"
        }
        
        // Remove
        node.remove()
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func removeOneTimes(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isPowered {return}
        if node.isOne(opCase: .plusOrMinus) && node.next.isTimes && !(node.next.isBrackets(.complete) && fnCtrl.contains(.skipRemoveOneTimesBrkt)) {} else {return}

        //
        removeTimesOne(node: node.next, fnCtrl: fnCtrl, &steps)
        if !node.next.isTimes {return}
        
        //
        determineChainSignTillEnd(node: node, fnCtrl: fnCtrl + [.skipRemoveTimesFromTerms], &steps)
        
        // Mark and explain
        if !fnCtrl.isSkipAppendStep {
            steps.lastMarked = node.valueSK + [node.next.op]
            let numberOrExprStr =
            node.next.isNumberNotPoweredNotCoeff ? "number" : "expression"
            steps.lastExplanation = "Any \(numberOrExprStr) multiplied by 1 remains the same"
        }
        
        // Remove
        node.next.op = node.op
        node.remove()
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func removePowerOne(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isPowered && node.isPoweredByOne {} else {return}
        
        // Mark and explain
        if !fnCtrl.isSkipAppendStep {
            steps.lastMarked = node.power.flatSKs
            if node.isBrackets && node.dropPower(withParent: true).mayRemoveBrackets {
                steps.lastMarked.append(contentsOf: node.valueSK)
            }
            let numberOrExprStr = !node.isSymb && !node.isBrackets ? "number" : "expression"
            steps.lastExplanation = "Any \(numberOrExprStr) raised to the power of 1 remains the same"
        }
        
        // remove power
        node.removePower()
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func removeOnePowered(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        guard node.valueIsOne && node.isPowered else {return}
        
        // Mark and explain
        if !fnCtrl.isSkipAppendStep {
            steps.lastMarked = node.power.flatSKs
            steps.lastExplanation = "1 raised to any power equals 1"
        }
        
        // set power to one
        node.removePower()
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func removeDenominatorIfOne(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isFraction && node.denominator.isOne(opCase: .plus) {} else {return}
        
        // Mark and explain
        if !fnCtrl.isSkipAppendStep {
            steps.lastMarked = node.valueSK + node.denominator.flatSKs
            let numberOrExprStr = node.numerator.count == 1 && node.numerator.first!.isNumberNotPoweredNotCoeff ? "number" : "expression"
            steps.lastExplanation = "Any \(numberOrExprStr) divided by 1 remains the same"
        }
        
        // Remove denominatorn
        node.removeDenominator()
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func removeRadicalOneOrZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        guard let radicalParent = node.radicalParent else {return}
        if radicalParent.isPowered {return}
        if radicalParent.children.isOne(opCase: .plus) || radicalParent.children.isZero(opCase: .plus) {} else {return}
        
        //
        steps.lastMarked = radicalParent.flatSKs + (node.isOneRadical && node.isTimes ? [node.op] : [])
        let inRadicalValueSK = radicalParent.children.first!.valueSK
        steps.lastExplanation = "Any root of \(inRadicalValueSK.strForExpl) equals \(inRadicalValueSK.strForExpl)"
        
        //
        if !node.isOneRadical {
            node.extractRadicalAndAfter()
            steps.lastMarked.append(radicalParent.parent!.op)
        }
        
        //
        radicalParent.parent!.valueSK = inRadicalValueSK
        var shouldShowOneTerm = false
        if inRadicalValueSK.keys != [.zero] && radicalParent.parent!.hasDirectSymbs {
            shouldShowOneTerm = true
        }
        
        //
        radicalParent.remove()
        if shouldShowOneTerm {
            radicalParent.parent!.showOneTerm = true
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
