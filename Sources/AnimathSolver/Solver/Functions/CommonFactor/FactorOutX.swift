//
//  FactorOutX.swift
//  Hulul
//
//  Created by Ahmad on 01/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func factorOutX(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if nodeL.allNodes.allSymbs.shouldMoveAllToSide {return}
        if nodeL.children.isSimplestFormNegletTimesBracket && nodeR.children.isSimplestForm {} else {return}
        let tmpXMults = nodeL.children.filter({$0.isMultiplied && $0.isNumber(mayBePowered: false)})
        if !tmpXMults.isEmpty && tmpXMults.contains(where: {!($0.isOneSymb && $0.symbIsVar && $0.isTimes)}) {return}
        if nodeL.children.hasFraction(flat: true) {return}
        if nodeL.children.hasVar && !nodeR.children.hasVar {} else {return}
        guard let xMultiSymbNode = nodeL.children.first(where: {$0.hasVar && $0.hasMultiSymbs && $0.hasSingleVar && $0.hasEqualVarAndPower(in: nodeL.children)}) else {return}
        let xNodes = nodeL.children.filter({$0.hasVar && xMultiSymbNode.directSymbs.first(where: {$0.isVar})!.powerValue == $0.directSymbs.first(where: {$0.isVar})!.powerValue})
        if xNodes.count > 1 {} else {return}
        
        //
        let brktNode = StepNode.newBracketsNode
        xNodes.first!.insertBefore(brktNode)
        xNodes.removeNodesFromParent()
        brktNode.children = xNodes
        let xFactorNode = StepNode.newOneNode
        xFactorNode.directSymbs = [xNodes.last!.directSymbs.first(where: {$0.isVar})!.clone(changeID: false, withParent: false)]
        extractCommonFactorFromBrackets(node: brktNode, factorNode: xFactorNode, fnCtrl: fnCtrl + [.extractCmnFctrFromRight], &steps)
        let mergeIDs = steps.lastMergeIDs
        steps.removeLast()
        brktNode.op = xFactorNode.op
        xFactorNode.op = .times
        steps.lastMarked.append(xFactorNode.op)
        xFactorNode.remove()
        brktNode.insertAfter(xFactorNode)

        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.lastMergeIDs = mergeIDs
        
        //
        factorOutX(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
}
