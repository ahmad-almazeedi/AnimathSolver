//
//  Reduce.swift
//  Hulul
//
//  Created by Ahmad on 25/06/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    
    func reduceFirstEqualNodes(numNode: inout StepNode, denChain: [StepNode], fnCtrl: [FnCtrl], sameFraction: Bool, _ steps: inout [StepModel]) {
        
        // Conditions
        var denNode = StepNode()
        guard let tmpDenNode = denChain.first(where: {$0.hasEqualBase(with: numNode) && $0.hasEqualPow(with: numNode) && (!sameFraction || $0.isInSameFraction(with: numNode, shouldBeSingle: true))}) else {return}
        if fnCtrl.isCheckAllowed {numNode.root.changeContent(); return}
        denNode = tmpDenNode
        numNode.numeratorMultChain(termMix: true).setSurfedToTrue()
        denChain.setSurfedToTrue()
        numNode.isReduced = true
        denNode.isReduced = true
        
        // Flip Positions if appropriate
        if numNode.isBrackets && numNode.children.count == 2 && !numNode.children.first!.isEqualTo(node: denNode.children.first!) {
            let toFlipBrkt = [numNode, denNode].first(where: {$0.children.isMinus}) ?? numNode
            flipPositionsOfTwoNodes(node1: toFlipBrkt.children.first!, node2: toFlipBrkt.children.last!, fnCtrl: fnCtrl, &steps)
        }
        
        // Mark and strike and explain
        steps.lastMarked = numNode.flatSKsNoTerms(.dropOp) + denNode.flatSKsNoTerms(.dropOp)
        if (numNode.baseNode.isOneSingleTerm && denNode.baseNode.isOneSingleTerm || ![numNode, denNode].hasTerm) && sameFraction && numNode.baseNodeIfOneSingleTerm.isInFraction && numNode.baseNodeIfOneSingleTerm.parentFraction!.isFraction(.single(simplest: false, for: .all)) || numNode.isBrackets && numNode.children.first!.isInSameFraction(with: denNode.children.first!, shouldBeSingle: false) && numNode.children.first!.parentFraction!.isFraction(.simplest(for: .all)) {
            let numberOrExprStr = !numNode.isTerm && !numNode.isCoeff && numNode.isNumber(mayBePowered: false) ? "number" : "expression"
            steps.lastMarked.append(numNode.baseNodeIfOneSingleTerm.parentFraction!.valueSK.first!)
            steps.lastExplanation = "Any non-zero \(numberOrExprStr) divided by itself equals 1"
        } else {
            let commonFactorStr = numNode.isBrackets ? numNode.flatSKsNoTerms(.dropOp).strForExpl.dropOuterBrackets(flag: !numNode.isPowered) : numNode.flatSKsNoTerms(.dropOp).filter({!$0.key.isBracket}).stringWithSinglePower
            steps.lastExplanation = "Cancel out the common factor \(commonFactorStr)"
        }
        
        steps.lastStrikeKeys = [numNode.strikeKey, denNode.strikeKey]
        
        // Insert one
        let numNodeBase = numNode.baseNodeIfOneSingleTerm
        if fnCtrl.contains(.forceReduceToOne) && (numNodeBase.isOneTerm && numNodeBase.hasSingleTerm || !numNodeBase.isCoeff) && numNodeBase.level!.count == 2 && numNodeBase.level!.dropNode(node: numNodeBase).first!.isBrackets {
            let newOneNode = StepNode.newOneNode.withOp(.times)
            numNodeBase.insertAfter(newOneNode)
            steps.lastMarked.append(newOneNode.valueSK.first!)
        }
        
        // Parenthesize if appropriate
        if numNode.parent!.isFraction {
            numNode.children.setBrackets()
            numNode = numNode.children.first!
        }
        if denNode.parent!.isFraction {
            denNode.children.setBrackets()
            denNode = denNode.children.first!
        }
        
        // Remove nodes
        if numNode.baseNode.isInNumerator || numNode.isInBrackets && numNode.parent!.isInNumerator {
            numNode.baseNodeIfOneSingleTerm.removeInFraction(isTerm: numNode.isTerm, markedKeys: &steps.lastMarked)
            denNode.baseNodeIfOneSingleTerm.removeInFraction(isTerm: denNode.isTerm, markedKeys: &steps.lastMarked)
        } else {
            denNode.baseNodeIfOneSingleTerm.removeInFraction(isTerm: denNode.isTerm, markedKeys: &steps.lastMarked)
            numNode.baseNodeIfOneSingleTerm.removeInFraction(isTerm: numNode.isTerm, markedKeys: &steps.lastMarked)
        }
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // remove times one
        if denNode.baseNode.parent!.hasParent {
            removeHighOpOne(node: denNode.baseNode.parent!.parent!, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}

extension CalcBrain {
    func reduceDividedFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isDivide && node.isFraction(.singlePositiveNumber(mayBePowered: true, mayHaveCoeff: true, for: .all)) {} else {return}
        if node.numerator.isEqualTo(nodes: node.denominator) {} else {return}
        
        // Mark and Explain
        steps.lastMarked = node.flatSKs(.dropOp)
        let numberOrExprStr = node.numerator.count == 1 && node.numerator.first!.isNumber(mayBePowered: false) && !node.numerator.hasTerm ? "number" : "expression"
        steps.lastExplanation = "Any non-zero \(numberOrExprStr) divided by itself equals 1"
        steps.lastStrikeKeys = [node.numerator.first!.strikeKeyWithSymb, node.denominator.first!.strikeKeyWithSymb]
        
        //
        let divOneNode = StepNode.newOneNode.withOp(node.op)
        node.insertAfter(divOneNode)
        node.remove()
        
        // Mark and Append step
        steps.lastMarked.append(divOneNode.firstValueSK)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
