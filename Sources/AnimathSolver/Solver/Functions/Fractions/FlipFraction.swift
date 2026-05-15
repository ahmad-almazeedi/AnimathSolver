//
//  FlipFraction.swift
//  Hulul
//
//  Created by Ahmad on 15/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func flipFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isFraction && node.isDivide {} else {return}
        
        //
        if node.numerator.isEqualTo(nodes: node.denominator) {
            node.pinRootExpr()
            for numNode in node.numerator {
                var numNode = numNode
                reduceFirstEqualNodes(numNode: &numNode, denChain: node.denominator, fnCtrl: fnCtrl, sameFraction: false, &steps)
            }
            if node.pinnedRootDidChange {return}
        }
        
        // Mark and explain
        steps.lastMarked = node.flatSKs(.any)
        steps.lastExplanation = "To divide by a fraction, multiply by its reciprocal"
        
        // Flip Fraction
        node.flipFraction(fnCtrl: fnCtrl)
        
        // change sign
        node.op = .times
        
        // Append Step
        steps.lastMarked.append(node.op)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

