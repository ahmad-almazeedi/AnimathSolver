//
//  MultBothSidesByFraction.swift
//  Hulul
//
//  Created by Ahmad on 11/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func multBothSidesByFraction(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if fnCtrl.isCheckAllowed && nodeL.children.first!.isCommaNode {return}
        var mainSide = nodeL
        var otherSide = nodeR
        if nodeL.children.isSingleFractionWithX && !nodeR.children.hasVar && nodeR.children.isSimplestFormNegletTimesBracket {} else {
            if nodeR.children.isSingleFractionWithX && !nodeL.hasVar && nodeL.children.isSimplestFormNegletTimesBracket {
                mainSide = nodeR
                otherSide = nodeL
            } else {return}
        }
        let fractionNode = mainSide.children.first(where: {$0.isFraction})!
        // Check if reducible
        fractionNode.changeStaticIDWithChildren()
        let flippedFraction = fractionNode.flippedFraction.dropVarAndRadVar(dropNotVarX: false)
        let checkNodeRoot = StepNode()
        let otherSideNodeClone = otherSide.children.getParenthesizedCloneOrFirst()
        checkNodeRoot.children = [flippedFraction.withOp(.plus), otherSideNodeClone.withOp(.times)]
        if fractionNode.isMultipliedByBracketsOnly && otherSide.children.isMulti {return}
        if otherSide.containsVar && willHaveFractionAfterReduce(node: checkNodeRoot.children.first!, fnCtrl: []) {return}
        if otherSide.children.isDecimal || isReducibleAfterDetermineMinus(node: checkNodeRoot.children.first!, fnCtrl: []) {} else {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}

        // Mark and explain
        steps.lastMarked = flippedFraction.flatSKs
        steps.lastExplanation = "Multiply both sides by the reciprocal of the fraction"

        // Set
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Append Multipliers
        if otherSide.children.isMinus && otherSide.children.count == 1 || otherSide.isLeft && !flippedFraction.isMinus {
            appendHighOpOnBothSides(opNodes: [flippedFraction], highOp: .times, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        } else {
            insertMultiplierAtFirstOnBothSides(multNodes: [flippedFraction], nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // Reduce main side
        surfAndEvaluateAndApplyFnTillEnd(parent: mainSide, fnCtrl: [.forceReduce, .skipReduceToSimplify], &steps.lastStepSubsteps)
        determineChainSign(node: otherSide.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        
        // Set multNode from the other side
        let flippedFractionRHS = otherSide.flatTree.first(where: {$0.staticID == flippedFraction.staticID})!
       
        // more marking
        steps.lastMarked.append(otherSide.children.flatSKs(.any).first(where: {$0.key.isTimes})!)
        
        // change IDs to animate
        flippedFractionRHS.valueSK = flippedFraction.valueSK
        for i in 0..<flippedFractionRHS.numerator.count {
            flippedFractionRHS.numerator[i].content = flippedFraction.numerator[i].content
        }
        for i in 0..<flippedFractionRHS.denominator.count {
            flippedFractionRHS.denominator[i].content = flippedFraction.denominator[i].content
        }
        if flippedFractionRHS.isMinus {
            flippedFractionRHS.op = flippedFraction.isMinus ? flippedFraction.op : flippedFraction.numerator.isMinus ? flippedFraction.numerator.op : flippedFraction.denominator.isMinus ? flippedFraction.denominator.op : flippedFraction.op
        }
        flippedFractionRHS.numerator.first!.op = .plus
        flippedFractionRHS.denominator.first!.op = .plus
        
        // Append main step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension Array where Element == StepNode {
    var isSinglePosFractionWithX: Bool {
        if count == 1 || count == 2 && isSimplestFormWithFractionTimesBracket {} else {return false}
        if let fractionNode = first(where: {$0.isFraction(.singlePositiveNumber(mayBePowered: false, mayHaveCoeff: true, for: .numerator)) }) {
            if fractionNode.numerator.first!.valueIsOne {return false}
            return fractionNode.numerator.hasVar || count > 1
        }
        return false
    }
    var isSingleFractionWithX: Bool {
        if count == 1 || count == 2 && isSimplestFormWithFractionTimesBracket {} else {return false}
        if let fractionNode = first(where: {$0.isFraction(.single(simplest: true, for: .numerator)) }) {
            if fractionNode.numerator.first!.valueIsOne {return false}
            return fractionNode.numerator.hasVar || count > 1 && first(where: {$0.isBrackets})!.hasVar
        }
        return false
    }
    var isSinglePosFractionOrNumber: Bool {
        isSingle(mayBeFraction: true, fractionCase: .singlePositiveNumber(mayBePowered: false, mayHaveCoeff: true, for: .numerator), mayBePowered: false)
    }
}
