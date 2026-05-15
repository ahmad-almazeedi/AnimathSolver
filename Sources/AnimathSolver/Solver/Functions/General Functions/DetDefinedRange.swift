//
//  DetermineDefinedRange.swift
//  Hulul
//
//  Created by Ahmad on 25/10/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    enum UndefinedRangeCase {
        case denominator, divisor, negativeExp, zeroExp
    }
    func determineTheDefinedRange(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if fnCtrl.contains(.forceSkip) {return}
        var hasZeroExpo = false
        for node in nodeL.flatTree + nodeR.flatTree {
            determineTheDefinedRangeFor(node: node, hasZeroExpo: &hasZeroExpo, fnCtrl: fnCtrl, &steps)
        }
        if steps.lastMultiSubSteps.count > 1 && steps.lastMultiSubSteps.dropFirst().contains(where: {!$0.first!.isTitleStep}) {
            guard let varStr = steps.lastStep.multiSubSteps.last(where: {!$0.first!.isTitleStep})!.last!.nodeL.children.allSymbsFlat.first(where: {$0.isVar})!.type?.key.title else {return}
            let undefinedNodes = steps.first!.multiSubSteps.getUndefinedNodes
            let undefinedNodesStrWithOr = undefinedNodes.undefinedNodesStrWithOr
            steps.lastExplanation = hasZeroExpo ? "\(varStr) is undefined at \(undefinedNodes.count > 1 ? "any of the values " : "")\(undefinedNodesStrWithOr)" : "\(varStr) cannot be equal to \(undefinedNodes.count > 1 ? "any of the values " : "")\(undefinedNodesStrWithOr) since division by zero is not defined"
            steps[0].shouldShowMainStep = true
            steps[0].multiSubSteps[1].lastMarked.append(.comma)
            appendStep(&steps, fnCtrl: fnCtrl)
        }
    }
}

extension CalcBrain {
    private func determineTheDefinedRangeFor(node: StepNode, hasZeroExpo: inout Bool, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        //
        if (node.isVar || node.hasVarFlat) && !node.isSqrt {} else {return}
        
        // Determine Case
        var undefinedRangeCase = UndefinedRangeCase.denominator
        if node.isFraction && node.denominator.hasVarFlat {}
        else if node.isDivide {
            undefinedRangeCase = .divisor
        } else if node.powerResultIsNegative {
            undefinedRangeCase = .negativeExp
        } else if node.powerResultIsZero {
            hasZeroExpo = true
            undefinedRangeCase = .zeroExp
        }
        else {return}
        guard let varType = node.isVar ? node.type?.key : node.allSymbsFlat.first(where: {$0.isVar})!.type?.key else {return}
        
        // Init the root nodes
        let targetedNode = StepNode()
        targetedNode.isLeft = true
        let nodeR = StepNode(valueSK: [.notEqual.withID(Int32.randomOdd)]) // To distinguish with notEqual of checkSolutionBySubtituting
        nodeR.isLeft = false
        
        // Set targeted node
        let nodeClone = node.cloneWithChangedStaticIDs
        switch undefinedRangeCase {
        case .denominator:
            targetedNode.children = nodeClone.denominator
        case .divisor:
            targetedNode.children = [nodeClone]
            nodeClone.op = .plus
            if nodeClone.isBrackets && nodeClone.mayRemoveBrackets {
                nodeClone.removeBracketsGeneral()
            }
        case .negativeExp, .zeroExp:
            if nodeClone.isBrackets {
                targetedNode.children = nodeClone.children
            } else if nodeClone.isVar {
                nodeClone.removePower()
                let newNode = StepNode.newOneNode
                newNode.directSymbs = [nodeClone]
                targetedNode.children = [newNode]
            } else {
                steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
                return
            }
        }
                
        // Init Substeps
        steps.lastMultiSubSteps.append([StepModel()])
        stepsInit(nodeL: targetedNode, nodeR: nodeR, fnCtrl: fnCtrl + [.skipPrintStep], steps: &steps.lastStepLastSubsteps)
        steps.lastStepLastSubsteps[0].inMainSteps = false

        //
        var exprTypeStr = ""
        switch undefinedRangeCase {
        case .denominator:
            exprTypeStr = "denominator"
        case .divisor:
            exprTypeStr = "divisor"
        case .negativeExp:
            exprTypeStr = "base of the negative exponent"
        case .zeroExp:
            exprTypeStr = "base of the zero exponent"
        }
        steps.lastStepLastSubsteps.lastExplanation = "Set the \(exprTypeStr) equal to 0 and solve for \(varType.title)"

        //
        nodeR.children = [StepNode(valueKeys: [.zero])]
        if nodeR.valueSK.first!.key != .notEqual {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        steps.lastStepLastSubsteps.lastMarked = targetedNode.flatSKs(.dropPlus) + [nodeR.valueSK.first!] + nodeR.children.flatSKs

        //
        appendStep(&steps.lastStepLastSubsteps, fnCtrl: fnCtrl)

        //
        highCostSolve(nodeL: targetedNode, nodeR: nodeR, fnCtrl: fnCtrl + [.forceSkip, .skipFlattenning, .isInUndefinedSteps], &steps.lastStepLastSubsteps)
        checkEquality(nodeL: targetedNode, nodeR: nodeR, steps: &steps.lastStepLastSubsteps)
        if targetedNode.shouldBeUnableToSolve || targetedNode.resultCase == .none && !targetedNode.children.isOneSingleVar(mayBeInSqrt: false) {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }

        //
        if targetedNode.resultCase == .none {} else if targetedNode.resultCase == .falseForAnyX {
            
        } else {
            if targetedNode.resultCase == .undefined {
                steps.lastStepLastSubsteps.removeAll()
            } else {
                steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            }
            return
        }
    }
}
extension CalcBrain {
    func checkIfSolutionInDefinedRange(nodeL: StepNode, nodeR: StepNode, _ steps: inout [StepModel]) {
        
        //
        if nodeL.resultCase == .none {} else {return}
        if nodeL.children.isOneSingleVar(mayBeInSqrt: false) && !nodeR.children.hasVarFlat {} else {return}
        guard let multiSubSteps = steps.first?.multiSubSteps, multiSubSteps.count > 1 else {return}
        let undefinedNodes = multiSubSteps.getUndefinedNodes
        
        //
        if let splittedSteps = steps.last!.splittedSteps {
            
            //
            if splittedSteps.hasWrongSolution {steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR); return}
            let splittedStepsWithWrongSolution = splittedSteps.filter({singleSplitSteps in
                undefinedNodes.contains(where: {$0.otherSide.children.first!.directVar!.isSameSymb(with: singleSplitSteps.last!.nodeL.children.first!.directVar!) && $0.children.isEqualTo(nodes: singleSplitSteps.last!.nodeR.children)})
            })
            if splittedStepsWithWrongSolution.isEmpty {return}
            
            //
            let allAreWrongSolutions = splittedSteps.count == splittedStepsWithWrongSolution.count
            let pluralStr = splittedStepsWithWrongSolution.count > 1 ? "s" : ""
            let isOrAreStr = splittedStepsWithWrongSolution.count > 1 ? "are" : "is"
            guard let varStr = nodeL.children.allSymbsFlat.first(where: {$0.isVar})?.type?.key.title else {return}
            let firstUndefStr = splittedStepsWithWrongSolution.first!.last!.nodeR.children.flatSKs(.dropPlus).strForExpl
            let restUndefStr = splittedStepsWithWrongSolution.dropFirst().map({", " + $0.last!.nodeR.children.flatSKs(.dropPlus).strForExpl})
            let allUndefStr = "\(firstUndefStr)\(splittedStepsWithWrongSolution.count > 1 ? "\(restUndefStr)" : "")"
            let explanationStr = "The solution\(pluralStr) \(varStr) = \(allUndefStr) \(isOrAreStr) not valid because the equation is undefined at \(allUndefStr)"
            if allAreWrongSolutions {
                steps.setEquationIsFalseForSpliSteps(nodeL: steps.lastStepLastSplitStep.last!.dynamicNodeL, nodeR: steps.lastStepLastSplitStep.last!.dynamicNodeR)
                steps.lastStepLastSplitStep.lastExplanation = explanationStr
                steps.last!.nodeL.resultCase = .falseForAnyX
            } else {
                steps.lastStepLastSplitStep.lastExplanation = explanationStr
                for wrongNodeL in splittedStepsWithWrongSolution.map({$0.last!.nodeL}) {
                    wrongNodeL.resultCase = .falseForAnyX
                }
                appendStep(&steps.lastStepLastSplitStep, fnCtrl: [])
                appendStep(&steps, fnCtrl: [])
                steps.lastMultiSubSteps.append(contentsOf: splittedSteps.filter({singleSplitSteps in
                    !splittedStepsWithWrongSolution.contains(where: {singleSplitSteps.first!.id == $0.first!.id})}).map({[$0.last!.clone]
                    }))
            }
        } else {
            if undefinedNodes.contains(where: {$0.otherSide.children.first!.directVar!.isSameSymb(with: nodeL.children.first!.directVar!) && $0.children.isEqualTo(nodes: nodeR.children)}) {} else {return}
            guard let varStr = nodeL.children.allSymbsFlat.first(where: {$0.isVar})?.type?.key.title else {return}
            let undefStr = nodeR.children.flatSKs(.dropPlus).strForExpl
            steps.lastExplanation = "The solution \(varStr) = \(undefStr) is not valid because the equation is undefined at \(undefStr)"
            steps.lastNote = "No Solution"
            steps.lastStep.nodeL.resultCase = .falseForAnyX
            steps.lastStep.nodeR.resultCase = .falseForAnyX
            nodeL.resultCase = .falseForAnyX
            nodeR.resultCase = .falseForAnyX
            steps.lastMarked = nodeL.flatSKs + nodeR.flatSKsWithEqualityOp + undefinedNodes.map({$0.root.otherSide.flatSKs(dropEqual: false)}).flatMap({$0})
            steps[0].shouldShowMainStep = true
        }
    }
}
