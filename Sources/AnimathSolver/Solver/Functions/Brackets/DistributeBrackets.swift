//
//  DistributeBrackets.swift
//  Hulul
//
//  Created by Ahmad on 26/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func distributeBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if fnCtrl.contains(.skipDistribute) {return}
        let multChain = node.multChain(forward: false)
        if multChain.count > 1 && multChain.hasOnlyBrackets(.distributeReady) {} else {return}
        if multChain.first!.isInDenominatorAndWillAddFractions {return}
        if multChain.contains(where: {$0.children.hasOnlyFractions && $0.children.denominatorsParents.nodesAreEqual}) {return}
        if !fnCtrl.contains(.forceDistribute) && willDivideBothSides(nodeL: node.root, nodeR: node.otherSide) {return}
        let firstBrackets = multChain[0]
        let secondBrackets = multChain[1]
        if fnCtrl.isCheckAllowed {node.changeContent(); return}
        
        //
        let root = node.root
        solveNonLinearEq(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl, &steps)
        if root.children.flatTree.hasBrackets {} else {return}
        
        //
        let originalStepExprNoPow = firstBrackets.children.flatSKsNoPow + secondBrackets.children.flatSKsNoPow
        let originalStepExprOnlyPow = firstBrackets.children.flatSKsOnlyPow + secondBrackets.children.flatSKsOnlyPow
        
        //
        steps.lastMarked = firstBrackets.valueSK + secondBrackets.valueSK + originalStepExprNoPow + originalStepExprOnlyPow
        let areTwoBinomials = firstBrackets.children.count == 2 && secondBrackets.children.count == 2
        steps.lastExplanation = "Simplify the expression\(areTwoBinomials ? " using the FOIL method" : "")"

        //
        steps.lastStepSubsteps = [steps.last!]
        
        //
        steps.lastStepSubsteps.lastMarked = firstBrackets.flatSKs(.dropOp) + secondBrackets.valueSK + secondBrackets.children.getOps
        steps.lastStepSubsteps.lastExplanation = "Multiply each term in the first parentheses by each term in the second parentheses\(areTwoBinomials ? " (FOIL)" : "")"
        
        //
        var newContent = [StepNode]()
        for leftNode in firstBrackets.children {
            for rightNode in secondBrackets.children {
                let leftClone = !rightNode.isFirst ? leftNode.cloneWithChangedStaticIDs : leftNode.clone(changeID: false, withParent: false)
                let rightClone = !leftNode.isFirst ? rightNode.cloneWithChangedStaticIDs : rightNode.clone(changeID: false, withParent: false)
                if !rightNode.isFirst {
                    steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: leftNode.flatSKs.ids, clonesKeysIDs: [leftClone.flatSKs.ids])
                }
                if !leftNode.isFirst {
                    steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: rightNode.flatSKs.ids, clonesKeysIDs: [rightClone.flatSKs.ids])
                }
                if rightClone.isMinus {
                    if leftClone.isMinus {
                        rightClone.setSelfToBrackets()
                        steps.lastStepSubsteps.lastMarked.append(contentsOf: rightClone.valueSK)
                    } else {
                        leftClone.op = rightClone.op
                    }
                }
                rightClone.op = .times
                steps.lastStepSubsteps.lastMarked.append(contentsOf: leftClone.flatSKs + [rightClone.op])
                newContent.append(contentsOf: [leftClone, rightClone])
            }
        }
        
        //
        firstBrackets.children = newContent
        firstBrackets.valueSK[1] = secondBrackets.valueSK.last!
        secondBrackets.remove()
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipRemoveUslessBrktsWithMultiChild])
        
        //
        surfAndEvaluateAndApplyFnTillEnd(parent: firstBrackets, fnCtrl: fnCtrl + [.skipFlattenning, .skipRemoveUslessBrktsWithMultiChild], &steps.lastStepSubsteps)
        
        //
        firstBrackets.children.replaceSimilarKeys(with: originalStepExprNoPow, withPow: false)
        firstBrackets.children.allpowersFlattened.replaceSimilarKeys(with: originalStepExprOnlyPow, withPow: true)
        
        //
        steps.lastMarked.append(contentsOf: firstBrackets.flatSKs(.dropOp))
        
        //
        if !firstBrackets.isMinus && !firstBrackets.isMultipliedOrDivided {
            for step in steps.lastStepSubsteps.dropFirst() {
                step.markedSide(parentStep: steps.lastStep).flatTree.first(where: {$0.staticID == firstBrackets.staticID})!.justRemoveBrackets()
                for subStep in step.subSteps.dropFirst() {
                    if let firstBrktInSubStep = subStep.nodeL.flatTree.first(where: {$0.staticID == firstBrackets.staticID}) {
                        firstBrktInSubStep.justRemoveBrackets()
                    }
                }
            }
            firstBrackets.justRemoveBrackets()
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
