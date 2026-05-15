//
//  EvaluateDivision.swift
//  Hulul
//
//  Created by Ahmad on 27/01/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func evaluateDivision(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        var defaultChain = node.divideDefaultChain
        if defaultChain.count > 1 && defaultChain.last!.isDivide {} else {return}
        if defaultChain.last!.isDecimal {return}
        let resultNode = defaultChain.clone(changeID: false, withParent: false).children.getResultNodeForHighOp(returnSymbs: true)
        if resultNode.isBrackets(.complete) {return}
        if defaultChain.count > 2 && defaultChain.hasDecimal {return}
        if defaultChain.first!.isDividableBy(node: defaultChain.last!, mayEqual: true) {return}
        if (fnCtrl.isForced || defaultChain.count > 2) && !resultNode.valueSK.keys.contains(.dot) && (fnCtrl.isForced || defaultChain.dropLast().getResultNodeForHighOp(returnSymbs: true).valueDouble <= 30) {} else {return}
        guard let firstIdx = node.idx else {return}

        // Multiply First
        if defaultChain.contains(where: {$0.isTimes}) {
            evaluateMult(node: defaultChain.first!, fnCtrl: fnCtrl + [.force, .skipSymbMultOrOrder], &steps)
        }
        defaultChain = node.level![firstIdx].divideDefaultChain
        if defaultChain.count != 2 || !defaultChain.last!.isDivide || defaultChain.isDivide {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }

        // Mark and explain
        steps.lastMarked = defaultChain.flatSKs(defaultChain.last!.isBrackets(.singleNeg(mayBePowered: false)) ? .any : .onlyMinus)
        steps.lastExplanation = "Divide the numbers"
        
        // Replace nodes with result
        node.level!.replaceNodesWithResult(nodes: defaultChain, resultNode: resultNode)
        
        // Mark and append
        steps.lastMarked.append(contentsOf: resultNode.flatSKs(.any))
        if !defaultChain.isMinus && resultNode.op == defaultChain.op {
            steps.lastMarked.removeAll(where: {$0 == resultNode.op})
        }
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
