//
//  FactorDiffOfTwoSqr.swift
//  Hulul
//
//  Created by Ahmad on 16/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func factorDiffOfTwoSquares(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var nodes: [StepNode] {parent.children}
        if nodes.count == 2 {} else {return}
        if [nodes.first!,nodes.last!].hasPlusAndMinus {} else {return}
        if nodes.first!.isBrackets {
            guard nodes.first!.powerValue.isMultiple(of: 2) else {return}
        } else {
            let aSqrtValue = nodes.first!.valueDouble.squareRoot()
            guard aSqrtValue.isWholeNumber else {return}
        }
        if nodes.last!.isBrackets {
            guard nodes.last!.powerValue.isMultiple(of: 2) else {return}
        } else {
            let cSqrtValue = nodes.last!.valueDouble.squareRoot()
            guard cSqrtValue.isWholeNumber else {return}
        }
        if nodes.directSymbs.contains(where: {!$0.powerValue.isMultiple(of: 2)}) {return}
        
        //
        parent.pinRootExpr()
        reduceAfterFactorPoly(brktNode: parent, fnCtrl: fnCtrl, &steps)
        if parent.pinnedRootDidChange {return}

        //
        if nodes.isMinus {
            flipPositionsOfTwoNodes(node1: nodes.first!, node2: nodes.last!, fnCtrl: fnCtrl, &steps)
        }
        
        //
        steps.lastStep.setTitle(title: "Factoring: \(nodes.flatSKs(.dropPlus).strForExpl)", subtitle: "Using Difference of Two Squares")
        
        // aNode as a²
        representNodeAsPowered(to: 2, node: nodes.first!, fnCtrl: fnCtrl, &steps)
        
        // cNode as c²
        representNodeAsPowered(to: 2, node: nodes.last!, fnCtrl: fnCtrl, &steps)

        //
        factorToBrktAndItsConjugate(parent: parent, fnCtrl: fnCtrl, &steps)
    }
    
    private func factorToBrktAndItsConjugate(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        steps.lastMarked = parent.flatSKs(.dropOp)
        steps.lastExplanation = "Use a²-b² = (a-b)(a+b) to factor the expression"

        //
        let nodes = parent.children
        if !parent.isBracketsNotHidden || parent.isBrackets(.powered) {
            nodes.setBrackets()
        }

        //
        nodes.removePowers()
        nodes.setBrackets()
        let brktNode = nodes.parent!
        let conjugateBrkt = brktNode.cloneWithChangedStaticIDs
        conjugateBrkt.op = .times
        conjugateBrkt.children.last!.flipSign()
        brktNode.insertAfter(conjugateBrkt)
        
        //
        steps.lastMarked.append(contentsOf: brktNode.flatSKs(.dropOp) + conjugateBrkt.flatSKs(.dropOp))
        
        //
        let parentIsToBeRemovedBrkts = parent.isBracketsNotHidden && !parent.isPowered
        let contentsHasBrkts = nodes.hasBrackets
        if parentIsToBeRemovedBrkts || contentsHasBrkts {
            if parentIsToBeRemovedBrkts {
                brktNode.valueSK = parent.valueSK
            } else if contentsHasBrkts {
                brktNode.valueSK = [nodes.flatSKs.first(where: {$0.key == .openBracket})!, nodes.flatSKs.last(where: {$0.key == .closeBracket})!]
            }
            if contentsHasBrkts {
                while let tmpBrktNode = (brktNode.children+conjugateBrkt.children).first(where: {$0.isBrackets}) {
                    tmpBrktNode.justRemoveBrackets()
                }
            }
            steps.lastStep.appendCloneIDs(originalKeysIDs: brktNode.valueSK.ids, clonesKeysIDs: [conjugateBrkt.valueSK.ids])
        }
        steps.lastStep.appendCloneIDs(originalKeysIDs: brktNode.children.flatSKs(.dropOp).ids, clonesKeysIDs: [conjugateBrkt.children.flatSKs(.dropOp).ids])
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipCopyStepTitle])

        //
        factorDiffOfTwoSquares(parent: brktNode.children.parent!, fnCtrl: fnCtrl, &steps)
        factorSumOrDiffOfTwoCubes(parent: brktNode.children.parent!, fnCtrl: fnCtrl, &steps)
        factorDiffOfTwoSquares(parent: conjugateBrkt, fnCtrl: fnCtrl, &steps)
        factorSumOrDiffOfTwoCubes(parent: conjugateBrkt, fnCtrl: fnCtrl, &steps)
    }
}
