//
//  ConvertToFraction.swift
//  Hulul
//
//  Created by Ahmad on 06/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    
    func convertDivisionToFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isFirstInDividedMultChain || node.isDivide && (node.prev.isFraction || !(fnCtrl.isForced && !fnCtrl.contains(.skipDivToFracIfDividedHasFraction)) && node.prev.isBrackets(.hasFraction(fractionCase: .simplest(for: .all)))) {} else {return}
        let multChain = node.multChain(forward: true)
        if multChain.isBrackets(.singleNegGeneral) {return}
        if multChain.hasBrackets(.notSimplest) || !node.isEquation && multChain.hasFraction(flat: true) || !(fnCtrl.isForced && !fnCtrl.contains(.skipDivToFracIfDividedHasFraction)) && node.isEquation && multChain.hasFractionFlat(part: .all, {!($0.first!.parentFraction!.parent!.isSqrt && $0.first!.parentFraction!.level!.isSimplestForm && $0.first!.parentFraction!.hasVarFlat)}) {return}
        let divNode = node.multChainDivider
        if divNode.baseOrTermNode.isPoweredByMultiple || divNode.baseOrTermNode.isPowered && divNode.baseOrTermNode.power.isMinus {return}
        if divNode.isFraction || !(fnCtrl.isForced && !fnCtrl.contains(.skipDivToFracIfDividedHasFraction)) && divNode.children.hasFraction(flat: true) {return}
        if divNode.isBrackets(.notSimplest) && !divNode.children.isMultChain || !fnCtrl.isForced && !multChain.isDecimal && divNode.isDecimal {return}
        if !multChain.isEmpty && multChain.first!.isBrackets(.any) && multChain.isTimes && multChain.first!.prev.valueIsOne {return}
        if node.isDivide && node.isBrackets && node.children.isFraction {return}
        
        //
        if let radicalParent = divNode.radicalParent, divNode.isOneRadical && radicalParent.children.isFraction {
            node.pinRootExpr()
            distributeRadicalsOnFractions(rootableNodes: [radicalParent.children.first!], fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        if !fnCtrl.isForced && !node.sqrtIsCeiling && !(node.isInBrackets && node.parent!.isPowered) && multChain.count == 1 && [node,divNode].hasOnlyWholeNumbers && [node,divNode].getGCD == nil {
            if !node.isPowerer && node.exactResultIfDividedBy(node: divNode) && !node.root.flatTree.dropNode(node: divNode).filter({!$0.isSymb}).contains(where: {$0.isTimesOrDivide || $0.isFraction}) && !(node.isEquation && node.otherSide.flatTree.filter({!$0.isSymb}).contains(where: {$0.isDivide || $0.isFraction || $0.isVarWithCoeff})) {
                divideTheNumbers(nodes: [node,divNode], steps: &steps)
                return
            }
            if steps.count == 1 && !node.isEquation && node.parent!.isRoot && node.root.children.count == 2 {
                steps[0].note = "..."
            }
        }
        
        //
        if multChain.isZero {
            removeTimesOrDividedZero(node: multChain.first!, fnCtrl: fnCtrl, &steps)
            return
        }
            
        // mark and explain
        steps.lastExplanation = "Write the division as a fraction"
        
        // Build Fraction Node
        let fractionNode = StepNode(valueSK: [.fraction.withID(divNode.op.id)])
        fractionNode.children.append(contentsOf: [.newFractionBracketsNode, .newFractionBracketsNode])
        fractionNode.numerator = multChain.isEmpty ? [.newOneNode] : multChain.clone(changeID: false, withParent: false).children
        fractionNode.denominator = [divNode.clone(changeID: false, withParent: false)]
        fractionNode.op = multChain.isEmpty ? .times : fractionNode.numerator.op
        fractionNode.numerator.op = .plus
        fractionNode.denominator.op = .plus
        
        // Remove brackets if alone
        if fractionNode.numerator.isBrackets(.any) && !fractionNode.numerator.first!.isPowered {
            steps.lastMarked.append(contentsOf: fractionNode.numerator.first!.valueSK)
            fractionNode.numerator.first!.removeBracketsGeneral()
        }
        if fractionNode.denominator.isBrackets(.any) && !fractionNode.denominator.first!.isPowered {
            steps.lastMarked.append(contentsOf: fractionNode.denominator.first!.valueSK)
            fractionNode.denominator.first!.removeBracketsGeneral()
        }
        
        // inser fraction node Remove old nodes
        node.level!.insert(fractionNode, at: multChain.isEmpty ? node.idx! : multChain.first!.idx!)
        multChain.removeNodesFromParent()
        divNode.remove()
        
        // mark and append
        steps.lastMarked.append(contentsOf: fractionNode.flatSKs(multChain.isEmpty ? .any : .dropOp))
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func divideTheNumbers(nodes: [StepNode], steps: inout [StepModel]) {

        // Mark and explain
        steps.lastMarked = nodes.flatSKs(.dropOp)
        steps.lastExplanation = "Divide the numbers"
        
        // Evaluate
        let resultNode = nodes.getResultNodeGeneralRounded(precision: 19)
        nodes.first!.insertBefore(resultNode)
        nodes.removeNodesFromParent()
        
        //
        if resultNode.valueSK.first!.key.isMinus {
            if !nodes.isMinus {
                steps.setToUnableToSolve(nodeL: nodes.root, nodeR: nodes.root.otherSide)
                return
            }
            resultNode.valueSK.removeFirst()
            resultNode.op = nodes.op
        }
        
        //
        resultNode.opValueSK.replaceSimilarKeys(similarKeys: nodes.flatSKs)
        
        // Mark and Append
        steps.lastMarked.append(contentsOf: resultNode.flatSKs(.dropOp))
        appendStep(&steps, fnCtrl: [])
    }
}

