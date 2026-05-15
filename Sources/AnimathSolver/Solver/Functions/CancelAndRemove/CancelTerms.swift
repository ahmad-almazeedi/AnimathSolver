//
//  CancelTerms.swift
//  Hulul
//
//  Created by Ahmad on 22/05/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func cancelOppositeTerms(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
       
        // Conditions
        if !node.exist {return}
        if node.isPlusOrMinus {} else {return}
        let oppositeChain = getOppositeEqualChain(for: node)
        if oppositeChain.isEmpty || node.hasRadicalFlat && !oppositeChain.isSimplestForm {return}
        guard node.idx! < oppositeChain.first!.idx! else {return}
        if oppositeChain.flatTree.contains(where: {$0.isUndefinableZero}) {return}
        if oppositeChain.mayBeUndefinable {return}
        if oppositeChain.isBrackets(.singleNegGeneral) && oppositeChain.isPlus {return}
        let chain = node.highOpChain
        
        // Mark and explain
        steps.lastMarked = chain.flatSKs(.any) + oppositeChain.flatSKs(.any)
        steps.lastExplanation = "Adding opposite values equals zero, so just remove them"
        if chain.count == 1 && !chain.isBrackets(.complete) {
            steps.lastStrikeKeys = [chain.first!.strikeKeyWithSymb, oppositeChain.first!.strikeKeyWithSymb]
        } else {
            let strikeKey1 = (chain.flatSKsForStrike[chain.flatSKsForStrike.count/2], chain.flatSKsForStrike.count)
            let strikeKey2 = (oppositeChain.flatSKsForStrike[oppositeChain.flatSKsForStrike.count/2], oppositeChain.flatSKsForStrike.count)
            steps.lastStrikeKeys = [strikeKey1, strikeKey2]
        }
        
        // Remove
        let parent = node.parent!
        chain.removeNodesFromParent()
        oppositeChain.removeNodesFromParent()
        
        // Set level to zero if empty
        if node.level!.isEmpty {
            steps.lastExplanation = "The sum of two opposites equals 0"
            parent.children = [StepNode.newZeroNode]
            steps.lastMarked.append(parent.children.first!.valueSK.first!)
        }
        
        // Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
        
    }
    
    func getOppositeEqualChain(for node: StepNode) -> [StepNode] {
        guard let level = node.level else {return []}
        let chain = node.highOpChain
        var opSign = chain.op.key
        opSign.flipSign()
        for otherNode in level.filter({!chain.contains($0)}) {
            if otherNode.op.key == opSign {
                var tmpChain = chain.clone(changeID: false, withParent: false).children
                tmpChain.op = .stepKey(opSign)
                let tmpOppositeChain = otherNode.highOpChain
                if tmpOppositeChain.isEqualHighOpChain(nodes: tmpChain) {
                    return tmpOppositeChain
                }
            }
        }
        return []
    }
}

extension CalcBrain {
    func cancelEqualTerms(mainNode: StepNode, otherParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
       
        // Conditions
        if fnCtrl.contains(.skipCancelEqualTerms) || !mainNode.exist {return}
        if !mainNode.parent!.isRoot || mainNode.level?.isZero ?? true {return}
        if mainNode.isPlusOrMinus {} else {return}
        let equalChain = getEqualChain(for: mainNode, in: otherParent)
        if equalChain.isEmpty || mainNode.hasRadicalFlat && !equalChain.isSimplestForm {return}
        if equalChain.flatTree.contains(where: {$0.isUndefinableZero}) {return}
        if equalChain.mayBeUndefinable {return}
        let mainChain = mainNode.highOpChain
        if fnCtrl.contains(.skipCancelIfWillRemain) {
            guard otherParent.children.filter({!equalChain.containsNode($0)}).containsEqualDirectTerms(nodes: equalChain) else {return}
        }
        
        // Stop Solving if boths sides are equal
        if mainChain.flatSKs(.any).keys == mainChain.first!.root.children.flatSKs(.any).keys && equalChain.flatSKs(.any).keys == equalChain.first!.root.children.flatSKs(.any).keys {
            if mainNode.root.children.isSimplestForm {} else {return}
            if fnCtrl.contains(.isInCheckingOurAnswer) {return}
            steps.setEquationIsTrue(nodeL: mainNode.isLeft ? mainNode : otherParent, nodeR: mainNode.isLeft ? otherParent : mainNode)
            return
        } else if mainChain.isZero {
            removeZero(node: mainNode, fnCtrl: fnCtrl + [.force], &steps)
            return
        }
        
        // Mark and explain
        steps.lastMarked = mainChain.flatSKs(.any) + equalChain.flatSKs(.any)
        let termOrNumberStr = mainChain.hasTerm || mainChain.hasFraction(flat: true) || mainChain.hasBrackets(.any) ? "terms" : "numbers"
        steps.lastExplanation = "Cancel equal \(termOrNumberStr) on both sides of the equation"
        if mainChain.count == 1 && !mainNode.isBrackets(.complete) {
            steps.lastStrikeKeys = [mainChain.first!.strikeKeyWithSymb, equalChain.first!.strikeKeyWithSymb]
        } else {
            let strikeKey1 = (mainChain.flatSKsForStrike[mainChain.flatSKsForStrike.count/2], mainChain.flatSKsForStrike.count)
            let strikeKey2 = (equalChain.flatSKsForStrike[equalChain.flatSKsForStrike.count/2], equalChain.flatSKsForStrike.count)
            steps.lastStrikeKeys = [strikeKey1, strikeKey2]
        }
        // Remove
        let mainParent = mainNode.parent!
        mainChain.removeNodesFromParent()
        equalChain.removeNodesFromParent()
        
        // Set level to zero if empty
        if mainNode.level!.isEmpty {
            mainParent.children = [StepNode.newZeroNode]
            steps.lastMarked.append(mainParent.children.first!.valueSK.first!)
        }
        if otherParent.children.isEmpty {
            otherParent.children = [StepNode.newZeroNode]
            steps.lastMarked.append(otherParent.children.first!.valueSK.first!)
        }
        
        // Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func getEqualChain(for node: StepNode, in otherParent: StepNode) -> [StepNode] {
        let chain = node.highOpChain
        for otherNode in otherParent.children {
            if otherNode.hasEqualOp(with: node) {
                let tmpChain = chain.clone(changeID: false, withParent: false).children
                let tmpEqualChain = otherNode.highOpChain
                if tmpEqualChain.isEqualHighOpChain(nodes: tmpChain) {
                    return tmpEqualChain
                }
            }
        }
        return []
    }
}
