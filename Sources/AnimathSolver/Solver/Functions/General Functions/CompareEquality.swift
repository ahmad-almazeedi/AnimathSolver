//
//  CompareEquality.swift
//  Hulul
//
//  Created by Ahmad on 25/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func checkEquality(nodeL: StepNode, nodeR: StepNode, steps: inout [StepModel]) {
        
        // Conditions
        if nodeL.forceStop {return}
        if nodeL.isEquation {} else {return}
        let allNodes = nodeL.children + nodeR.children
        if allNodes.hasVarOrNotVarXFlat {
            checkIfSolutionInDefinedRange(nodeL: nodeL, nodeR: nodeR, &steps)
            checkSolutionBySubtituting(nodeL: nodeL, nodeR: nodeR, mainSteps: steps, fnCtrl: [.skipEqualityCheck], &steps)
            return
        }
        
        // False if opposite signs
        if nodeL.children.count == 1 && nodeR.children.count == 1 && allNodes.filter({$0.isMinus}).count == 1 {
            steps.setEquationIsFalse(nodeL: nodeL, nodeR: nodeR)
            return
        }
        
        // Approximate Value
        let hadTerm = allNodes.hasTerm
        if !(nodeL.children.count == 1 && nodeR.children.count == 1 && nodeL.children.first!.hasEqualTerms(with: nodeR.children.first!)) {
            findApproximateValue(nodes: nodeL.children, fnCtrl: [], steps: &steps)
            findApproximateValue(nodes: nodeR.children, fnCtrl: [], steps: &steps)
        }
        
        // Compare
        if !(nodeL.children.count == 1 && nodeR.children.count == 1) {
            steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
            return
        }
        if nodeL.children.first!.isEqualTo(node: nodeR.children.first!) {
            if hadTerm {
                steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
                return
            }
            steps.setEquationIsTrue(nodeL: nodeL, nodeR: nodeR)
        } else {
            if hadTerm {
                let nodeLFirst = nodeL.children.first!
                let nodeRFirst = nodeR.children.first!
                if !nodeLFirst.valueSK.canBeDouble || !nodeRFirst.valueSK.canBeDouble || nodeLFirst.valueDouble.isAlmostEqual(to: nodeRFirst.valueDouble, tolerance: 0.00001) {
                    steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
                    return
                }
            }
            steps.setEquationIsFalse(nodeL: nodeL, nodeR: nodeR)
        }
    }
}

extension CalcBrain {
    func findApproximateValue(nodes: [StepNode], fnCtrl: [FnCtrl], steps: inout [StepModel]) {
        
        // Conditions
        if fnCtrl.isForced {} else {
            if nodes.hasVarFlat {return}
            if nodes.hasTerm {} else {return}
        }
        if nodes.isSingleNode && !nodes.first!.isCoeff && nodes.first!.isNumber(mayBePowered: false) {return}
        
        // Mark
        steps.lastMarked = nodes.flatSKs
        
        // Evaluate
        let resultNode = nodes.resultValue().operationResultRounded(precision: 7, isError: false).newNode
        nodes.first!.insertBefore(resultNode)
        nodes.removeNodesFromParent()
        
        // Explain
        let isExact = resultNode.opValueDouble == nodes.resultValue().operationResultRounded(precision: 13, isError: false)
        steps.lastExplanation = isExact && fnCtrl.contains(.isInSplittedSteps) ? "Simplify the expression" : "Calculate the approximate value"
        
        //
        resultNode.valueSK.replaceSimilarKeys(similarKeys: nodes.flatSKs)
        
        // Mark and Append
        steps.lastMarked.append(contentsOf: resultNode.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl + [.skipEqualityCheck])
    }
}
