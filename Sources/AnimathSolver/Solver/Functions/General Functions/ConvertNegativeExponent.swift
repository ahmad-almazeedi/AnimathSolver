//
//  ConvertNegativeExponent.swift
//  Hulul
//
//  Created by Ahmad on 20/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func convertNegativeExponent(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced && !fnCtrl.contains(.forceConvNegExp) {return}
        if node.valueIsZero || node.isDecimal {return}
        if node.isPoweredByNegative && (node.isPoweredByWholeNumber && node.powerValue != 0 || node.power.isFraction) {} else {return}
        if !fnCtrl.isForced && node.children.hasFraction(flat: true) && !node.children.isSimplestForm && node.children.count > 1 {return}
        if !fnCtrl.isForced && !fnCtrl.contains(.forceConvNegExp) && node.isBrackets && (node.children.termMix.hasNegPower && node.isBrktsNotSqrt && !node.isInFraction || node.children.hasBrackets || !node.children.isMultChainOrSimplestForm || node.children.hasFraction(flat: true) && node.children.count > 1) {return}
        let baseNode = node.baseNode
        if baseNode.isInBrackets && willDistributePowerIntoBrackets(node: baseNode.parent!, fnCtrl: fnCtrl) {return}
        if baseNode.isInSqrtGeneral && baseNode.generalRadicalParent!.isPowered {return}
        if baseNode.next.isDivide && baseNode.isInFraction {return}
        let reciprocalLevel = baseNode.isInFraction ? baseNode.reciprocalLevel : []
        if baseNode.isInFraction && !reciprocalLevel.hasOnlyTimes && !reciprocalLevel.isSimplestForm && !reciprocalLevel.termMix.hasNegPower {return}
        
        // Pre Functions
        if node.isBrackets {
            node.pinRootExpr()
            distributePowerIntoBrackets(node: node, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        }
        if node.power.isFraction(.notSimplestReduced) {
            node.pinRootExpr()
            reduceFraction(node: node.power.first!, fnCtrl: fnCtrl + [.force], &steps)
            if node.pinnedRootDidChange {return}
        }
        node.pinRootExpr()
        if let multChainFirst = node.baseNode.multChain(forward: false).first {
            multSameBase(node: multChainFirst, fnCtrl: fnCtrl, &steps)
        }
        if node.pinnedRootDidChange {return}
        if baseNode.isBrackets, let generalParentBrktWithNegExp = baseNode.generalParentBrktWithNegExp {
            convertNegativeExponent(node: generalParentBrktWithNegExp, fnCtrl: fnCtrl + [.forceConvNegExp], &steps)
        }
        if baseNode.isBrackets && baseNode.children.isFraction {
            node.pinRootExpr()
            let fractionNode = baseNode.children.first!
            reduceFirstDivisibleNodes(numNode: fractionNode.numerator.first!, denChain: fractionNode.denominator, numToDen: true, fnCtrl: fnCtrl + [.force], sameFraction: true, &steps)
            if node.pinnedRootDidChange {return}
            flipFractionWithNegExponent(node: baseNode.children.first!, fnCtrl: fnCtrl, &steps)
            return
        }
        // flip fraction if isDivide
        if let parentFraction = baseNode.parentFraction, parentFraction.isDivide {
            flipFraction(node: parentFraction, fnCtrl: fnCtrl, &steps)
            if baseNode.isInFraction {
                surfAndApplyFn(mainNode: parentFraction, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: .convertNegativeExponent, &steps)
            }
            return
        } else if node.baseNodeIfOneTerm.isDivide {
            convertDivideNegExponent(node: node, fnCtrl: fnCtrl, &steps)
            return
        }
        
        // Execute
        var termNodes = [StepNode]()
        var coeffNode = StepNode()
        if node.isCoeff {
            termNodes = node.directSymbs
            if let radicalParent = node.radicalParent {
                termNodes.append(radicalParent)
            }
            node.seperateTermsFromNode()
        } else if node.isSqrt && !node.baseNode.isOneSingleRadical {
            coeffNode = node.coeffNode
            termNodes = node.coeffNode.directSymbs
            node.seperateRadicalFromCoeff()
        } else if node.isSymb && !node.baseNode.isOneSingleSymb {
            if node.coeffNode.valueIsZero {
                removeTimesOrDividedZero(node: node.coeffNode, fnCtrl: fnCtrl + [.forceRemoveTimesZero], &steps)
                return
            }
            coeffNode = node.coeffNode
            termNodes = node.coeffNode.directSymbs.dropNode(node: node)
            if let radicalParent = node.radicalParent {
                termNodes.append(radicalParent)
            }
            node.seperateSymbFromSymbs()
        }
//        removeHighOpOne(node: coeffNode, fnCtrl: fnCtrl + [.skipAppendStep], &steps) // consider: e^-1 * 3

        // Mark and Explain
        steps.lastMarked = node.flatSKs(node.isInFraction ? .onlyTimes : .dropOp)
        steps.lastExplanation = "Get rid of the negative exponent using the rule:\na⁻ⁿ = 1/aⁿ"
        
        // Convert
        if node.baseNodeIfOneTerm.isInFraction && node.baseNodeIfOneTerm.level!.isHighOpChain {
            convertInFraction(node: node, steps: &steps)
        } else {
            convertNotFraction(node: node, termNodes: termNodes, coeffNode: coeffNode, steps: &steps)
        }
                
        // Remove Power One
        removePowerOne(node: node, fnCtrl: fnCtrl + [.force, .skipAppendStep], &steps)
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Convert Terms
        for termNode in termNodes {
            convertNegativeExponent(node: termNode, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
    
    private func convertInFraction(node: StepNode, steps: inout [StepModel]) {
      
        //
        let baseNode = node.baseNodeIfOneTerm
        let fractionNode = baseNode.parentFraction!
        let isInNumerator = baseNode.isInNumerator
        let shouldAppend = baseNode.isAlone || (baseNode.level!.count-1)/2 <= baseNode.idx!
        let numeratorIsOne = fractionNode.numerator.isOne(opCase: .plus)
        let numOrDen = isInNumerator ? fractionNode.denominator : fractionNode.numerator

        //
        steps.lastExplanation = "Move the expression to the \(isInNumerator ? "denominator" : "numerator") and make the exponent positive"

        //
        node.baseNodeIfOneSingleTerm.removeInFraction(isTerm: node.isTerm, markedKeys: &steps.lastMarked)
        node.power.first!.flipSign()
        
        //
        if !numeratorIsOne && fractionNode.isFraction && fractionNode.numerator.isOne(opCase: .plus) {
            fractionNode.numerator.first!.valueSK.changeIDs()
            steps.lastMarked.append(fractionNode.numerator.first!.valueSK.first!)
        }
        
        // Parenthesize if not highOpChain
        var didSetBrackets = false
        if !numOrDen.isHighOpChain {
            numOrDen.setBrackets()
            steps.lastMarked.append(contentsOf: numOrDen.parent!.valueSK)
            didSetBrackets = true
        }
        
        //
        if shouldAppend && !baseNode.isTimes {
            baseNode.op = .times
        } else if !shouldAppend {
            if baseNode.isTimes {
                baseNode.op = .plus
            }
            var firstInNumOrDen = numOrDen.first!
            if didSetBrackets {
                firstInNumOrDen = numOrDen.parent!
            }
            firstInNumOrDen.op = .times
            steps.lastMarked.append(firstInNumOrDen.op)
        }
        
        //
        steps.lastMarked.append(baseNode.op)
        
        //
        if isInNumerator {
            fractionNode.denominator.insertOrAppend(node: baseNode, shouldAppend: shouldAppend)
        } else {
            if fractionNode.isFraction {
                fractionNode.numerator.insertOrAppend(node: baseNode, shouldAppend: shouldAppend)
                if numeratorIsOne {
                    let oneNode = fractionNode.numerator.first(where: {$0.isOne(opCase: .any)})!
                    removeHighOpOne(node: oneNode, fnCtrl: [.skipAppendStep], &steps)
                }
            } else {
                fractionNode.insertAfter(baseNode)
                if numeratorIsOne {
                    fractionNode.remove()
                    baseNode.op = fractionNode.op
                }
            }
        }
    }
    
    private func convertNotFraction(node: StepNode, termNodes: [StepNode], coeffNode: StepNode, steps: inout [StepModel]) {
        let baseNode = node.baseNodeIfOneSingleTerm
        let fractionNode = StepNode.newFractionNode
        baseNode.insertAfter(fractionNode)
        baseNode.remove()
        node.power.first!.flipSign()
        fractionNode.op = baseNode.op
        baseNode.op = .plus
        fractionNode.denominator = [baseNode]
        steps.lastMarked.append(contentsOf: fractionNode.flatSKs(.dropOp))
        
        // Insert Term in Fraction
        if !termNodes.isEmpty && coeffNode.isEmpty {
            let oneTerm = termNodes.parent!
            oneTerm.remove()
            oneTerm.op = .plus
            fractionNode.numerator = [oneTerm]
        } else if !coeffNode.isEmpty {
            fractionNode.op = coeffNode.op
            coeffNode.op = .plus
            coeffNode.remove()
            fractionNode.numerator = [coeffNode]
        }
    }
    
    private func convertDivideNegExponent(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // mark and explain
        steps.lastMarked = [node.baseNodeIfOneTerm.op, node.power.op]
        steps.lastExplanation = "Dividing by a⁻ⁿ is the same as multiplying by aⁿ"
        
        // Change the signs
        node.baseNodeIfOneTerm.op = .times
        node.power.op = .plus
        
        // Mark and append
        steps.lastMarked.append(contentsOf: [node.baseNodeIfOneTerm.op, node.power.op])
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    private func flipFractionWithNegExponent(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.isFraction || !node.parent!.power.isMinus {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        
        //
        steps.lastMarked = node.flatSKs + [node.parent!.power.op]
        steps.lastExplanation = "Express with a positive exponent by replacing the fraction with its reciprocal"
        
        //
        node.parent!.power.first!.op = .plus
        
        //
        node.flipFraction(fnCtrl: fnCtrl)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
