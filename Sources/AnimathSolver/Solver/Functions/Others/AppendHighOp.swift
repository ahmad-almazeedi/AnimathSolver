//
//  AppendHighOp.swift
//  Hulul
//
//  Created by Ahmad on 01/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func appendHighOpOnBothSides(opNodes: [StepNode], highOp: Key, nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Mark and Explain
        steps.lastMarked = []
        let opStr = highOp == .times ? "Multiply" : highOp == .divide ? "Divide" : "..."
        steps.lastExplanation = "\(opStr) both sides by \(opNodes.isMinus ? "-" : "")\(opNodes.flatSKs(.dropOp).filter({!($0.key.isBracket && !$0.key.isSquareBrkt)}).strForExpl)"
        
        // Append Multiplier
        appendHighOp(node: nodeL, opNodes: opNodes.clone(changeID: true, withParent: false).children, highOp: highOp, &steps)
        appendHighOp(node: nodeR, opNodes: opNodes.clone(changeID: true, withParent: false).children, highOp: highOp, &steps)
        
        // Nextmark and Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
    }

    func appendHighOp(node: StepNode, opNodes: [StepNode], highOp: Key, _ steps: inout [StepModel]) {
        
        // parenthesize opNodes if needed
        var opNodes = opNodes
        let resultNodes = opNodes.resultNodes()
        if !opNodes.isBrackets && opNodes.isPlusOrMinus && (resultNodes.isMinus || !resultNodes.isSingle(mayBeFraction: true, mayBePowered: false) || highOp.isDivide && (opNodes.count > 1 || opNodes.hasTerm && !opNodes.isOneSingleTerm)) {
            let bracketsNode = StepNode.newBracketsNode
            steps.lastMarked.append(contentsOf: bracketsNode.valueSK)
            bracketsNode.children.append(contentsOf: opNodes)
            opNodes = [bracketsNode]
        }
        
        // Set op Node
        steps.lastMarked.append(contentsOf: opNodes.flatSKs(.any))
        opNodes.op = .stepKey(highOp)
        steps.lastMarked.append(opNodes.op)
        
        // Append Multiplier
        if node.children.hasOnlyTimes {
            node.children.append(contentsOf: opNodes)
        } else {
            let bracketsNode = StepNode.newBracketsNode
            steps.lastMarked.append(contentsOf: bracketsNode.valueSK)
            bracketsNode.children.append(contentsOf: node.children)
            node.children = [bracketsNode]
            node.children.append(contentsOf: opNodes)
        }
    }

    func insertMultiplierAtFirstOnBothSides(multNodes: [StepNode], nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        // Mark and Explain
        steps.lastMarked = []
        steps.lastExplanation = "Multiply both sides by \(multNodes.flatSKs(.dropPlus).filter({!($0.key.isBracket && !$0.key.isSquareBrkt)}).strForExpl)"

        // Append Multiplier
        insertMultiplierAtFirst(node: nodeL, multNodes: multNodes.clone(changeID: true, withParent: false).children, &steps)
        insertMultiplierAtFirst(node: nodeR, multNodes: multNodes.clone(changeID: true, withParent: false).children, &steps)

        // Nextmark and Append Step
        appendStep(&steps, fnCtrl: fnCtrl)
    }

    func insertMultiplierAtFirst(node: StepNode, multNodes: [StepNode], _ steps: inout [StepModel]) {

        // parenthesize MultNodes if needed
        var multNodes = multNodes
        if !multNodes.resultNodes().isSingle(mayBeFraction: true, mayBePowered: false) {
            let bracketsNode = StepNode.newBracketsNode
            bracketsNode.staticID = multNodes.first!.staticID
            steps.lastMarked.append(contentsOf: bracketsNode.valueSK)
            bracketsNode.children = multNodes
            multNodes = [bracketsNode]
        }

        // Set Multiplier Node
        if !multNodes.isMinus {
            multNodes.op = .plus
        }
        steps.lastMarked.append(contentsOf: multNodes.flatSKs(.dropPlus))

        // Insert Multiplier
        if node.children.hasOnlyTimes && node.children.isPlus {
            node.children.first!.op = .times
            node.children.insert(contentsOf: multNodes, at: 0)
        } else {
            let bracketsNode = StepNode.newBracketsNode
            bracketsNode.op = .times
            steps.lastMarked.append(contentsOf: bracketsNode.valueSK)
            if node.children.hasOnlyTimes {
                bracketsNode.children = [node.children.first!]
                node.children = [bracketsNode] + node.children.dropFirst
                node.children.insert(contentsOf: multNodes, at: 0)
            } else {
                bracketsNode.children = node.children
                node.children = [bracketsNode]
                node.children.insert(contentsOf: multNodes, at: 0)
            }
        }
        steps.lastMarked.append(node.children[1].op)
    }
}
