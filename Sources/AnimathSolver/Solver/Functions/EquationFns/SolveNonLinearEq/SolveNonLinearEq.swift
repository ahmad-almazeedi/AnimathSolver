//
//  SolveByFactoring.swift
//  Hulul
//
//  Created by Ahmad on 29/12/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func solveNonLinearEq(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fnCtrl.contains(.skipRootSidesOrSolveNonLinear) || fnCtrl.contains(.isInUndefinedSteps) {return}
        if nodeL.allNodes.hasMultiVarFlat {return}
        if nodeL.children.isSmplstFormOrMultChainOrIs4TermsFactorable && nodeR.children.isZero(opCase: .plus) {} else {return}
        
        //
        if nodeR.isLeft {
            swapSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.force], &steps)
            solveNonLinearEq(nodeL: nodeR, nodeR: nodeL, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        factorPolynomial(parent: nodeL, fnCtrl: fnCtrl, &steps)
                
        //
        if nodeL.children.count > 1 && nodeL.children.isMultChain && !nodeL.children.contains(where: {!$0.hasVarFlat}) {}
        else if nodeL.children.isBrackets(.powered) {
            rootBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
            if nodeL.children.count > 1 && nodeL.children.isMultChain && !nodeL.children.contains(where: {!$0.hasVarFlat}) {} else {return}
        } else {
            solveByQuadraticFormula(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        for node in nodeL.children.onlyBrackets {
            factorPolynomial(parent: node, fnCtrl: fnCtrl + [.skipExtractCommonFactor], &steps)
        }
        
        //
        if fnCtrl.contains(.isInSplittedSteps) {
            steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
            return
        }
        
        //
        steps.lastMarked = [nodeR.valueSK.first!,nodeR.children.first!.valueSK.first!]
        steps.lastExplanation = "Seperate the equation into \(nodeL.children.count) possible cases using the rule:"
        steps.lastNote = "If  ab = 0  then  a = 0  or  b = 0"

        let allBrackets = nodeL.children
        
        //
        nodeL.children = [allBrackets.first!]
        steps.lastMultiSubSteps.append([StepModel()])
        stepsInit(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.skipPrintStep], steps: &steps.lastStepLastSplitStep)
        steps.lastStepLastSplitStep.lastStep.mergeIDs = steps.last!.mergeIDs
        
        //
        for node in allBrackets.dropFirst {
            let newNodeL = StepNode().withChildren(children: [node.withOp(.plus, clone: false)])
            let newNodeR = nodeR.cloneWithChangedStaticIDs
            steps.lastMarked.append(newNodeR.children.first!.valueSK.first!)
            steps.lastMultiSubSteps.append([StepModel()])
            stepsInit(nodeL: newNodeL, nodeR: newNodeR, fnCtrl: fnCtrl + [.skipPrintStep], steps: &steps.lastStepLastSplitStep)
            steps.lastStepLastSplitStep.lastStep.mergeIDs = steps.last!.mergeIDs
            steps.lastStep.appendCloneIDs(originalKeysIDs: [nodeR.valueSK.first!.id], clonesKeysIDs: [[newNodeR.valueSK.first!.id]])
            steps.lastStep.appendCloneIDs(originalKeysIDs: [nodeR.children.first!.valueSK.first!.id], clonesKeysIDs: [[newNodeR.children.first!.valueSK.first!.id]])
        }

        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipMergeKeysPassing])
        steps.lastMultiSubSteps.append(contentsOf: steps.beforeLastStep.multiSubSteps.dropFirst())
        
        //
        for i in 1..<steps.last!.multiSubSteps.count {
            if steps.last!.multiSubSteps[i].first!.isTitleStep || steps.last!.multiSubSteps[i].last!.isUndefinedNodeStep {continue}
            surfAndEvaluateAndApplyFnAndSolveEqTillEnd(nodeL: steps.lastStep.multiSubSteps[i].first!.dynamicNodeL, nodeR: steps.lastStep.multiSubSteps[i].first!.dynamicNodeR, fnCtrl: fnCtrl + [.isInSplittedSteps, .skipMergeI], &steps.lastStep.multiSubSteps[i])
            if !steps.last!.multiSubSteps[i].last!.nodeL.children.isOneSingleVar(mayBeInSqrt: false) || (steps.last!.multiSubSteps[i].last!.nodeR.hasIFlat || steps.last!.multiSubSteps[i].last!.nodeR.children.contains(where: {$0.op.key == .plusMinus})) && steps.hasEvenRadVar {
                steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
                return
            }
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.lastStep.multiSubSteps = steps.beforeLastStep.multiSubSteps.map({$0.areNotTitleNorUndefNorEmptySteps ? [$0.last!.clone] : $0})
        
        //
        for i in 1..<steps.last!.multiSubSteps.count {
            if steps.last!.multiSubSteps[i].areNotTitleNorUndefNorEmptySteps {} else {continue}
            checkSolutionBySubtituting(nodeL: steps.lastStep.multiSubSteps[i].first!.dynamicNodeL, nodeR: steps.lastStep.multiSubSteps[i].first!.dynamicNodeR, mainSteps: steps, fnCtrl: fnCtrl + [.isInSplittedSteps, .skipEqualityCheck], &steps.lastStep.multiSubSteps[i])
        }
        removeWrongSolutions(fnCtrl: fnCtrl, &steps)
    }
}
