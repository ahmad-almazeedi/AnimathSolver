//
//  DecimalToFraction.swift
//  Hulul
//
//  Created by Ahmad on 19/05/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func convertDecimalsInFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isDivide {return}
        if node.isFraction(.single(simplest: false, for: .all)) {} else {return}
        if !node.numeratorAndDenominator.hasPoweredFlat && node.numeratorAndDenominator.hasDecimal {} else {return}
        if isReducible(node: node.multChainFirst, fnCtrl: fnCtrl) {return}
        
        //
        if node.isEquation && node.numerator.count == 1 && node.numerator.first!.valueIsOne && node.denominator.isDecimal {
            node.pinRootExpr()
            multBothSidesSinglebyLCM(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl + [.force], &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        let nodeClone = node.clone(changeID: false, withParent: false)
        
        //
        if node.children.hasFraction(flat: true) {
            convertDecimalsInFractionToFractions(node: node, fnCtrl: fnCtrl + [.force, .forceConvertDecimalToFraction], &steps)
            return
        }
        
        //
        multNumDenToGetRidOfDecimals(node: node, fnCtrl: fnCtrl + [.force], &steps)

        //
        if !nodeClone.numeratorAndDenominator.hasOnlyDecimals && isReducible(node: node, fnCtrl: fnCtrl) {
            node.content = nodeClone.content
            steps.removeLast()
            steps.lastStepSubsteps.removeAll()
            convertDecimalsInFractionToFractions(node: node, fnCtrl: fnCtrl + [.force, .forceConvertDecimalToFraction], &steps)
        }
    }
}

extension CalcBrain {
    func multNumDenToGetRidOfDecimals(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Mark and Explain
        steps.lastMarked = node.numeratorAndDenominator.flatSKs
        let toBeMultNode = node.numerator.first!.afterDotCount > node.denominator.first!.afterDotCount ? node.numerator.first! : node.denominator.first!
        let multNode = toBeMultNode.tenPoweredToDecimalCount
        steps.lastExplanation = "Multiply both the numerator and the denominator by \(multNode.valueSK.strForExpl) to get rid of the decimals"

        // Substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]

        //
        multiplyFractionNumDen(fractionNode: node, multNode: multNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // mark new keys
        steps.lastMarked.append(contentsOf: node.numeratorAndDenominator.flatSKs)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    func convertDecimalsInFractionToFractions(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
       
        // Convert decimals to fractions
        convertDecimalToFraction(node: node.numerator.first!, fnCtrl: fnCtrl + [.force], &steps)
        convertDecimalToFraction(node: node.denominator.first!, fnCtrl: fnCtrl + [.force], &steps)
        
        // Get out the fractions
        convertNestedFractionIntoMainFractions(node: node, fnCtrl: fnCtrl + [.force], &steps)
    }
    func convertDecimalToFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isDecimal && (fnCtrl.contains(.forceConvertDecimalToFraction) || node.isPowered || node.isDivide || !(node.isInFraction && node.isAlone) || node.isInFraction && node.isAlone && node.otherPartOfTheFraction.isMulti) {} else {return}
        let multChain = node.multChain(forward: false)
        if fnCtrl.isForced || (node.isPowerer || node.parent!.isSqrt) && node.isAlone || node.isDivide && !(node.prev.isDecimal && node.prev.isPlusOrMinus) || node.isPowered || node.isInDividedMultChain && ![node.multChainDivider].contains(where: {multChain.count == 1 && $0.isDecimal || $0.isFraction && $0.numerator.isOne(opCase: .any)}) || node.isInMultChain && multChain.hasFraction(flat: false) || node.isInSimplestFraction {} else {return}
        if fnCtrl.isForced && fnCtrl.contains(.moreCertainForceConvertDecimalToFraction) {} else {
            if !node.isDivide && cancelDivWithMultAllowed(node: multChain.first!, fnCtrl: fnCtrl) {return}
            if node.isDivide && !node.prev.isDivide && cancelDivWithMultAllowed(node: node.prev.multChainFirst, fnCtrl: fnCtrl) {return}
            if !(node.isInFraction && node.parentFraction!.numeratorAndDenominator.hasFraction(flat: true)) && !node.otherSide.isEmpty && !xMultAllowed(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl) && !(node.isInFraction && node.valueKeys.count == 3 && isReducible(node: node.dotRemoved.parentFraction!, fnCtrl: fnCtrl)) && multBothSidesAllowed(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl) {return}
        }
        
        //
        determineChainSign(node: node, fnCtrl: fnCtrl, &steps)
        if let radicalParent = node.parent, radicalParent.isSqrt {
            extractMinusFromRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            node.pinRootExpr()
            evaluateNthPowerInNthRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
            if node.isEquation {
                node.pinRootExpr()
                powerBothSides(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl, &steps)
                if node.pinnedRootDidChange {return}
            }
        }
        
        // set divNode
        var divNode = StepNode()
        if node.isInDividedMultChain {
            divNode = node.multChainDivider
        }
        
        //
        multSameBase(node: node, fnCtrl: fnCtrl, &steps)
        
        // Mark and Explain
        steps.lastMarked = node.valueSK
        steps.lastExplanation = "Convert the decimal to a fraction"
        
        // Substeps
        steps.lastStepSubsteps = [steps.last!]
        
        // Set mult node
        let multNode = node.tenPoweredToDecimalCount
        
        // Parenthesize if powered
        if node.isPowered {
            if node.isCoeff {
                node.extractTerms()
            }
            node.setBrackets()
            node.parent!.power = node.power
            node.removePower()
            steps.lastMarked.append(contentsOf: node.parent!.valueSK)
            steps.lastStepSubsteps.lastMarked = node.parent!.valueSK
            node.parent!.op = node.op
            node.op = .plus
        }
        
        // Just convert to fraction
        convertNodeToFractionAndSetDenominatorToOne(node: node, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
                
        // Mult numerator and denominator
        multiplyFractionNumDen(fractionNode: node, multNode: multNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // reduce to simplify
        reduceFirstToSimplifyNodes(numNode: node.numerator.first!, denChain: node.denominator, fnCtrl: fnCtrl + [.skipFlattenning], sameFraction: true, &steps.lastStepSubsteps)
        
        // Append main step
        steps.lastMarked.append(contentsOf: node.flatSKs(.dropOp))
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Flip
        flipFraction(node: node, fnCtrl: fnCtrl, &steps)
        
        // covert divNode
        if !divNode.isEmpty {
            convertDecimalToFraction(node: divNode, fnCtrl: fnCtrl + [.force, .forceConvertToDecimal], &steps)
        }
    }
}

extension CalcBrain {
    func multiplyFractionNumDen(fractionNode: StepNode, multNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
       
        // insert mult
        if fractionNode.numerator.count > 1 {
            fractionNode.numerator.setBrackets()
        }
        fractionNode.numerator.append(multNode.clone(changeID: true, withParent: false).withOp(.times))
        if fractionNode.denominator.count > 1 {
            fractionNode.denominator.setBrackets()
        }
        fractionNode.denominator.append(multNode.clone(changeID: true, withParent: false).withOp(.times))
        
        // Mark and explain
        let isDecimal = fractionNode.numerator.hasDecimal
        let isPluralDecimal = fractionNode.denominator.hasDecimal
        steps.lastMarked.append(contentsOf: fractionNode.numerator.last!.opValueSK + fractionNode.denominator.last!.opValueSK)
        steps.lastExplanation = "Multiply both the numerator and the denominator by \(multNode.valueSK.strForExpl)" + (isDecimal ? " to get rid of the decimal\(isPluralDecimal ? "s" : "")" : "")
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Evaluate
        if fractionNode.numerator.first!.isBrackets(.any) {
            distributeMultiplier(node: fractionNode.numerator.first!, fnCtrl: fnCtrl + [.force, .forceDistribute], &steps)
        } else {
            evaluateMult(node: fractionNode.numerator.first!, fnCtrl: fnCtrl + [.force], &steps)
        }
        if fractionNode.denominator.first!.isBrackets(.any) {
            distributeMultiplier(node: fractionNode.denominator.first!, fnCtrl: fnCtrl + [.force, .forceDistribute], &steps)
        } else {
            evaluateMult(node: fractionNode.denominator.first!, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}
