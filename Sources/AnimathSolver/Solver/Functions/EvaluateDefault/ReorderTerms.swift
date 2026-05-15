//
//  ReorderTerms.swift
//  Hulul
//
//  Created by Ahmad on 25/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func reorderTermsFromOut(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if !fnCtrl.isForced && node.isSurfed {return}
        guard let nextNumberNode = node.nextNonMultBrkt, !nextNumberNode.isOne else {return}
        if nextNumberNode.nextNonMultBrkt != nil {return}
        if !node.isBrackets && node.multChain(forward: true).hasBrackets(.any) && !nextNumberNode.next.isTimesOrDivide {return}
        if nextNumberNode.directTerms.hasPoweredByNotPosConst {return}
        let afterRadThenSymb = node.hasAfterSymbsRadical && nextNumberNode.hasDirectSymbs
        if node.isOneTerm || afterRadThenSymb {} else {return}
        if node.directTerms.contains(where: {!$0.power.isSimplestForm || $0.power.isFraction}) {return}
        if !node.isDivide && node.next.isTimes {} else {return}
        if node.isInDividedMultChain {return}
        if nextNumberNode.isNumber(mayBePowered: false) && !(nextNumberNode.isOneTerm && node.isOneTerm && !(node.hasAfterSymbsRadical || nextNumberNode.hasBeforeSymbsRadical) || nextNumberNode.isOneSymb && node.directSymbs.contains(where: {nextNumberNode.directSymbs.first!.hasEqualBase(with: $0)})) && !(node.hasDirectRadical && nextNumberNode.hasDirectRadical) {} else {return}
        if !node.isOneTerm && !nextNumberNode.isOneTerm {return}
        if !node.isInSqrtGeneral && [node, nextNumberNode].directRadicals.contains(where: {!$0.isSimplestRadical}) {return}
        
        // Mark and explain
        let beforeNodesOrder = [node,nextNumberNode].withEachTermExtracted
        steps.lastExplanation = UseCommutativePropExplanation
        
        // Reorder
        if !(node.isOneRadical && node.isTimes) {
            nextNumberNode.op = node.op
        }
        if let radicalParent = node.radicalParent {
            if let nexRadicalParent = nextNumberNode.radicalParent {
                let newOneNode = StepNode.newOneNode.withOp(.times)
                newOneNode.radicalParent = nexRadicalParent
                nextNumberNode.insertAfter(newOneNode)
            }
            nextNumberNode.radicalParent = radicalParent
        }
        if node.hasDirectSymbs {
            if nextNumberNode.hasVar || !node.hasVar {
                nextNumberNode.directSymbs.insert(contentsOf: node.directSymbs, at: 0)
            } else {
                nextNumberNode.directSymbs.append(contentsOf: node.directSymbs)
            }
        }
        if !node.isOneTerm && nextNumberNode.isOneTerm {
            nextNumberNode.valueSK = node.valueSK
        }
        nextNumberNode.remove()
        node.insertAfter(nextNumberNode)
        node.remove()
        
        //
        reorderTermsFromIn(node: nextNumberNode, fnCtrl: fnCtrl + [.skipAppendStep], &steps)
        
        //
        let afterNodesOrder = [nextNumberNode].withEachTermExtracted
        var nonMarked = [StepNode]()
        if beforeNodesOrder.count == afterNodesOrder.count {
            for i in (0..<afterNodesOrder.count).reversed() {
                if beforeNodesOrder[i].baseOrTermNode.valueSK == afterNodesOrder[i].baseOrTermNode.valueSK {
                    nonMarked.append(afterNodesOrder[i])
                }
            }
        }
        steps.lastMarked = afterNodesOrder.dropNodes(nodes: nonMarked).flatSKs(.dropOp) + beforeNodesOrder.dropFirst.getOps.filter({$0.key.isTimes})
        
        // Append
        appendStep(&steps, fnCtrl: fnCtrl)
        
    }
    
    func reorderTermsFromIn(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.exist {return}
        if fnCtrl.contains(.skipSymbMultOrOrder) {return}
        if node.isNumber(mayBePowered: true) && node.hasMultiTerms {} else {return}
        if node.directTerms.hasPoweredByNotPosConst {return}
        if !fnCtrl.isForced && node.isInSqrtGeneral {return}
        if let radicalParent = node.radicalParent {
            if radicalParent.isSimplestRadical {} else {return}
        }
        if let parentFraction = node.parentFraction, parentFraction.denominator.hasDirectRadical {return}
        if node.isMultipliedOrDivideOrDivided {
            reorderRadicalFromIn(node: node, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        reorderSymbsFromIn(node: node, fnCtrl: fnCtrl, &steps)
        reorderRadicalFromIn(node: node, fnCtrl: fnCtrl, &steps)
    }
    
    private func reorderRadicalFromIn(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.exist {return}
        guard let radicalParent = node.radicalParent else {return}
        if node.shouldReorderRadical {} else {return}
        
        //
        steps.lastMarked = node.directTerms.flatSKs
        steps.lastExplanation = UseCommutativePropExplanation
        
        //
        radicalParent.flipRadicalOrder()
        
        //
        node.next.removeTimesFromTerm(markedKeys: &steps.lastMarked)
        reorderSymbsFromIn(node: node, fnCtrl: fnCtrl + [.skipAppendStep], &steps)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    private func reorderSymbsFromIn(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if node.symbsAreInSimplestForm {} else {return}
        guard let firstVarOrI = node.directSymbs.first(where: {$0.isVarOrI}), !firstVarOrI.isLast else {return}
        let levelAfterVarOrI = firstVarOrI.levelNext
        if levelAfterVarOrI.hasConstSymb {} else {return}
        
        //
        reorderRadicalFromIn(node: node, fnCtrl: fnCtrl + [.skipAppendStep], &steps)
        
        // Set var nodes
        let varOrINodes = node.directSymbs.filter({$0.isVarOrI})
        
        // Mark and explain
        steps.lastMarked.append(contentsOf: levelAfterVarOrI.flatSKs)
        steps.lastExplanation = UseCommutativePropExplanation
        
        // Reorder
        node.directSymbs.removeAll(where: {$0.isVarOrI})
        node.directSymbs.append(contentsOf: varOrINodes)
        
        // Append
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func reorderSymbsFromInTo(node: StepNode, symbKeys: [Key], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.directSymbs.typesKeys.contains(where: {symbKeys.contains($0)}) {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        if symbKeys == node.directSymbs.typesKeys {return}
                
        // Mark and explain
        steps.lastMarked.append(contentsOf: node.directSymbs.flatSKs)
        steps.lastExplanation = UseCommutativePropExplanation
        
        // Reorder
        node.directSymbs = symbKeys.map({symbKey in node.directSymbs.first(where: {$0.type?.key == symbKey})!})
        
        // Append
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
