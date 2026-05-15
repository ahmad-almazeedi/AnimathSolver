//
//  RemoveZero.swift
//  Hulul
//
//  Created by Ahmad on 22/06/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func removeZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        evaluatePoweredByZero(node: node, fnCtrl: fnCtrl, &steps)
        detectDivideByZero(node: node, fnCtrl: fnCtrl, &steps)
        removeZeroPowered(node: node, fnCtrl: fnCtrl, &steps)
        removeTimesOrDividedZero(node: node, fnCtrl: fnCtrl, &steps)
        removeAddedZero(node: node, fnCtrl: fnCtrl, &steps)
        removeDenominatorIfNumIsZero(node: node, fnCtrl: fnCtrl, &steps)
        removeNegativeZero(node: node, fnCtrl: fnCtrl, &steps)
        zeroPoweredByNegative(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    private func evaluatePoweredByZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isPoweredByZero {} else {return}
        
        // Bracket content not zero check
        if node.isBrackets {
            if node.children.mayBeUndefinable {return}
            let nodeClone = node.clone(changeID: false, withParent: false)
            nodeClone.op = .plus
            var fakeSteps = [StepModel()]
            surfAndEvaluateAndApplyFnTillEnd(parent: nodeClone, fnCtrl: fnCtrl + [.skipAppendStep, .skipPrintStep], &fakeSteps)
            if nodeClone.children.isZero {return}
        }
        
        // Mark
        steps.lastMarked = node.flatSKsNoTerms(.dropOp)
        
        // If zero power zero
        if node.valueIsZero {
            let explanation = "0 raised to the power of 0 is undefined"
            setToUndefined(nodeL: node, nodeR: node.otherSide, markedKeys: node.flatSKsNoTerms(.dropOp), explanation: explanation, &steps)
            return
        }
        
        // Explain
        steps.lastExplanation = "Any non-zero expression raised to the power of 0 equals 1"
        
        // Change to one
        let newOneNode = StepNode.newOneNode.withOp(node.isSqrt ? .times : node.op)
        if node.isSymb {
            newOneNode.op.changeID()
        }
        if !node.isTerm {
            if node.isCoeff {
                node.extractTerms()
                node.valueSK = [.one]
                node.removePower()
                steps.lastMarked.append(contentsOf: [node.firstValueSK, node.next.op])
            } else {
                node.insertAfter(newOneNode)
                node.remove()
            }
        } else {
            let coeffNode = node.coeffNode
            if node.isFirstTerm {
                if coeffNode.isOneTerm {
                    steps.lastMarked.append(coeffNode.valueSK.first!)
                    node.remove()
                    if coeffNode.hasDirectSymbs {
                        coeffNode.showOneTerm = true
                    }
                } else {
                    coeffNode.extractTerms()
                    steps.lastMarked.append(contentsOf: coeffNode.next.opValueSK)
                    node.remove()
                    if coeffNode.next.hasDirectSymbs {
                        coeffNode.next.showOneTerm = true
                    }
                }
            } else {
                if node.isSqrt {
                    steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
                    return
                }
                if node.isLast {
                    coeffNode.insertAfter(newOneNode)
                    steps.lastMarked.append(newOneNode.op)
                    node.remove()
                } else {
                    coeffNode.extractTermsAfter(termNode: node)
                    steps.lastMarked.append(contentsOf: coeffNode.next.opValueSK)
                    node.remove()
                    coeffNode.next.showOneTerm = true
                }
            }
        }
        
        // Mark and append
        steps.lastMarked.append(newOneNode.valueSK.first!)
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // removeOneTerm
        removeHighOpOne(node: node.baseNode, fnCtrl: fnCtrl, &steps)
        if node.baseNode.exist {
            removeHighOpOne(node: node.baseNode.next, fnCtrl: fnCtrl, &steps)
        }
    }
    func detectDivideByZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isDivideByZero {} else {return}
        
        // Mark and explain
        let markedKeys = node.isInFraction && node.parentFraction!.denominator.isZero ? node.parentFraction!.flatSKs(.dropOp) : node.prev.multChain(forward: false).flatSKs(.dropPlus) + node.flatSKs(.any)
        let explanation = "Any Expression divided by 0 is undefined"
        
        // Set Undefined
        setToUndefined(nodeL: node, nodeR: node.otherSide, markedKeys: markedKeys, explanation: explanation, &steps)
    }

    func removeAddedZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isZero(opCase: .plusOrMinus) && !node.next.isTimesOrDivide && !node.level!.isZero {} else {return}
        
        // Mark and Append
        steps.lastMarked = node.opValueSK + (node.isFirst && node.next.isPlus ? [node.next.op] : [])
        steps.lastExplanation = "When adding or subtracting 0, nothing changes"
        
        // Remove Zero
        node.remove()
        
        // Append
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func removeZeroPowered(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        guard node.valueIsZero && node.isPowered && !node.power.mayBeUndefinable && (node.power.hasVarOrNotVarXFlat || node.power.resultValue() > 0) else {return}
        
        // Mark and explain
        steps.lastMarked = node.flatSKsNoTerms(.dropOp)
        steps.lastExplanation = "0 raised to any positive power equals 0"
        
        // Remove
        node.removePower()
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // detect divide by zero
        detectDivideByZero(node: node, fnCtrl: fnCtrl, &steps)
    }
    
    func removeTimesOrDividedZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isPlusOrMinus {} else {return}
        let highOpChain = node.highOpChain
        let chain = highOpChain.mayBeUndefinable ? node.multChain(forward: true) : highOpChain
        if chain.flatTree.contains(where: {$0.isUndefinableZero}) {return}
        if chain.count > 1 && chain.contains(where: {$0.isZeroMayHaveSymb && !$0.isDivide}) || chain.count == 1 && chain.first!.isZeroMayHaveSymb && chain.first!.isCoeff {} else {return}
        if !fnCtrl.contains(.forceRemoveTimesZero) && chain.mayBeUndefinable {return}
        
        // Mark and explain
        let zeroNode = chain.first(where: {$0.isZeroMayHaveSymb})!
        let isTimesZero = zeroNode.isTimes || zeroNode.next.isTimes || zeroNode.isCoeff
        steps.lastMarked = chain.flatSKs(chain.first!.isFirst ? .onlyMinus : .dropOp)
        let chainDroppedZero = chain.filter({!$0.isZero})
        let numberOrExprStr = chain.filter({$0.isZero}).count == 1 && chainDroppedZero.count == 1 && chainDroppedZero.first!.isNumberNotPoweredNotCoeff ? "number" : "expression"
        steps.lastExplanation = isTimesZero ? "Any \(numberOrExprStr) multiplied by 0 equals 0" : "0 divided by any non-zero expression equals 0"
        
        // Preserve 0 IDs and first op
        let newZeroNode = StepNode(op: chain.first!.isFirst ? .plus : chain.op, valueSK: zeroNode.valueSK)
        chain.first!.insertBefore(newZeroNode)
        
        // Remove chain
        chain.removeNodesFromParent()
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // detect divide by zero
        detectDivideByZero(node: newZeroNode, fnCtrl: fnCtrl, &steps)
    }
    private func removeDenominatorIfNumIsZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isFraction && node.numerator.isZero {} else {return}
        if node.denominator.mayBeUndefinable {return}
        
        // Mark and explain
        steps.lastMarked = node.flatSKs(.dropOp)
        steps.lastExplanation = "0 divided by any non-zero expression equals 0"
        
        // Remove denominatorn
        node.removeDenominator()
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    private func removeNegativeZero(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Condtions
        if !node.exist {return}
        if node.isZero && node.isMinus {} else {return}
        if node.isAlone {} else {return}
        
        // Mark and explain
        steps.lastMarked = [node.op]
        steps.lastExplanation = "0 does not have a sign"
        
        // Remove minus
        node.op = .plus
        
        // Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    private func zeroPoweredByNegative(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        guard node.valueIsZero && node.isPowered && node.power.isSimplestForm else {return}
        if node.power.hasVarOrNotVarXFlat {return}
        guard node.power.resultValue() < 0 else {return}
        
        //
        let markedKeys = node.flatSKs(.dropOp)
        let explanation = "0 raised to the power of a negative number is undefined"
        setToUndefined(nodeL: node, nodeR: node.otherSide, markedKeys: markedKeys, explanation: explanation, &steps)
        return
    }
}
