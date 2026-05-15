//
//  xMultiplication.swift
//  Hulul
//
//  Created by Ahmad on 16/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func isVarMultiplication(nodeL: StepNode, nodeR: StepNode) -> Bool {
        let allNodes = nodeL.children + nodeR.children
        if !allNodes.contains(where: {!$0.isFraction}) {} else {return false}
        if nodeL.children.count == 1 && nodeR.children.count == 1 {} else {return false}
        if allNodes.contains(where: {$0.numerator.isVar(firstDeg: true)}) && allNodes.flatTree.filter({!$0.isFraction && $0.symbIsVar}).count == 1 {return false}
        return true
    }
    
    func xMultiplication(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if fnCtrl.isCheckAllowed && nodeL.children.first!.isCommaNode {return}
        if isMultBothSidesCommonConditions(nodeL: nodeL, nodeR: nodeR) {} else {return}
        let allNodes = nodeL.children + nodeR.children
        if nodeL.children.isFraction && nodeR.children.isFraction {} else {return}
        if allNodes.hasNestedFraction {return}
        if allNodes.contains(where: {$0.numerator.isVar(firstDeg: true)}) && allNodes.flatTree.filter({!$0.isFraction && $0.symbIsVar}).count == 1 {return}
        if allNodes.filter({$0.hasVarFlat}).count == 1 && allNodes.contains(where: {$0.numerator.count == 1 && $0.numerator.hasVar && $0.numerator.first!.isOneSingleSymb}) {return}
        if !allNodes.contains(where: {$0.isFraction && $0.denominator.isOneSingleVar(mayBeInSqrt: true)}) && allNodes.onlyFractions.numeratorsParents.allSatisfy({$0.children.count == 1}) && allNodes.numeratorChain.nodesHaveEqualBase && !allNodes.numeratorChain.first!.valueIsOne {return}
        if allNodes.contains(where: {$0.numDenAreEqual}) {return}
        if !allNodes.map({$0.denominator}).contains(where: {$0.isMulti}) && !allNodes.denominatorsFirsts.containsVar && willHaveWholeNumberAfterMultSingleLCM(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl) {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        // x multiplication
        if allNodes.contains(where: {$0.isFraction(.notSingle(for: .denominator))}) {
            xMultiplicationMulti(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        } else {
            xMultiplicationSingle(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        }
    }
    
    private func xMultiplicationMulti(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Init
        let allNodes = nodeL.children + nodeR.children
        
        // Mark and Explain
        steps.lastMarked = allNodes.denominatorChain.flatSKs(.dropPlus) + allNodes.valuesSK
        steps.lastExplanation = "Simplify the equation using cross-multiplication"
        steps.lastStrikeKeys = [(key: .typedEqual, count: 1)]

        //
        let lhsDenClone = nodeL.children.first!.denominator.clone(changeID: false, withParent: false).children
        let rhsDenClone = nodeR.children.first!.denominator.clone(changeID: false, withParent: false).children
        nodeL.children.first!.removeDenominator()
        nodeR.children.first!.removeDenominator()
        
        if nodeL.children.count > 1 && rhsDenClone.count == 1 {
            insertMultiplierAtFirst(node: nodeL, multNodes: rhsDenClone, &steps)
        } else {
            appendHighOp(node: nodeL, opNodes: rhsDenClone, highOp: .times, &steps)
        }
        
        if nodeR.children.count == 1 && lhsDenClone.count > 1 {
            appendHighOp(node: nodeR, opNodes: lhsDenClone, highOp: .times, &steps)
        } else {
            insertMultiplierAtFirst(node: nodeR, multNodes: lhsDenClone, &steps)
        }
        
        // Remove one
        if (nodeL.children + nodeR.children).contains(where: {$0.valueIsOne}) {
            steps.lastStep.shouldShowMainStep = true
            steps.lastStepSubsteps = [steps.last!]
            steps.lastStepSubsteps.lastStrikeKeys = [(key: .typedEqual, count: 1)]
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        }
        if let oneTermNode = nodeL.children.first(where: {$0.isOneTerm}) {
            reorderTermsFromOut(node: oneTermNode, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        }
        surfAndApplyFn(mainNode: nodeL, otherNode: nil, fnCtrl: fnCtrl + [.force], surfFnCases: .removeHighOpOne, &steps.lastStepSubsteps)
        if let oneTermNode = nodeR.children.first(where: {$0.isOneTerm}) {
            reorderTermsFromOut(node: oneTermNode, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        }
        surfAndApplyFn(mainNode: nodeR, otherNode: nil, fnCtrl: fnCtrl + [.force], surfFnCases: .removeHighOpOne, &steps.lastStepSubsteps)

        // append step
        steps.lastMarked.append(contentsOf: (nodeL.children + nodeR.children).opValuesSK(.any).filter({$0.key.isTimes}))
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    private func xMultiplicationSingle(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Init
        let allNodes = nodeL.children + nodeR.children
        
        // Mark and Explain
        steps.lastMarked = allNodes.denominatorChain.flatSKs(.dropPlus) + allNodes.valuesSK
        steps.lastExplanation = "Simplify the equation using cross-multiplication"
        
        // Set substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Mult both sides by LHS denominator
        let multNodeLHS = nodeL.children.first!.denominator.clone(changeID: false, withParent: false).children
        if nodeR.children.isPlus {
            insertMultiplierAtFirstOnBothSides(multNodes: multNodeLHS, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        } else {
            appendHighOpOnBothSides(opNodes: multNodeLHS, highOp: .times, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // Mult both sides by RHS denominator
        let multNodeRHS = nodeR.children.first(where: {$0.isFraction})!.denominator.clone(changeID: false, withParent: false).children
        if nodeL.children.last!.isFraction(.notSingle(for: .numerator)) {
            insertMultiplierAtFirstOnBothSides(multNodes: multNodeRHS, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        } else {
            appendHighOpOnBothSides(opNodes: multNodeRHS, highOp: .times, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // Set Targets
        for node in nodeR.children.termMix {
            if !multNodeLHS.termMix.map({$0.staticID}).contains(node.staticID) {
                node.isTarget = true
            }
        }
        for node in nodeL.children.termMix {
            if !multNodeRHS.termMix.map({$0.staticID}).contains(node.staticID) {
                node.isTarget = true
            }
        }
        
        // Evaluate
        determineChainSign(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force, .keepTargets], &steps.lastStepSubsteps)
        reduceFraction(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force, .forceReduce, .targetOnly, .keepTargets], &steps.lastStepSubsteps)
        if let oneTermNode = nodeL.children.first(where: {$0.isOneTerm}) {
            reorderTermsFromOut(node: oneTermNode, fnCtrl: fnCtrl + [.force, .keepTargets], &steps.lastStepSubsteps)
        }
        determineChainSign(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force, .keepTargets], &steps.lastStepSubsteps)
        reduceFraction(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force, .forceReduce, .targetOnly, .keepTargets] , &steps.lastStepSubsteps)
        if let oneTermNode = nodeR.children.first(where: {$0.isOneTerm}) {
            reorderTermsFromOut(node: oneTermNode, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        }
        
        // Append to main steps
        steps.lastMarked.append(contentsOf: (nodeL.children + nodeR.children).opValuesSK(.any).filter({$0.key.isTimes}))
        steps.lastStrikeKeys = [(key: .typedEqual, count: 1)]
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Make Multiplier IDs equal to their IDs when they were denominators
        steps.lastStep.nodeL.children.matchIDsOfSameStaticID(with: multNodeRHS, inStepsView: false)
        nodeL.children.matchIDsOfSameStaticID(with: multNodeRHS, inStepsView: false)
        steps.lastStep.nodeR.children.matchIDsOfSameStaticID(with: multNodeLHS, inStepsView: false)
        nodeR.children.matchIDsOfSameStaticID(with: multNodeLHS, inStepsView: false)
    }
}

extension CalcBrain {
    func xMultAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeLClone = nodeL.clone(changeID: false, withParent: true)
        let nodeRClone = nodeR.clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        xMultiplication(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
}



