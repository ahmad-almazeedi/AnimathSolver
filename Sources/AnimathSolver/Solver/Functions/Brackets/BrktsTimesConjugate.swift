//
//  BrktsTimesConjugate.swift
//  Hulul
//
//  Created by Ahmad on 14/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func evaluateBrktsTimesConjugate(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if fnCtrl.contains(.skipDistribute) {return}
        let multChain = node.multChain(forward: false)
        if multChain.count > 1 {} else {return}
        if multChain.onlyBrackets.contains(where: {$0.children.hasOnlyFractions && $0.children.denominatorsParents.nodesAreEqual}) {return}
        guard let firstBrackets = multChain.first(where: {$0.hasConjugate(in: multChain)}) else {return}
        guard let secondBrackets = multChain.first(where: {$0.isConjugate(of: firstBrackets)}) else {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
                
        //
        swapBracketsContentsIfAppropriate(firstBrackets: firstBrackets, secondBrackets: secondBrackets, fnCtrl: fnCtrl, &steps)
        
        //
        let originalFirstBrackets = firstBrackets.clone(changeID: false, withParent: false)
        let originalSecondBrackets = secondBrackets.clone(changeID: false, withParent: false)

        //
        guard let brktsWithMinus = [firstBrackets, secondBrackets].first(where: {$0.children.last!.isMinus})?.clone(changeID: false, withParent: false) else {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        
        //
        let withPlusFirst = firstBrackets.children.last!.isPlus
        steps.lastMarked = firstBrackets.flatSKs(.dropOp) + secondBrackets.flatSKs(.dropOp)
        steps.lastExplanation = "Use (a\(withPlusFirst ? "+" : "-")b)(a\(withPlusFirst ? "-" : "+")b) = a²-b² to simplify the product"
        
        // a²
        let aSqrd = firstBrackets.children.first!.clone(changeID: false, withParent: false)
        if aSqrd.shouldSetBrktIfPowered {
            aSqrd.setSelfToBrackets()
        }
        aSqrd.baseOrTermNode.power = [2.newNode]
        
        // b²
        let bSqrd = firstBrackets.children.last!.clone(changeID: false, withParent: false)
        if bSqrd.isMinus {
            bSqrd.op = .plus
        }
        if bSqrd.shouldSetBrktIfPowered {
            bSqrd.setSelfToBrackets()
        }
        bSqrd.op = firstBrackets.children.last!.isMinus ? firstBrackets.children.last!.op : brktsWithMinus.children.last!.op
        bSqrd.baseOrTermNode.power = [2.newNode]
        
        //
        let newContent = [aSqrd, bSqrd]
        steps.lastMarked.append(contentsOf: newContent.flatSKs)
        
        //
        secondBrackets.remove()
        firstBrackets.children = newContent
        
        //
        if firstBrackets.mayRemoveBrackets {
            firstBrackets.justRemoveBrackets()
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: originalFirstBrackets.children.first!.flatSKs.ids, mergesKeysIDs: [originalSecondBrackets.children.first!.flatSKs.ids])
        steps.appendMergeIDs(originalKeysIDs: originalFirstBrackets.children.last!.flatSKs(.dropOp).ids, mergesKeysIDs: [originalSecondBrackets.children.last!.flatSKs(.dropOp).ids])
        
        //
        surfAndEvaluateAndApplyFnTillEnd(parent: newContent.first!.parent!, fnCtrl: fnCtrl + [.skipAddition], &steps)
    }
}

extension CalcBrain {
    private func swapBracketsContentsIfAppropriate(firstBrackets: StepNode, secondBrackets: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if firstBrackets.children.first!.isEqualTo(node: secondBrackets.children.first!) {return}
        
        //
        if firstBrackets.children.last!.isEqualTo(node: secondBrackets.children.last!) {
            swapTwoChildren(bracketsNode: firstBrackets, fnCtrl: fnCtrl, &steps)
            swapTwoChildren(bracketsNode: secondBrackets, fnCtrl: fnCtrl, &steps)
        } else if firstBrackets.children.first!.isEqualTo(node: secondBrackets.children.last!) {
            swapTwoChildren(bracketsNode: secondBrackets, fnCtrl: fnCtrl, &steps)
        } else {
            swapTwoChildren(bracketsNode: firstBrackets, fnCtrl: fnCtrl, &steps)
        }
    }

    func swapTwoChildren(bracketsNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let brktsChildren = bracketsNode.children
        
        //
        steps.lastMarked = brktsChildren.flatSKs
        steps.lastExplanation = UseCommutativePropExplanation
        
        //
        bracketsNode.children = brktsChildren.reversed()
        
        //
        if !brktsChildren.hasPlusAndMinus && brktsChildren.isPlus {
            let opHolder = brktsChildren.first!.op
            brktsChildren.first!.op = brktsChildren.last!.op
            brktsChildren.last!.op = opHolder
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
