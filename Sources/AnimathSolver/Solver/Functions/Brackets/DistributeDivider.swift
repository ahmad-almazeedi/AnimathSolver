//
//  DistributeDivider.swift
//  Hulul
//
//  Created by Ahmad on 01/06/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func distributeDivider(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isBrackets(.complete) {} else {return}
        if node.isPowered {return}
        if node.isPlusOrMinus && node.next.isDivide && node.next.noHighOpAfter && !node.next.isBrackets(.notSingle(mayBeFraction: false)) {} else {return}
        
        // Mark and explain
        steps.lastMarked = node.flatSKs(node.isMinus ? .dropOp : .any) + node.next.flatSKs(.any)
        let multTitle = node.next.isBrackets(.complete) ? node.next.children.opValuesSK(.onlyMinus).strForExpl : node.next.opValueSK(.onlyMinus).strForExpl
        steps.lastExplanation = "Distribute \(multTitle) through the parentheses"
        
        // Distribute
        for inNode in node.children {
            if !inNode.next.isTimesOrDivide {
                let distNode = node.next.clone(changeID: inNode.isLast ? false : true, withParent: false)
                if !inNode.isLast {
                    steps.lastStep.appendCloneIDs(originalKeysIDs: node.next.opValueSK.ids, clonesKeysIDs: [distNode.opValueSK.ids])
                }
                inNode.insertAfter(distNode)
            }
        }
        steps.lastMarked.append(contentsOf: [node, node.next].flatSKs(.dropOp))
        node.next.remove()
        if node.isPlus {
            node.justRemoveBrackets()
        }
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
