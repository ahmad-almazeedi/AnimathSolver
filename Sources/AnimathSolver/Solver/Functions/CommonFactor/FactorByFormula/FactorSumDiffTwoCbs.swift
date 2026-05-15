//
//  FactorDiffOrSum.swift
//  Hulul
//
//  Created by Ahmad on 16/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func factorSumOrDiffOfTwoCubes(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var newParent = parent
        var nodes: [StepNode] {newParent.children}
        if nodes.count == 2 {} else {return}
        if nodes.first!.isBrackets {
            guard nodes.first!.powerValue.isMultiple(of: 3) else {return}
        } else {
            let aCbrtValue = pow(nodes.first!.valueDouble, 1/3).rounded
            guard aCbrtValue.isWholeNumber else {return}
        }
        if nodes.last!.isBrackets {
            guard nodes.last!.powerValue.isMultiple(of: 3) else {return}
        } else {
            let cCbrtValue = pow(nodes.last!.valueDouble, 1/3).rounded
            guard cCbrtValue.isWholeNumber else {return}
        }
        if nodes.directSymbs.contains(where: {!$0.powerValue.isMultiple(of: 3)}) {return}

        //
        parent.pinRootExpr()
        reduceAfterFactorPoly(brktNode: parent, fnCtrl: fnCtrl, &steps)
        if parent.pinnedRootDidChange {return}

        //
        if nodes.isMinus {
            if nodes.last!.isMinus {
                extractCommonFactor(nodes: nodes, withOp: true, fnCtrl: [.forceExtractMinus], &steps)
                newParent = newParent.children.first(where: {$0.isBrackets}) ?? newParent
            } else {
                flipPositionsOfTwoNodes(node1: nodes.first!, node2: nodes.last!, fnCtrl: fnCtrl, &steps)
            }
        }
        
        //
        let isSum = nodes.hasOnlyPlus
        steps.lastStep.setTitle(title: "Factoring: \(nodes.flatSKs(.dropPlus).strForExpl)", subtitle: "Using \(isSum ? "Sum" : "Difference") of Two Cubes")
        
        // aNode as a³
        representNodeAsPowered(to: 3, node: nodes.first!, fnCtrl: fnCtrl, &steps)
        
        // cNode as c³
        representNodeAsPowered(to: 3, node: nodes.last!, fnCtrl: fnCtrl, &steps)

        //
        factorToBiAndTri(parent: newParent, fnCtrl: fnCtrl, &steps)
    }
    
    private func factorToBiAndTri(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let isSum = parent.children.hasOnlyPlus
        
        //
        steps.lastMarked = parent.flatSKs(.dropOp)
        steps.lastExplanation = "Use " + (isSum ? "a³+b³ = (a+b)(a²-ab+b²)" : "a³-b³ = (a-b)(a²+ab+b²)") + " to factor the expression"

        //
        let nodes = parent.children
        if !parent.isBracketsNotHidden || parent.isBrackets(.powered) {
            nodes.setBrackets()
        }

        //
        nodes.removePowers()
        nodes.setBrackets()
        let biBrkts = nodes.parent!
        let triBrkts = StepNode.newBracketsNode
        triBrkts.op = .times
        biBrkts.insertAfter(triBrkts)

        //
        let aSqrd = biBrkts.children.first!.cloneWithChangedStaticIDs
        aSqrd.baseOrTermNode.power = [2.newNode]
        let bSqrd = biBrkts.children.last!.cloneWithChangedStaticIDs.withOp(.plus, clone: false)
        bSqrd.baseOrTermNode.power = [2.newNode]
        let abNodes = [biBrkts.children.first!.cloneWithChangedStaticIDs.withOp(isSum ? .minus : .plus, clone: false), biBrkts.children.last!.cloneWithChangedStaticIDs.withOp(.times, clone: false)]
        triBrkts.children = [aSqrd] + abNodes + [bSqrd]

        //
        steps.lastMarked.append(contentsOf: biBrkts.flatSKs(.dropOp) + triBrkts.flatSKs(.dropOp))
        
        //
        if parent.isBracketsNotHidden && !parent.isPowered {
            biBrkts.valueSK = parent.valueSK
        } else if nodes.hasBrackets {
            biBrkts.valueSK = [nodes.flatSKs.first(where: {$0.key == .openBracket})!, nodes.flatSKs.last(where: {$0.key == .closeBracket})!]
        }
        if nodes.hasBrackets {
            for tmpBrktNode in (triBrkts.children+biBrkts.children).filter({$0.isBrackets}) {
                tmpBrktNode.removeBracketsIfAppropriate()
            }
        }
        steps.lastStep.appendCloneIDs(originalKeysIDs: biBrkts.children.first!.flatSKs(.dropOp).ids, clonesKeysIDs: [triBrkts.children.first!.flatSKs(.dropOp).ids, triBrkts.children[1].flatSKs(.dropOp).ids])
        steps.lastStep.appendCloneIDs(originalKeysIDs: biBrkts.children.last!.flatSKs(.dropOp).ids, clonesKeysIDs: [triBrkts.children.last!.flatSKs(.dropOp).ids, triBrkts.children[2].flatSKs(.dropOp).ids])
        if parent.isBracketsNotHidden {
            steps.lastStep.appendCloneIDs(originalKeysIDs: biBrkts.valueSK.ids, clonesKeysIDs: [triBrkts.valueSK.ids])
        }

        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        distributePowerIntoBrackets(node: triBrkts.children.first!, fnCtrl: fnCtrl + [.force], &steps)
        evaluatePow(node: triBrkts.children.first!, fnCtrl: fnCtrl + [.force], &steps)
        surfAndEvaluateAndApplyFnTillEnd(parent: triBrkts, fnCtrl: fnCtrl, &steps)
        
        //
        steps.lastStep.multiSubSteps.removeAll(where: {$0.first?.isTitleStep ?? false})
        
        //
        factorDiffOfTwoSquares(parent: biBrkts.children.parent!, fnCtrl: fnCtrl, &steps)
        factorSumOrDiffOfTwoCubes(parent: biBrkts.children.parent!, fnCtrl: fnCtrl, &steps)
    }
}
