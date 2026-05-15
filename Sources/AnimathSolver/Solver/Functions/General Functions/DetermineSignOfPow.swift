//
//  DetermineSignOfPoweredBrkts.swift
//  Hulul
//
//  Created by Ahmad on 22/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func determineSignOfPoweredBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isPoweredByWholeNumber {} else {return}
        if node.powerValue <= 0 {return}
        if node.isBrackets(.singleNegGeneral) && node.children.isSimplestForm {} else {return}
        guard node.children.isFraction || node.isBrackets && !node.isSqrt && node.children.isMinus else {return}
        // if node.parent!.isSqrt && !node.parent!.indexIsEven && node.isRootableOrSimplifiable(indexValue: node.parent!.indexValue, isNotRootableIfMultiplied: false) {return} // Don't know why this was implemented, but removed it because of this: (−{8}/{125})^[{4}/{3}]
        
        //
        if node.powerValue.isEven {
            
            // Mark & Explain
            steps.lastMarked = [node.children.op] + node.power.flatSKs
            steps.lastExplanation = "A negative base raised to an even power equals a positive, so remove the negative sign"
            
            // Remove minus and brackets
            node.children.op = .plus
            if !node.children.isFraction && !node.children.first!.isPowered && !node.hasTerm {
                node.removeBracketsGeneral()
            }
            
            // append step
            appendStep(&steps, fnCtrl: fnCtrl)
        } else if node.isPlus {
            
            // Mark & Explain
            steps.lastMarked = node.flatSKs
            steps.lastExplanation = "A negative base raised to an odd power equals a negative"
            
            if node.children.first!.shouldSetBrktIfPowered {
                node.op = node.children.op
                node.children.op = .plus
            } else {
                node.removeBracketsGeneral()
            }
            
            // append step
            appendStep(&steps, fnCtrl: fnCtrl)
        } else {
            
            // mark and explain
            steps.lastMarked = node.power.flatSKs + node.children.first!.opValueSK
            steps.lastExplanation = "A negative base raised to an odd power equals a negative"
            
            //
            if node.children.first!.shouldSetBrktIfPowered {
                node.children.first!.setSelfToBrackets()
                steps.lastMarked.append(contentsOf: node.children.first!.flatSKs)
                node.children.op = node.children.first!.children.op
                node.children.first!.children.op = .plus
            }
            
            // Bring power inside
            node.children.first!.baseOrTermNode.power = node.power
            node.removePower()
            
            // append step
            appendStep(&steps, fnCtrl: fnCtrl)
        }
    }
}
