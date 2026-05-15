//
//  SplitStepsTo±.swift
//  Hulul
//
//  Created by Ahmad on 07/01/2023.
//  Copyright © 2023 Ahmad. All rights reserved.
//

extension CalcBrain {
    func seperateIntoTwoPlusAndMinusEquations(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fnCtrl.contains(.isInSplittedSteps) || fnCtrl.contains(.isInUndefinedSteps) {return}
        if nodeR.flatTree.contains(where: {$0.op.key == .plusMinus}) {} else {return}
        
        //
        let nodeL2 = nodeL.cloneWithChangedStaticIDs
        let nodeR2 = nodeR.cloneWithChangedStaticIDs

        //
        let plusMinusWasFirst = nodeR.children.first!.op.key == .plusMinus
        nodeR.flatTree.first(where: {$0.op.key == .plusMinus})!.op.key = .plus
        nodeR2.flatTree.first(where: {$0.op.key == .plusMinus})!.op = .minus
        
        //
        steps.lastMarked = nodeL.allNodesWithEqualStepExpr + nodeL2.allNodesWithEqualStepExpr
        
        steps.lastExplanation = "Seperate the equation into 2 possible cases"
        
        //
        steps.lastMultiSubSteps.append([StepModel()])
        stepsInit(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.skipPrintStep], steps: &steps.lastStepLastSplitStep)
        steps.lastStepLastSplitStep.lastStep.mergeIDs = steps.last!.mergeIDs
        
        //
        steps.lastMultiSubSteps.append([StepModel()])
        stepsInit(nodeL: nodeL2, nodeR: nodeR2, fnCtrl: fnCtrl + [.skipPrintStep], steps: &steps.lastStepLastSplitStep)
        steps.lastStepLastSplitStep.lastStep.mergeIDs = steps.last!.mergeIDs
        
        //
        steps.lastStep.appendCloneIDs(originalKeysIDs: nodeL.children.flatSKs.ids, clonesKeysIDs: [nodeL2.children.flatSKs.ids])
        steps.lastStep.appendCloneIDs(originalKeysIDs: [nodeR.valueSK.first!.id], clonesKeysIDs: [[nodeR2.valueSK.first!.id]])
        steps.lastStep.appendCloneIDs(originalKeysIDs: nodeR.children.flatSKs.ids, clonesKeysIDs: [nodeR2.children.flatSKs.ids])
        
        //
        steps.lastMarked.append(contentsOf: nodeR2.children.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl + [.skipMergeKeysPassing, .skipCopyStepTitle])
        steps.lastMultiSubSteps.append(contentsOf: steps.beforeLastStep.multiSubSteps.dropFirst())
        
        //
        if plusMinusWasFirst {
            nodeR.children.first!.op.changeID()
        }
        
        //
        surfAndEvaluateAndApplyFnAndSolveEqTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.isInSplittedSteps, .skipMergeI], &steps.lastStepBeforeLastSplitStep)
        rewriteExprWithIInStandardComplexForm(parent: nodeR, fnCtrl: fnCtrl, &steps.lastStepBeforeLastSplitStep)
        surfAndEvaluateAndApplyFnAndSolveEqTillEnd(nodeL: nodeL2, nodeR: nodeR2, fnCtrl: fnCtrl + [.isInSplittedSteps, .skipMergeI], &steps.lastStepLastSplitStep)
        rewriteExprWithIInStandardComplexForm(parent: nodeR2, fnCtrl: fnCtrl, &steps.lastStepLastSplitStep)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        steps.lastStep.multiSubSteps = steps.beforeLastStep.multiSubSteps.map({$0.areNotTitleNorUndefNorEmptySteps ? [$0.last!.clone] : $0})
        
        //
        checkSolutionBySubtituting(nodeL: nodeL, nodeR: nodeR, mainSteps: steps, fnCtrl: fnCtrl + [.isInSplittedSteps, .skipMergedKeysInCheckSolution, .skipEqualityCheck], &steps.lastStepBeforeLastSplitStep)
        checkSolutionBySubtituting(nodeL: nodeL2, nodeR: nodeR2, mainSteps: steps, fnCtrl: fnCtrl + [.isInSplittedSteps, .skipMergedKeysInCheckSolution, .skipEqualityCheck], &steps.lastStepLastSplitStep)
        removeWrongSolutions(fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func rewriteExprWithIInStandardComplexForm(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if parent.children.isFraction(part: .numerator, {$0.count == 1}) {return}
        guard let nodeWithIFLat = parent.children.first(where: {$0.hasIFlat}) else {return}
        if nodeWithIFLat.isFraction || !nodeWithIFLat.isLast {} else {return}
        
        //
        steps.lastMarked = parent.flatSKs
        steps.lastExplanation = "Rewrite the expression in standard complex form:"
        steps.lastNote = "a + bi"
        
        //
        if !nodeWithIFLat.isLast {
            parent.children = parent.children.dropNode(node: nodeWithIFLat) + [nodeWithIFLat]
        }
        
        if nodeWithIFLat.isFraction {
            guard let iCoeff = nodeWithIFLat.numerator.first(where: {$0.hasDirectI}) else {
                steps.setToUnableToSolve(nodeL: parent.root, nodeR: parent.otherSide)
                return
            }
            if !iCoeff.isLast {
                nodeWithIFLat.numerator = nodeWithIFLat.numerator.dropNode(node: iCoeff) + [iCoeff]
            }
            if nodeWithIFLat.numerator.count == 1 {
                let newOneNodeWithI = StepNode.newOneNode.withOp(.times).withSymb(symbs: [.newSymbNode(type: iCoeff.directI!.type!)])
                iCoeff.directI!.remove()
                nodeWithIFLat.insertAfter(newOneNodeWithI)
            } else {
                var fakeSteps = [StepModel()]
                parent.pinRootExpr()
                seperateFractionToRealAndI(fractionNode: nodeWithIFLat, fnCtrl: fnCtrl + [.skipPrintStep], &fakeSteps)
                if !parent.pinnedRootDidChange {
                    steps.setToUnableToSolve(nodeL: parent.root, nodeR: parent.otherSide)
                    return
                }
                steps.lastMarked.append(contentsOf: fakeSteps.allMarkedKeys)
                steps.lastCloneIDs.append(contentsOf: fakeSteps.beforeLastStep.cloneIDs)
            }
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func seperateFractionToRealAndI(fractionNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fractionNode.hasI && fractionNode.isFraction(.simplestReduced) {} else {return}
        if fractionNode.numerator.count == 2 {} else {return}
        let iCoeff = fractionNode.numerator.last!
        
        //
        steps.lastMarked = fractionNode.flatSKs
        steps.lastExplanation = "Rewrite the expression in standard complex form:"
        steps.lastNote = "a + bi"
        
        //
        fractionNode.numerator = [fractionNode.numerator.first!]
        
        //
        let newFraction = StepNode.newFractionNode
        newFraction.op = iCoeff.op
        iCoeff.op = .plus
        newFraction.numerator = [iCoeff]
        newFraction.denominator = fractionNode.denominator.cloneWithChangedStaticIDs
        
        //
        fractionNode.insertAfter(newFraction)
        
        //
        steps.lastMarked.append(contentsOf: newFraction.flatSKs)
        steps.lastStep.appendCloneIDs(originalKeysIDs: fractionNode.valueSK.ids, clonesKeysIDs: [newFraction.valueSK.ids])
        steps.lastStep.appendCloneIDs(originalKeysIDs: fractionNode.denominator.flatSKs(.dropPlus).ids, clonesKeysIDs: [newFraction.denominator.flatSKs(.dropPlus).ids])
        
        //
        let oneI = StepNode.newOneNode.withOp(.times).withSymb(symbs: [newFraction.allSymbs.first(where: {$0.type?.key == .imaginary})!])
        newFraction.numerator.first!.directSymbs.removeAll(where: {$0.type?.key == .imaginary})
        newFraction.insertAfter(oneI)
        
        //
        steps.lastMarked.append(newFraction.numerator.first!.valueSK.first!)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        determineChainSign(node: fractionNode, fnCtrl: fnCtrl + [.force], &steps)
        
        //
        reduceFraction(node: fractionNode, fnCtrl: fnCtrl + [.force], &steps)
    }
    
}
