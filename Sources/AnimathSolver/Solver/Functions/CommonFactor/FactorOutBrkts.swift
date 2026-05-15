//
//  FactorOutBrkts.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func factorOutBrkts(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if node.isTerm {return}
        guard let level = node.level else {return}
        guard level.is4TermsFactorable else {return}
        guard let firstBrackets = level.first(where: {$0.isBrackets({$0.isSimplestFormMulti})}) else {return}
        let allBrackets = level.onlyBrackets
        
        // Set
        var multiplierNodes = allBrackets.map({
            if let multiplierNode = $0.multiplierNode {
                return multiplierNode
            }
            return StepNode.newOneNode.withOp($0.op)
        })
        multiplierNodes = multiplierNodes.map({$0.withOp($0.isTimes ? $0.prev.op : $0.op, clone: false)})
        
        //
        steps.lastMarked = allBrackets.map({$0.flatSKs(.dropOp)}).flatMap({$0})
        steps.lastExplanation = "Factor out \(firstBrackets.children.flatSKs(.dropPlus).strForExpl) from the expression"
        
        //
        if firstBrackets.isTimes {
            firstBrackets.op = firstBrackets.prev.op
        }
        allBrackets.dropNode(node: firstBrackets).removeNodesFromParent()
        let multsParentBrkt = StepNode.newBracketsNode.withOp(.times)
        multiplierNodes.removeNodesFromParent()
        multsParentBrkt.children = multiplierNodes
        firstBrackets.insertAfter(multsParentBrkt)
        steps.lastMarked.append(contentsOf: multsParentBrkt.opValueSK)
        
        //
        if firstBrackets.isMinus {
            multiplierNodes.flipSigns()
            multiplierNodes.first(where: {$0.op.id == firstBrackets.op.id})!.op.changeID()
            steps.lastMarked.append(contentsOf: firstBrackets.flatSKs + multsParentBrkt.flatSKs)
            steps.lastExplanation = "Factor out \(firstBrackets.flatSKs.strForExpl) from the expression"
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipCopyStepTitle])
        
        //
        steps.appendMergeIDs(originalKeysIDs: firstBrackets.flatSKs(.dropOp).ids, mergesKeysIDs: allBrackets.dropNode(node: firstBrackets).map({$0.flatSKs(.dropOp).ids}))
    }
}
