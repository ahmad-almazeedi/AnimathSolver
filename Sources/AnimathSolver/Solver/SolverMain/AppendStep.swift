//
//  AppendStep.swift
//  Hulul
//
//  Created by Ahmad on 06/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func appendStep(_ steps: inout [StepModel], fnCtrl: [FnCtrl]) {
        
        //
        let nodeL = steps.last!.dynamicNodeL
        let nodeR = steps.last!.dynamicNodeR
        
        //
        setSurfedToTrue(nodes: nodeL.flatTree, markedKeys: steps.lastMarked)
        setSurfedToTrue(nodes: nodeR.flatTree, markedKeys: steps.lastMarked)
        if !fnCtrl.isKeepTargets {
            nodeL.setTargetedToFalse()
            nodeR.setTargetedToFalse()
        }
        
        // Flatten Substeps with main steps then exit
        if steps.last!.hasSubSteps && (fnCtrl.contains(.forceFlatSubsteps) || steps.last!.subSteps.count <= 2 || !fnCtrl.contains(.skipFlattenning) && !steps.first!.inMainSteps) {
            var preservedLastStep = steps.last!
            someNoStepsEnhancements(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl)
            someNoStepsEnhancements(nodeL: preservedLastStep.subSteps.last!.nodeL, nodeR: preservedLastStep.subSteps.last!.nodeR, fnCtrl: fnCtrl)
            steps.removeLast()
            preservedLastStep.subSteps[0].cloneIDs.append(contentsOf: preservedLastStep.cloneIDs)
            for i in 0..<preservedLastStep.subSteps.count-1 {
                preservedLastStep.subSteps[i].mergeIDs.append(contentsOf: preservedLastStep.mergeIDs)
            }
            preservedLastStep.subSteps.appendMergeIDs(mergedIDs: preservedLastStep.mergeIDs)
            steps.append(contentsOf: preservedLastStep.subSteps)
            if preservedLastStep.inMainSteps {
                steps[0].inMainSteps = true
            }
            if steps.first!.inMainSteps && !nodeL.forceStop && !nodeR.forceStop {
                setEvenRootOfNegativeToUndefined(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
            }
            return
        }
        
        //
        someNoStepsEnhancements(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl)
        
        //
        if fnCtrl.contains(.skipAppendStep) {return}
        
        //
        nodeL.changeStaticIDForStepIncIfOpChanged(with: steps.last!.nodeL)
        nodeR.changeStaticIDForStepIncIfOpChanged(with: steps.last!.nodeR)
        var step = StepModel(dynamicExprs: [Expression(nodeL: nodeL, nodeR: nodeR)], prevExprs: [Expression(nodeL: nodeL.cloneForStepIncrement, nodeR: nodeR.cloneForStepIncrement)])

        //
        if steps.count == 1 && fnCtrl.contains(.setInMainSteps) {
            step.inMainSteps = true
            steps.removeLast()
        } else if steps.last!.subSteps.count > 1 {
            steps.lastStep.subSteps.lastStep.explanation = steps.lastStep.subSteps[steps.lastStep.subSteps.count-2].explanation
            steps.lastStep.subSteps.lastStep.note = steps.lastStep.subSteps[steps.lastStep.subSteps.count-2].note
            steps.lastStep.subSteps.lastStep.markedKeys = steps.lastStep.subSteps[steps.lastStep.subSteps.count-2].markedKeys
            steps.appendMactchedMarkedKeysOfLastSubStepWithMain(mainWholeExpr: step.flatSKs(dropEqual: true))
        }
        
        //
        if !fnCtrl.contains(.skipPrintStep) && !steps.isEmpty && !fnCtrl.contains(.skipMergeKeysPassing) {
            step.mergeIDs.append(contentsOf: steps.last!.mergeIDs)
            while let equalIDInWholeExpr = steps.lastCloneIDs.map({$0.cloneMergeID}).first(where: {cloneID in steps.last!.flatSKs(dropEqual: false).ids.contains(cloneID)}) {
                while let cloneIdx = steps.lastCloneIDs.firstIndex(where: {$0.cloneMergeID == equalIDInWholeExpr}) {
                    let newID = Int32.random
                    steps.lastCloneIDs[cloneIdx].cloneMergeID = newID
                    step.appendMergeIDs(originalKeysIDs: [equalIDInWholeExpr], mergesKeysIDs: [[newID]])
                }
            }
        }
        
        //
        if !fnCtrl.contains(.skipCopyStepTitle), let titleStep = steps.last?.titleStep {
            step.copyTitleFrom(titleStep: titleStep)
        }
        
        //
#if DEBUG
        step.stepIdx = steps.count+1
#endif
        
        //
        steps.append(step)
        
        //
#if DEBUG
        if Global.printSteps {
            printGeneral(nodeL: nodeL, nodeR: nodeR, steps: &steps, step: step, fnCtrl: fnCtrl)
        }
#endif
        if !fnCtrl.contains(.skipPrintStep) {
            if steps.first!.inMainSteps && !fnCtrl.contains(.skipEqualityCheck) && !(steps.count >= 2 && steps.beforeLastStep.hasSplittedSteps) {
                checkEqualityForSteps(&steps)
            }
            if (steps.first!.inMainSteps || fnCtrl.contains(.forceSetNegRootToUndefCheck)) && !nodeL.forceStop && !nodeR.forceStop {
                setEvenRootOfNegativeToUndefined(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
                if !nodeL.forceStop {
                    if let undefinableZeroNode = [nodeL, nodeR].flatTree.first(where: {$0.isUndefinableZero}) {
                        removeZero(node: undefinableZeroNode, fnCtrl: fnCtrl, &steps)
                    }
                }
            }
        }
    }
}

extension CalcBrain {
    func setSurfedToTrue(nodes: [StepNode], markedKeys: [StepKey]) {
        if let idx = nodes.firstIndex(where: {markedKeys.contains($0.valueSK.first!)}) {
            for i in 0...idx {
                nodes[i].isSurfed = true
            }
        }
        for node in nodes.filter({!$0.isSurfed}) {
            if markedKeys.contains(node.valueSK.first!) {
                node.isSurfed = true
            }
        }
    }
    
    func someNoStepsEnhancements(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) {
        if !fnCtrl.contains(.skipRemoveUslessBrackets) {
            removeUselessBracketsNoSteps(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl)
        }
        updateSqrtsAfterSymbs(nodeL: nodeL, nodeR: nodeR)
        if fnCtrl.contains(.forceRemoveTimesFromTerms) || !fnCtrl.contains(.skipRemoveTimesFromTerms) {
            removeTimesFromTermsFromOutNoStep(nodeL: nodeL, nodeR: nodeR)
        }
    }
    
    func removeUselessBracketsNoSteps(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) {
        for node in (nodeL.flatTree + nodeR.flatTree).onlyBrackets {
            if node.op.key == .pow || !node.exist {continue}
            if node.isBrackets && node.nodeProduct?.isCommaNode ?? false {continue}
            if node.isBrackets && (node.children.count > 1 || node.children.isFraction(part: .numerator, {$0.count > 1})) && fnCtrl.contains(.skipRemoveUslessBrktsWithMultiChild) {continue}
            if node.isBrackets(.single(mayBePowered: true)) && node.isDivide && node.children.first!.isCoeff && !node.children.first!.isOneSingleTerm {continue}
            if node.isBrackets(.singlePos(mayBeFraction: true, fractionCase: .any, mayBePowered: true)) || (node.isFirst && node.isPlus && (node.isBrackets(.notPowered) && node.isAlone || node.isBrackets(.singleFraction(fractionCase: .any)))) || node.children.hasOnlyTimes && !node.children.isMinus && node.children.hasOnlyBrackets(.any) {} else {continue}
            if !node.valueSK.first!.isHiddenBracket {} else {continue}
            if node.isPowered && (node.children.count > 1 || node.children.isMinus || node.children.first!.isCoeff && !node.children.first!.isOneSingleTerm || node.children.isFraction || node.children.first!.isPowered || node.children.first!.directTerms.contains(where: {$0.isPowered})) {continue}
            if fnCtrl.contains(.justRemoveBrktInRmvUslsBrkt) {
                node.justRemoveBrackets()
            } else {
                node.removeBracketsGeneral()
            }
        }
        for node in nodeL.flatTree + nodeR.flatTree {
            if node.isFraction(.hasBrackets(.any, for: .any)) {
                if node.numerator.isBrackets(.any) && node.numerator.isPlus && !node.numerator.first!.isPowered {
                    if node.numerator.first!.children.count > 1 && fnCtrl.contains(.skipRemoveUslessBrktsWithMultiChild) {continue}
                    node.numerator.first!.removeBracketsGeneral()
                }
                if node.denominator.isBrackets(.any) && node.denominator.isPlus && !node.denominator.first!.isPowered {
                    if node.denominator.first!.children.count > 1 && fnCtrl.contains(.skipRemoveUslessBrktsWithMultiChild) {continue}
                    node.denominator.first!.removeBracketsGeneral()
                }
            } else if let radicalParent = node.radicalParent, radicalParent.children.isBrackets {
                if radicalParent.children.first!.isPlus && !radicalParent.children.first!.isPowered {
                    if radicalParent.children.first!.children.count > 1 && fnCtrl.contains(.skipRemoveUslessBrktsWithMultiChild) {continue}
                    radicalParent.children.first!.removeBracketsGeneral()
                }
            }
        }
    }
    
    func updateSqrtsAfterSymbs(nodeL: StepNode, nodeR: StepNode) {
        for radicalParent in nodeL.allRadicalsFlat + nodeR.allRadicalsFlat {
            if radicalParent.isAfterSymbs && radicalParent.coeffNode.isOneSingleTerm {
                radicalParent.isAfterSymbs = false
            }
        }
    }
    
    func removeTimesFromTermsFromOutNoStep(nodeL: StepNode, nodeR: StepNode) {
        for node in nodeL.flatTree + nodeR.flatTree {
            node.removeTimesFromTerm()
        }
    }
    
    private func printGeneral(nodeL: StepNode, nodeR: StepNode, steps: inout [StepModel], step: StepModel, fnCtrl: [FnCtrl]) {
        if fnCtrl.skipPrintStep {return}
        if steps.first!.inMainSteps {
            if steps.count == 1 {
                print("")
                print("Start:")
            }
            print("\(steps.count):   ", terminator: "")
            printNodesAndExpr(flatSKsTuple: step.flatSKsTuple, nodeL: nodeL, nodeR: nodeR)
            print("")
        } else {
            print("\(steps.first!.parentStepIdx).\(steps.count): ", terminator: "")
            printNodesAndExpr(flatSKsTuple: step.flatSKsTuple, nodeL: nodeL, nodeR: nodeR)
            print("")
        }
    }
    
    private func printNodesAndExpr(flatSKsTuple: ([StepKey],[StepKey]), nodeL: StepNode, nodeR: StepNode) {
        printExpression(keys: flatSKsTuple.0.keys)
        if !nodeR.isEmpty {
            print(" = ", terminator: "")
            printExpression(keys: flatSKsTuple.1.keys)
        }
        print("")
    }
}

extension CalcBrain {
    func checkEqualityForSteps(_ steps: inout [StepModel]) {
        guard steps.count > 1 else {return}
        if [steps.first!,steps.last!].contains(where: {$0.allNodes.flatKeys.contains(where: {$0.isVar && ![Key.x, Key.y, Key.z].contains($0)})}) {return}
        if steps.first!.nodeR.isEmpty {
            checkEqualityOfExprs(node1: steps.first!.nodeL, node2: steps.last!.nodeL, subtitutes: [[.three,.dot,.five],[.five,.dot,.five],[.seven,.dot,.five]], &steps)
        } else if steps.last!.nodeL.children.flatKeys == steps.beforeLastStepFlat.nodeL.children.flatKeys {
            checkEqualityOfExprs(node1: steps.last!.nodeR, node2: steps.beforeLastStepFlat.nodeR, subtitutes: [[.three,.dot,.five],[.five,.dot,.five],[.seven,.dot,.five]], &steps)
        } else if steps.last!.nodeR.children.flatKeys == steps.beforeLastStepFlat.nodeR.children.flatKeys {
            checkEqualityOfExprs(node1: steps.last!.nodeL, node2: steps.beforeLastStepFlat.nodeL, subtitutes: [[.three,.dot,.five],[.five,.dot,.five],[.seven,.dot,.five]], &steps)
        }
        if !steps.first!.nodeR.isEmpty && steps.last!.nodeL.isVarFromRoot(opCase: .plus) && !(steps.last!.nodeR.flatTree.hasVar || steps.last!.nodeR.allSymbsFlat.contains(where: {$0.valueKeys == [.notVarX]})) && steps.last!.nodeR.children.isSimplestForm {
            let mainVarKey = steps.last!.nodeL.children.first!.directVar!.type?.key
            let subtitute = steps.last!.nodeR.children.flatSKs(.dropPlus).keys
            var subtitutes: [[Key]] = [[.three,.dot,.five],[.five,.dot,.five],[.seven,.dot,.five]]
            if mainVarKey == .x {
                subtitutes[0] = subtitute
            } else if mainVarKey == .y {
                subtitutes[1] = subtitute
            } else if mainVarKey == .z {
                subtitutes[2] = subtitute
            } else {steps.setToUnableToSolve(nodeL: steps.last!.dynamicNodeL, nodeR: steps.last!.dynamicNodeR)}
            checkEqualityOfExprs(node1: steps.first!.nodeL, node2: steps.first!.nodeR, subtitutes: subtitutes, &steps)
        }
    }
    func checkEqualityOfExprs(node1: StepNode, node2: StepNode, subtitutes: [[Key]], _ steps: inout [StepModel]) {
        
        //
        if subtitutes.contains(where: {$0.contains(where: {$0 == .imaginary})}) {return}
        if [node1,node2].flatTree.contains(where: {$0.valueKeys.contains(where: {$0 == .questionMark || $0 == .imaginary}) || $0.isBrackets && $0.power.isFraction}) {return}
        
        // Set Results
        guard let originalResult = node1.children.getResult(subtitutes: subtitutes, allowNegEvenRoot: false) else {return}
        guard let lastStepResult = node2.children.getResult(subtitutes: subtitutes, allowNegEvenRoot: false) else {return}
        if originalResult == Double.codeForNegEvenRootCheck || lastStepResult == Double.codeForNegEvenRootCheck {return}
        if originalResult.isAlmostEqualWithConsiderations(to: lastStepResult) {return}
        
        // Display Error
        print("ERROR: \(originalResult) != \(lastStepResult)")
        steps.setToUnableToSolve(nodeL: node1, nodeR: node2)
    }
}
