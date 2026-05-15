//
//  NestedFraction.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func convertNestedFractionIntoMainFractions(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !fnCtrl.contains(.forceConvertNestedFraction) {
            surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: .removeHighOpOne, &steps)
        }
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isFraction(part: .all, {!$0.isBrackets(.powered) && ($0.count == 1 && (!$0.isFraction || $0.first!.isFraction(part: .all, {$0.isMultChainOrSimplestForm})) || $0.isMultChain && !$0.hasFraction(flat: true) || $0.isSimplestForm)}) && !node.isDivide {} else {return}
        if node.numerator.isDecimal && !node.denominator.flatTree.hasDecimal || node.denominator.isDecimal && !node.numerator.flatTree.hasDecimal {return}
        if node.numerator.isFraction || node.denominator.isFraction {} else {return}
        if !fnCtrl.contains(.forceConvertNestedFraction) && (node.numOrDenIsFractionDividable || isNestedFractionReducibleAfterDetermineMinus(node: node, fnCtrl: fnCtrl)) {return}
        
        //
        node.pinRootExpr()
        surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: .reduce, &steps)
        if node.pinnedRootDidChange {return}
        
        //
        repeat {
            node.pinRootExpr()
            surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl + [.force], surfFnCases: .determineSign, &steps)
            determineChainSign(node: node, fnCtrl: fnCtrl + [.force], &steps)
        } while node.pinnedRootDidChange
        if node.numerator.isMinus || node.denominator.isMinus {return}
        
        //
        node.pinRootExpr()
        for numOrDenNode in node.numeratorAndDenominator {
            fractionAddition(node: numOrDenNode, fnCtrl: fnCtrl, &steps)
        }
        if node.pinnedRootDidChange {return}
        
        // Dynamic steps
        let numeratorIsOne = node.numerator.isOne(opCase: .plus)
        let numeratorIsOneTerm = node.numerator.isOneTerm
         
        // Mark and explain
        steps.lastMarked = node.flatSKs(.dropOp)
        steps.lastExplanation = "Multiply the numerator by the reciprocal of the denominator"
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Mark and explain
        steps.lastStepSubsteps.lastMarked = node.flatSKs(.dropOp)
        steps.lastStepSubsteps.lastExplanation = "Write the fraction as a division"
        
        // Convert to divide
        var dividedNode = node.numerator.clone(changeID: false, withParent: false).children.firstOrSelftAfterSetBrackets
        dividedNode.op = node.op
        let dividerNode = node.denominator.clone(changeID: false, withParent: false).children.firstOrSelftAfterSetBrackets
        dividerNode.op = .divide.withID(node.valueSK.first!.id)
        node.insertBefore(contentsOf: [dividedNode, dividerNode])
        node.remove()
        
        //
        if dividedNode.isBrackets {
            if dividedNode.children.isMultChain {
                if dividedNode.children.count == 1 {
                    steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
                    return
                }
                let lastChild = dividedNode.children.last!
                dividedNode.removeBracketsGeneral()
                dividedNode = lastChild
            } else {
                steps.lastStepSubsteps.lastMarked.append(contentsOf: dividedNode.valueSK)
                steps.lastMarked.append(contentsOf: dividedNode.valueSK)
            }
        }
        if dividerNode.isBrackets {
            steps.lastStepSubsteps.lastMarked.append(contentsOf: dividerNode.valueSK)
        }

        // Append step
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        // flip divider or convert it to fraction
        let dividerIsWholeNumber = !dividerNode.isFraction
        let dividerNumIsOne = dividerNode.isFraction && dividerNode.numerator.isOne(opCase: .plus)
        flipFraction(node: dividerNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        convertDivisionToFraction(node: dividerNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
                
        // Remove OneTimes
        if numeratorIsOne {
            removeHighOpOne(node: dividedNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            dividerNode.op = node.op
        } else if dividerIsWholeNumber || numeratorIsOneTerm {
            dividedNode.next.isTarget = true
            dividedNode.isTarget = true
            mergeWithFraction(node: dividedNode, fnCtrl: fnCtrl + [.force, .forceMerge, .targetOnly], &steps.lastStepSubsteps)
            steps.lastMarked.append(contentsOf: steps.lastStepSubsteps.beforeLastStep.markedKeys)
            steps.lastExplanation = "Multiply the numerator by the reciprocal of the denominator"
        } else {
            steps.lastMarked.append(contentsOf: dividedNode.next.flatSKs(.any))
        }
        
        // Append main steps
        node.nodeProduct = dividedNode
        appendStep(&steps, fnCtrl: fnCtrl + (dividerNumIsOne ? [.forceFlatSubsteps] : []))
    }
}

extension CalcBrain {
     func convertNodeToFractionAndSetDenominatorToOne(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
       
        // Mark and explain
         steps.lastExplanation = "Convert \(node.flatSKs(.dropPlus).strForExpl) to a fraction by setting the denominator to 1"
        
        // convert
        let fractionNode = StepNode.newFractionNode
        fractionNode.numerator = [node.clone(changeID: false, withParent: false)]
        fractionNode.op = node.op
        fractionNode.numerator.op = .plus
        node.content = fractionNode.content
        
        // append step
        steps.lastMarked.append(contentsOf: node.flatSKs(.dropOp))
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func reduceSubFractionDens(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isFraction {} else {return}
        if node.numerator.isFraction && node.denominator.isFraction {} else {return}
        let upperDen = node.numerator.first!.denominator
        let lowerDen = node.denominator.first!.denominator
        if upperDen.isSimplestForm && lowerDen.isSimplestForm {} else {return}
        if upperDen.isEqualTo(nodes: lowerDen) {} else {return}
        if fnCtrl.isCheckAllowed {node.changeContent(); return}
        
        //
        node.pinRootExpr()
        surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: .removeHighOpOne, &steps)
        if node.pinnedRootDidChange {return}
        
        // Mark and Explain
        steps.lastMarked = upperDen.flatSKs + lowerDen.flatSKs
        steps.lastExplanation = "Simplify the expression"
        steps.lastStrikeKeys = [upperDen.parent!.strikeKey, lowerDen.parent!.strikeKey]
        
        // Set Substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Convert
        let origFractionLine = node.valueSK.first!
        convertNestedFractionIntoMainFractions(node: node, fnCtrl: fnCtrl + [.force, .forceConvertNestedFraction, .skipRemoveDenIfOne], &steps.lastStepSubsteps)
        guard let dividerFractionNode = node.nodeProduct?.next else {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        
        // Reduce
        node.nodeProduct!.next.dynamicNumeratorFirst.isTarget = true
        reduceFraction(node: node.nodeProduct!.multChainFirst, fnCtrl: fnCtrl + [.force, .forceReduce, .targetOnly, .skipCommonFactor, .skipReduceToSimplify, .skipReduceDivisible], &steps.lastStepSubsteps)
        
        // Merge
        if node.nodeProduct!.exist {
            let firstFraction = node.nodeProduct!.levelNext.first(where: {$0.isFraction})!
            [StepNode](node.nodeProduct!.level![node.nodeProduct!.idx!...firstFraction.idx!]).setTargetToTrue()
            mergeWithFraction(node: node.nodeProduct!, fnCtrl: fnCtrl + [.force, .forceMerge, .targetOnly, .forceMergeWithBrkt], &steps.lastStepSubsteps)
        }
        
        // Animate fraction divider
        if let resultFraction = node.nodeProduct!.nodeProduct {
            resultFraction.valueSK[0] = origFractionLine
        } else if dividerFractionNode.isFraction && dividerFractionNode.numerator.isOne(opCase: .any) {
            dividerFractionNode.valueSK[0] = origFractionLine
            dividerFractionNode.numerator[0].valueSK = node.numerator.first!.numerator.first!.valueSK
        }
        
        // Append main step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
