//
//  TrinomialPerfectSquare.swift
//  Hulul
//
//  Created by Ahmad on 15/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func factorPrefectSquares(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var newParent = parent
        var excludedNode = StepNode()
        var nodes: [StepNode] {newParent.children.dropNode(node: excludedNode)}
        if [3,4].contains(nodes.count) {} else {return}
        var potentialExcludedNodes = nodes.count == 4 ? nodes : [StepNode()]
        var conditionsAreMet = false
        var aNode = StepNode()
        var bNode = StepNode()
        var cNode = StepNode()
        repeat {
            let tmpExcludedNode = potentialExcludedNodes.last!
            let selectedNodes = nodes.dropNode(node: tmpExcludedNode)
            potentialExcludedNodes.removeLast()
            guard let aNodeTmp = selectedNodes.first(where: {[$0].areAllRootables(indexValue: 2)}) else {continue}
            guard let cNodeTmp = selectedNodes.dropNode(node: aNodeTmp).first(where: {[$0].areAllRootables(indexValue: 2)}) else {continue}
            let bNodeTmp = selectedNodes.dropNodes(nodes: [aNodeTmp,cNodeTmp]).first!
            if !tmpExcludedNode.isEmpty {
                guard tmpExcludedNode.isMinus && aNodeTmp.isPlus || tmpExcludedNode.isPlus && aNodeTmp.isMinus else {continue}
                guard tmpExcludedNode.isWholeNumber(mayBeCoeff: true) else {continue}
                guard [tmpExcludedNode].areAllRootables(indexValue: 2) else {continue}
            }
            
            //
            if aNodeTmp.op.key == cNodeTmp.op.key {} else {continue}
            let aSqrtValue = aNodeTmp.valueDouble.squareRoot()
            let cSqrtValue = cNodeTmp.valueDouble.squareRoot()
            if aSqrtValue.isWholeNumber && cSqrtValue.isWholeNumber {} else {continue}
            if 2*aSqrtValue*cSqrtValue == bNodeTmp.valueDouble {} else {continue}
            for aOrcNode in [aNodeTmp, cNodeTmp] {
                for symbNode in aOrcNode.directSymbs {
                    if symbNode.isRootable(indexValue: 2) {} else {continue}
                    guard let bSymb = bNodeTmp.directSymbs.first(where: {$0.isSameSymb(with: symbNode)}) else {continue}
                    if symbNode.powerValue / bSymb.powerValue == 2 {} else {continue}
                }
            }
            if bNodeTmp.directSymbs.contains(where: {bSymb in ![aNodeTmp,cNodeTmp].allSymbs.contains(where: {$0.isSameSymb(with: bSymb)})}) {continue}
            aNode = aNodeTmp
            bNode = bNodeTmp
            cNode = cNodeTmp
            excludedNode = tmpExcludedNode
            conditionsAreMet = true
            break
        } while !potentialExcludedNodes.isEmpty
        guard conditionsAreMet else {return}
        
        //
        reorderTermsTo(nodes: excludedNode.isEmpty ? [aNode,bNode,cNode] : [aNode,bNode,cNode,excludedNode], fnCtrl: fnCtrl, &steps)
        reorderSymbsFromInTo(node: bNode, symbKeys: aNode.directSymbs.typesKeys+cNode.directSymbs.typesKeys, fnCtrl: fnCtrl, &steps)
        
        //
        if newParent.children.isMinus {
            extractCommonFactor(nodes: newParent.children, withOp: true, fnCtrl: [.forceExtractMinus], &steps)
            newParent = newParent.children.first(where: {$0.isBrackets}) ?? newParent
            if !excludedNode.isEmpty {
                excludedNode = newParent.children.first(where: {$0.staticID == excludedNode.staticID})!
            }
        }
        
        //
        steps.lastStep.setTitle(title: "Factoring: \(nodes.flatSKs(.dropPlus).strForExpl)", subtitle: "Using Perfect Square Formula")
        
        // aNode as a²
        representNodeAsPowered(to: 2, node: nodes.first!, fnCtrl: fnCtrl, &steps)
        
        // cNode as c²
        representNodeAsPowered(to: 2, node: nodes.last!, fnCtrl: fnCtrl, &steps)
        
        // bNode as 2ab
        rewriteBNodeForPerfectSquare(newParent: newParent, bNode: bNode, excludedNode: excludedNode, fnCtrl: fnCtrl, &steps)

        //
        factorToSquaredBrkt(newParent: newParent, excludedNode: excludedNode, fnCtrl: fnCtrl, &steps)
        
        //
        if !excludedNode.isEmpty {
            factorDiffOfTwoSquares(parent: newParent, fnCtrl: fnCtrl, &steps)
        }
    }
        
    private func rewriteBNodeForPerfectSquare(newParent: StepNode, bNode: StepNode, excludedNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var nodes: [StepNode] {newParent.children.dropNode(node: excludedNode)}
        if nodes[1].valueDouble == 2 && nodes[1].allSymbs.count == 2 {return}
        
        //
        steps.lastMarked = bNode.flatSKs(.dropOp)
        
        //
        let aClone = nodes.first!.cloneWithChangedStaticIDs
        let cClone = nodes.last!.cloneWithChangedStaticIDs
        aClone.baseOrTermNode.removePower()
        cClone.baseOrTermNode.removePower()
        aClone.baseNode.op = .times
        cClone.baseNode.op = .times
        aClone.baseNode.op.idIsZero = true
        cClone.baseNode.op.idIsZero = true
        
        //
        nodes[1].replace(with: [2.newNode, aClone.baseNode, cClone.baseNode], withOp: true)
        nodes[1].valueSK.replaceSimilarKeys(similarKeys: bNode.valueSK)
        let bNodeASymbs = bNode.allSymbs.filter({bSymb in aClone.selfOrChild.allSymbs.contains(where: {$0.isSymbType(type: bSymb.type?.key)})})
        let bNodeCSymbs = bNode.allSymbs.filter({bSymb in cClone.selfOrChild.allSymbs.contains(where: {$0.isSymbType(type: bSymb.type?.key)})})
        aClone.selfOrChild.allSymbs.replaceSimilarKeys(with: bNodeASymbs.flatSKs, withPow: true)
        cClone.selfOrChild.allSymbs.replaceSimilarKeys(with: bNodeCSymbs.flatSKs, withPow: true)
        aClone.selfOrChild.allRadicals.replaceSimilarKeys(with: bNode.allRadicals.flatSKs, withPow: true)
        cClone.selfOrChild.allRadicals.replaceSimilarKeys(with: bNode.allRadicals.flatSKs, withPow: true)
        let bValueSK = bNode.valueSK.filter({$0 != nodes[1].valueSK.first!})
        aClone.selfOrChild.valueSK.replaceSimilarKeys(similarKeys: bValueSK)
        cClone.selfOrChild.valueSK.replaceSimilarKeys(similarKeys: bValueSK.dropSKs(aClone.valueSK))

        //
        if !aClone.isBrackets {
            aClone.setSelfToBrackets(extractOp: true)
        }
        if !cClone.isBrackets {
            cClone.setSelfToBrackets(extractOp: true)
        }
        
        //
        steps.lastMarked.append(contentsOf: [StepNode](nodes[1...3]).flatSKs(.dropOp))
        steps.lastExplanation = "Rewrite \(bNode.flatSKs(.dropOp).strForExpl) as 2\(aClone.flatSKs(.dropOp).strForExpl)\(cClone.flatSKs(.dropOp).strForExpl)"
                
        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipRemoveUslessBrackets])
    }
    
    private func factorToSquaredBrkt(newParent: StepNode, excludedNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var nodes: [StepNode] {newParent.children.dropNode(node: excludedNode)}
        
        //
        steps.lastMarked = nodes.flatSKs(.dropOp)
        let opStr = nodes[1].isMinus ? "-" : "+"
        steps.lastExplanation = "Use a²\(opStr)2ab+b² = (a\(opStr)b)² to factor the expression"

        //
        let directNodes = nodes
        if !excludedNode.isEmpty || !newParent.isBracketsNotHidden || newParent.isBrackets(.powered) {
            nodes.setBrackets()
        }
        
        // Set brackets power
        directNodes.parent!.power = directNodes.first!.baseOrTermNode.power
        
        // remove inner powers
        directNodes.first!.baseOrTermNode.removePower()
        let lastPowerIDs = directNodes.last!.baseOrTermNode.power.first!.valueSK.ids
        directNodes.last!.baseOrTermNode.removePower()

        // change brackets content
        let middleIsBrkts = directNodes.count == 5
        let bFirstStepExprIDs = middleIsBrkts ? directNodes[2].children.first!.flatSKs(.dropOp).ids : directNodes[1].allSymbs.first!.flatSKs(.dropOp).ids
        let bLastStepExprIDs = middleIsBrkts ? directNodes[3].children.first!.flatSKs(.dropOp).ids : directNodes[1].allSymbs.last!.flatSKs(.dropOp).ids
        let directNodesStepExpr = directNodes.flatSKs
        let twoOp = directNodes[1].op
        let lastOpID = directNodes.last!.op.id
        directNodes.last!.op = twoOp
        directNodes.parent!.children = [directNodes.first!, directNodes.last!]
        if middleIsBrkts {
            directNodes.parent!.valueSK = [directNodesStepExpr.first(where: {$0.key == .openBracket})!, directNodesStepExpr.last(where: {$0.key == .closeBracket})!]
        } else {
            steps.lastMarked.append(contentsOf: directNodes.parent!.valueSK)
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipCopyStepTitle])
        
        //
        steps.appendMergeIDs(originalKeysIDs: [directNodes.parent!.valueSK.first!.id], mergesKeysIDs: directNodesStepExpr.dropSKs([directNodes.parent!.valueSK.first!]).filter({$0.key == .openBracket}).map({[$0.id]}))
        steps.appendMergeIDs(originalKeysIDs: [directNodes.parent!.valueSK.last!.id], mergesKeysIDs: directNodesStepExpr.dropSKs([directNodes.parent!.valueSK.last!]).filter({$0.key == .closeBracket}).map({[$0.id]}))
        steps.appendMergeIDs(originalKeysIDs: directNodes.parent!.power.first!.valueSK.ids, mergesKeysIDs: [lastPowerIDs])
        steps.appendMergeIDs(originalKeysIDs: directNodes.first!.flatSKs(.dropOp).ids, mergesKeysIDs: [bFirstStepExprIDs])
        steps.appendMergeIDs(originalKeysIDs: directNodes.last!.flatSKs(.dropOp).ids, mergesKeysIDs: [bLastStepExprIDs])
        if twoOp.key == .plus {
            steps.appendMergeIDs(originalKeysIDs: [directNodes.last!.op.id], mergesKeysIDs: [[lastOpID]])
        }
    }
}
