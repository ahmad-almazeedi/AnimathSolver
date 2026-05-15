//
//  SwapSides.swift
//  Hulul
//
//  Created by Ahmad on 16/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func swapSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
      
        // Conditions
        var allNodes: [StepNode] {nodeL.children + nodeR.children}
        if !allNodes.hasVarFlat {return}
        if fnCtrl.isForced {} else {
            if !allNodes.allSymbs.shouldMoveAllToSide {
                if multBothSidesAllowed(nodeL: nodeR, nodeR: nodeL, fnCtrl: fnCtrl) {return}
                if powBothRadicalsAllowed(nodeL: nodeL, nodeR: nodeR, dynamicSwap: false, fnCtrl: fnCtrl) {return}
                if powerBothSidesAllowed(nodeL: nodeR, nodeR: nodeL, dynamicSwap: false, fnCtrl: fnCtrl) && !powerBothSidesAllowed(nodeL: nodeL, nodeR: nodeR, dynamicSwap: false, fnCtrl: fnCtrl) {}
                else if nodeR.children.hasBrackets(.any) {
                    if divideBothSidesAllowedExceptMoveCoeff(nodeL: nodeR, nodeR: nodeL, fnCtrl: fnCtrl) {return}
                    if moveCoeffAllowed(nodeL: nodeR, nodeR: nodeL, fnCtrl: fnCtrl) {} else {return}
                } else {
                    if nodeL.children.isSimplestForm && nodeR.children.isSimplestForm {} else {return}
                    if nodeR.children.hasVar && (!nodeL.children.hasVar || nodeR.children.count == 1 && nodeR.children.isPlus && !nodeL.children.isFraction && nodeL.children.first(where: {$0.hasVar})!.isMinus) {} else {return}
                    if nodeR.children.contains(where: {$0.isFraction && !$0.numerator.hasVar}) {return}
                    if nodeR.children.count == 1 || nodeL.children.isZero || nodeR.children.first(where: {$0.hasVar})!.isPlus {} else {return}
                }
            } else if !nodeR.children.isZero(opCase: .plus) && nodeL.children.isZero(opCase: .plus) {} else {return}
        }
        
        //
        removeOneTimesBracket(node: nodeR.children.first!, fnCtrl: fnCtrl, &steps)
        
        // Mark And Explain
        steps.lastMarked = nodeL.rootStepExpr + nodeR.rootStepExpr
        steps.lastExplanation = "Swap the sides of the equation"
        
        // Swap Sides
        let tempNodeLChildren = nodeL.children
        nodeL.children = nodeR.children
        nodeR.children = tempNodeLChildren
        
        // Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
