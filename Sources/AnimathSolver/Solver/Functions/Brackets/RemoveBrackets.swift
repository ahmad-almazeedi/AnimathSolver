//
//  RemoveBrackets.swift
//  Hulul
//
//  Created by Ahmad on 20/01/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func removeBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if node.exist && node.multChain(forward: false).hasBrackets {} else {return}
        if let parentFraction = node.parentFraction {
            if isReducible(node: parentFraction, fnCtrl: fnCtrl.drop(.skipRemoveUslessBrackets) + [.skipDistribute]) {return}
        }
        removePositiveBrackets(node: node, fnCtrl: fnCtrl, &steps)
        mergeAndEvaluateEqualBrackets(node: node, fnCtrl: fnCtrl, &steps)
        evaluateBrktsTimesConjugate(node: node, fnCtrl: fnCtrl, &steps)
        removeNegativeBrackets(node: node, fnCtrl: fnCtrl, &steps)
        distributeMultiplier(node: node, fnCtrl: fnCtrl, &steps)
        evaluatePoweredBrackets(node: node, fnCtrl: fnCtrl, &steps)
        distributeBrackets(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func removePositiveBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isHiddenBrkts {return}
        if node.isBrackets(.simplest) || node.isBrackets(.single(mayBePowered: true)) {} else {return}
        if node.isInFraction && node.isAlone {return}
        if node.isPowered {return}
        if node.isPlus && !(node.isMultipliedOrDivided && !node.isBrackets(.single(mayBePowered: true)) && node.isBrackets(.notSingle(mayBeFraction: true))) {} else {return}
        
        // Mark and explain
        steps.lastMarked = node.opValueSK(node.children.isPlus ? .dropOp : .any)
        steps.lastExplanation = "Remove unnecessary parentheses"
        
        // Remove brackets
        node.justRemoveBrackets()
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    func removeNegativeBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isBrackets({$0.isSimplestForm || $0.isBrackets(.simplest) && $0.isMinus}) && node.isMinus {} else {return}
        if node.next.isTimesOrDivide && (!node.isBrackets({$0.isBrackets(.simplest) && $0.isMinus}) && node.isBrackets(.notSingle(mayBeFraction: true))) {return}
        if !node.otherSide.isEmpty && isMultBothSidesByNegativeOne(mainSide: node.root, otherSide: node.otherSide) {return}
        if fnCtrl.contains(.skipDistribute) && node.children.count > 1 {return}
        
        //
        if node.children.isMulti && node.isInBrackets && node.parent!.isMinus && node.isAlone {
            removeNegativeBrackets(node: node.parent!, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        if node.isPowered {return}

        // Mark and explain
        steps.lastMarked = [node.op] + node.children.getOps
        steps.lastExplanation = node.children.count == 1 ? "Apply the rule −(−a) = \(node.isFirst ? "" : "+")a" : "To find the opposite of a parentheses, find the opposite of each term in the parentheses"
//        if node.children.count == 1 {
//            steps.lastStrikeKeys = [node.op.strikeKey,node.children.op.strikeKey]
//        }
        
        // Flip signs
        node.flipSign()
        node.children.flipSigns()
        if node.children.isMinus {
            node.children.op = steps.lastMarked.first!
        }
        steps.lastMarked.append(contentsOf: [node.op] + node.children.getOps)
        
        // Remove bracket
        if node.isPlus && (!node.isMultipliedOrDivided || node.children.isBrackets) {
            node.justRemoveBrackets()
        } else if node.children.isMinus {
            node.op.changeID()
            steps.lastMarked.append(node.op)
        }
                
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func removeBracketsAllowed(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeClone = node.clone(changeID: false, withParent: true)
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        removeBrackets(node: nodeClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed, .forceDistribute], &tmpSteps)
        return nodeClone.pinnedRootDidChange
    }
}
