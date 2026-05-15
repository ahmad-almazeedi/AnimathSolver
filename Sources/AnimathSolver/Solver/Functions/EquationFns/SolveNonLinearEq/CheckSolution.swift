//
//  CheckSolution.swift
//  Hulul
//
//  Created by Ahmad on 14/01/2023.
//  Copyright © 2023 Ahmad. All rights reserved.
//

extension CalcBrain {
    func checkSolutionBySubtituting(nodeL: StepNode, nodeR: StepNode, mainSteps: [StepModel], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if mainSteps.first!.isEquation {} else {return}
        if nodeL.resultCase == .none {} else {return}
        if nodeL.children.isOneSingleVar(mayBeInSqrt: false) && !nodeL.children.first!.directVar!.isPowered && !nodeR.children.hasVarFlat {} else {return}
        if nodeL.allNodes.hasIFlat {return}
        if steps.last!.hasOtherSteps {return}
        let substituteNodes = nodeR.children
        let substitute = substituteNodes.flatSKs(.dropPlus).keys
        if substitute.contains(.notVarX) {return}
        if (mainSteps+steps).hasEvenRadVar {} else {
            guard let originalResult = mainSteps.first!.nodeL.children.getResult(subtitutes: [substitute], allowNegEvenRoot: true)?.operationResultRounded(precision: 12, isError: false) else {return}
            guard let lastStepResult = mainSteps.first!.nodeR.children.getResult(subtitutes: [substitute], allowNegEvenRoot: true)?.operationResultRounded(precision: 12, isError: false) else {return}
            if originalResult.isNaN || lastStepResult.isNaN {return}
            if String(originalResult).contains("e-") && String(lastStepResult).contains("e-") {return}
            if originalResult.isAlmostEqualWithConsiderations(to: lastStepResult) {return}
        }
        
        //
        let originalStep = steps.last!
        
        //
        guard let varStr = nodeL.children.first?.directVar?.type?.key.title else {return}
        let substitureStr = substituteNodes.flatSKs(.dropPlus).strForExpl

        //
        steps.lastMarked = nodeL.flatSKs(dropEqual: false)
        steps.lastExplanation = "Substitute \(substitureStr) in the original equation to check if it's a valid solution"
        
        //
        nodeL.children = mainSteps.first!.nodeL.children.clones(changeID: true, withParent: false)
        nodeR.children = mainSteps.first!.nodeR.children.clones(changeID: true, withParent: false)
        
        //
        let wholeEqSKs = nodeL.flatSKs(dropEqual: false).str
        let substitureStrForTitle = substituteNodes.flatSKs(.dropPlus).str
        steps.lastStep.setTitle(title: "Checking our answer", subtitle: "By substituting #\(substitureStrForTitle)# in #\(wholeEqSKs)")
        
        //
        for node in nodeL.allNodes.flatTree {
            if !node.directVars.isEmpty {
                for directVar in node.directVars {
                    let varPowerNodes = directVar.power
                    if !node.isOneSingleTerm {
                        node.extractTerm(directVar)
                    }
                    let newCoeff = directVar.coeffNode
                    newCoeff.setBracketsAndExtractOp()
                    let newBrkts = newCoeff.parent!
                    if !newBrkts.isBrackets {
                        steps.setToUnableToSolve(nodeL: nodeL.root, nodeR: nodeR.otherSide)
                        return
                    }
                    newBrkts.power = varPowerNodes
                    newCoeff.removeTerms()
                    newCoeff.replace(with: substituteNodes.clones(changeID: true, withParent: false), withOp: false)
                    if !fnCtrl.contains(.skipMergedKeysInCheckSolution) {
                        steps.lastStep.appendCloneIDs(originalKeysIDs: substituteNodes.flatSKs(.dropPlus).ids, clonesKeysIDs: [newBrkts.children.flatSKs(.dropPlus).ids])
                    }
                }
            }
        }
        
        //
        steps.lastMarked.append(contentsOf: nodeL.allNodes.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl)
       
        //
        if fnCtrl.contains(.isInSplittedSteps) {
            setEvenRootOfNegativeToUndefined(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl.drop(.skipMergeFraction) + [.skipFlattenning, .forceSetNegRootToUndefCheck], &steps)
        } else {
            surfAndEvaluateAndApplyFnTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl.drop(.skipMergeFraction) + [.skipFlattenning, .forceSetNegRootToUndefCheck, .isInCheckingOurAnswer], &steps)
        }
        if !nodeL.isUndefined && !nodeL.children.isEqualTo(nodes: nodeR.children) {
            findApproximateValue(nodes: nodeL.children, fnCtrl: fnCtrl + [.force], steps: &steps)
            findApproximateValue(nodes: nodeR.children, fnCtrl: fnCtrl + [.force], steps: &steps)
        }
        
        //
        if fnCtrl.contains(.isInSplittedSteps) {
            appendStep(&steps, fnCtrl: fnCtrl)
        }
        
        //
        if nodeL.isUndefined {
            appendStep(&steps, fnCtrl: fnCtrl + [.skipCopyStepTitle])
        }
        
        //
        if nodeL.isUndefined {
            steps.lastExplanation = "Since the equation is undefined for \(varStr) = \(substitureStr), the equation has no solution"
            steps.lastNote = "No Solution"
            steps.lastStep.nodeL.resultCase = .falseForAnyX
            steps.lastStep.nodeR.resultCase = .falseForAnyX
            nodeL.resultCase = .falseForAnyX
            nodeR.resultCase = .falseForAnyX
            steps[0].shouldShowMainStep = true
        }
        
        //
        else if !nodeL.children.isEqualTo(nodes: nodeR.children) {
            if fnCtrl.contains(.isInSplittedSteps) {
                steps.removeLast()
            }
            steps.lastMarked = nodeL.flatSKs(dropEqual: false)
            steps.lastExplanation = "The equality is false, therefore \(varStr)=\(substitureStr) is not a solution of the equation"
            if fnCtrl.contains(.isInSplittedSteps) {
                nodeL.children = originalStep.nodeL.children.clones(changeID: false, withParent: false)
                nodeR.children = originalStep.nodeR.children.clones(changeID: false, withParent: false)
                nodeR.children.replaceSimilarKeys(with: steps.last!.nodeR.children.flatSKs, withPow: true)
                steps.lastMarked.append(contentsOf: nodeL.flatSKs(dropEqual: false))
                appendStep(&steps, fnCtrl: fnCtrl + [.skipCopyStepTitle])
                steps.last!.nodeR.valueSK = [.notEqual.withID(Int32.randomEven)] // To distinguish with notEqual of determineTheDefinedRangeFor
                steps.beforeLastStep.markedKeys.append(steps.last!.nodeR.valueSK.first!)
            } else {
                steps.lastStep.removeTitleStep()
                steps.lastStep.nodeL.resultCase = .falseForAnyX
                steps.lastStep.nodeR.resultCase = .falseForAnyX
                nodeL.resultCase = .falseForAnyX
                nodeR.resultCase = .falseForAnyX
                steps.lastNote = "No Solution"
            }
        }
        
        //
        else {
            if fnCtrl.contains(.isInSplittedSteps) {
                steps.removeLast()
            }
            steps.lastMarked = nodeL.flatSKs(dropEqual: false)
            steps.lastExplanation = "The equality is true, therefore \(varStr)=\(substitureStr) is a solution of the equation"
            nodeL.children = originalStep.nodeL.children.clones(changeID: false, withParent: false)
            nodeR.children = originalStep.nodeR.children.clones(changeID: false, withParent: false)
            nodeR.children.replaceSimilarKeys(with: steps.last!.nodeR.children.flatSKs, withPow: true)
            steps.lastMarked.append(contentsOf: nodeL.flatSKs(dropEqual: false))
            appendStep(&steps, fnCtrl: fnCtrl + [.skipCopyStepTitle])
        }
    }
}

extension CalcBrain {
    func removeWrongSolutions(fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        guard let splittedSteps = steps.last!.splittedSteps else {return}
        let wrongCount = splittedSteps.onlyWrongSolutions.count
        if wrongCount == 0 {return}
        
        //
        if splittedSteps.count == wrongCount {
            
            //
            steps.lastStepLastSplitStep.setEquationIsFalseForSpliSteps(nodeL: steps.lastStepLastSplitStep.last!.dynamicNodeL, nodeR: steps.lastStepLastSplitStep.last!.dynamicNodeR)
            
            //
            steps.last!.nodeL.resultCase = .falseForAnyX
            
        } else {
            
            //
            steps.lastStepLastSplitStep.lastExplanation = "The equation has only \(wrongCount) solution\(wrongCount == 1 ? "" : "s")"
            appendStep(&steps.lastStepLastSplitStep, fnCtrl: fnCtrl)
            
            //
            appendStep(&steps, fnCtrl: fnCtrl)
            
            //
            steps.lastMultiSubSteps.append(contentsOf: splittedSteps.dropWrongSolutions.map({[$0.last!.clone]}))
        }
    }
}
