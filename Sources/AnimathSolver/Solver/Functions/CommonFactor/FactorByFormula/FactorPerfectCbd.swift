//
//  FactorPerfectCbd.swift
//  Hulul
//
//  Created by Ahmad on 21/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func factorPrefectCubed(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var newParent = parent
        var excludedNode = StepNode()
        var nodes: [StepNode] {newParent.children.dropNode(node: excludedNode)}
        if [4,5].contains(nodes.count) {} else {return}
        var potentialExcludedNodes = nodes.count == 5 ? nodes : [StepNode()]
        var conditionsAreMet = false
        var aNode = StepNode()
        var bNode = StepNode()
        var cNode = StepNode()
        var dNode = StepNode()
        repeat {
            let tmpExcludedNode = potentialExcludedNodes.last!
            let selectedNodes = nodes.dropNode(node: tmpExcludedNode)
            potentialExcludedNodes.removeLast()
            if !tmpExcludedNode.isEmpty {
                guard tmpExcludedNode.isWholeNumber(mayBeCoeff: true) else {continue}
                guard [tmpExcludedNode].areAllRootables(indexValue: 3) else {continue}
            }
            guard let aNodeTmp = selectedNodes.first(where: {[$0].areAllRootables(indexValue: 3)}) else {continue}
            guard let dNodeTmp = selectedNodes.dropNode(node: aNodeTmp).first(where: {[$0].areAllRootables(indexValue: 3)}) else {continue}
            let aCbrtValue = pow(aNodeTmp.valueDouble, 1/3).rounded
            let dCbrtValue = pow(dNodeTmp.valueDouble, 1/3).rounded
            if aCbrtValue.isWholeNumber && dCbrtValue.isWholeNumber {} else {continue}
            guard let bNodeTmp = selectedNodes.dropNodes(nodes: [aNodeTmp,dNodeTmp]).first(where: {bNode in
                let cNodeTmp = selectedNodes.dropNodes(nodes: [aNodeTmp,bNode,dNodeTmp]).first!
                if bNode.valueDouble == 3*pow(aCbrtValue,2)*dCbrtValue {} else {return false}
                if cNodeTmp.valueDouble == 3*pow(dCbrtValue,2)*aCbrtValue {} else {return false}
                for symbNode in aNodeTmp.directSymbs {
                    if symbNode.isRootable(indexValue: 3) {} else {return false}
                    guard let bSymb = bNode.directSymbs.first(where: {$0.isSameSymb(with: symbNode)}) else {return false}
                    if (symbNode.powerValue/3)*2 == bSymb.powerValue {} else {return false}
                    guard let cSymb = cNodeTmp.directSymbs.first(where: {$0.isSameSymb(with: symbNode)}) else {return false}
                    if symbNode.powerValue / cSymb.powerValue == 3 {} else {return false}
                }
                for symbNode in dNodeTmp.directSymbs {
                    if symbNode.isRootable(indexValue: 3) {} else {return false}
                    guard let bSymb = bNode.directSymbs.first(where: {$0.isSameSymb(with: symbNode)}) else {return false}
                    if symbNode.powerValue / bSymb.powerValue == 3 {} else {return false}
                    guard let cSymb = cNodeTmp.directSymbs.first(where: {$0.isSameSymb(with: symbNode)}) else {return false}
                    if (symbNode.powerValue/3)*2 == cSymb.powerValue {} else {return false}
                }
                return true
            }) else {continue}
            let cNodeTmp = selectedNodes.dropNodes(nodes: [aNodeTmp,bNodeTmp,dNodeTmp]).first!
            if aNodeTmp.op.key != cNodeTmp.op.key || bNodeTmp.op.key != dNodeTmp.op.key {continue}
            if [bNodeTmp, cNodeTmp].directSymbs.contains(where: {bOrcSymb in ![aNodeTmp,dNodeTmp].allSymbs.contains(where: {$0.isSameSymb(with: bOrcSymb)})}) {continue}
            aNode = aNodeTmp
            bNode = bNodeTmp
            cNode = cNodeTmp
            dNode = dNodeTmp
            excludedNode = tmpExcludedNode
            conditionsAreMet = true
            break
        } while !potentialExcludedNodes.isEmpty
        guard conditionsAreMet else {return}
        
        //
        reorderTermsTo(nodes: excludedNode.isEmpty ? [aNode,bNode,cNode,dNode] : [aNode,bNode,cNode,dNode,excludedNode], fnCtrl: fnCtrl, &steps)
        reorderSymbsFromInTo(node: bNode, symbKeys: aNode.directSymbs.typesKeys+dNode.directSymbs.typesKeys, fnCtrl: fnCtrl, &steps)
        reorderSymbsFromInTo(node: cNode, symbKeys: aNode.directSymbs.typesKeys+dNode.directSymbs.typesKeys, fnCtrl: fnCtrl, &steps)

        //
        if newParent.children.isMinus {
            extractCommonFactor(nodes: newParent.children, withOp: true, fnCtrl: [.forceExtractMinus], &steps)
            newParent = newParent.children.first(where: {$0.isBrackets}) ?? newParent
            if !excludedNode.isEmpty {
                excludedNode = newParent.children.first(where: {$0.staticID == excludedNode.staticID})!
            }
        }
        
        //
        steps.lastStep.setTitle(title: "Factoring: \(nodes.flatSKs(.dropPlus).strForExpl)", subtitle: "Using Perfect Cube Formula")
        
        // aNode as a³
        representNodeAsPowered(to: 3, node: nodes.first!, fnCtrl: fnCtrl, &steps)
        
        // dNode as b³
        representNodeAsPowered(to: 3, node: nodes.last!, fnCtrl: fnCtrl, &steps)
        
        // bNode as 3a²b
        rewriteMidNodeForPerfectCubes(newParent: newParent, midNode: bNode, excludedNode: excludedNode, fnCtrl: fnCtrl, &steps)

        // cNode as 3ab²
        rewriteMidNodeForPerfectCubes(newParent: newParent, midNode: cNode, excludedNode: excludedNode, fnCtrl: fnCtrl, &steps)

        //
        factorToCubedBrkt(newParent: newParent, excludedNode: excludedNode, fnCtrl: fnCtrl, &steps)
        
        //
        if !excludedNode.isEmpty {
            factorSumOrDiffOfTwoCubes(parent: newParent, fnCtrl: fnCtrl, &steps)
        }
    }
    
    private func rewriteMidNodeForPerfectCubes(newParent: StepNode, midNode: StepNode, excludedNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var nodes: [StepNode] {newParent.children.dropNode(node: excludedNode)}
        if nodes[1...2].allSatisfy({$0.valueDouble == 3 && $0.allSymbs.count == 2}) {return}
        
        //
        steps.lastMarked = midNode.flatSKs(.dropOp)
        
        //
        let midNodeIdx = nodes.firstIndex(where: {$0.staticID == midNode.staticID})!
        let aClone = nodes.first!.cloneWithChangedStaticIDs
        let dClone = nodes.last!.cloneWithChangedStaticIDs
        if midNodeIdx == 1 {
            aClone.baseOrTermNode.power = [2.newNode]
            dClone.baseOrTermNode.removePower()
        } else {
            aClone.baseOrTermNode.removePower()
            dClone.baseOrTermNode.power = [2.newNode]
        }
        aClone.baseNode.op = .times
        dClone.baseNode.op = .times
        aClone.baseNode.op.idIsZero = true
        dClone.baseNode.op.idIsZero = true
        
        //
        nodes[midNodeIdx].replace(with: [3.newNode, aClone.baseNode, dClone.baseNode], withOp: true)
        nodes[midNodeIdx].valueSK.replaceSimilarKeys(similarKeys: midNode.valueSK)
        // Terms
        let midNodeASymbs = midNode.allSymbs.filter({midSymb in aClone.selfOrChild.allSymbs.contains(where: {$0.isSymbType(type: midSymb.type?.key)})})
        let midNodeDSymbs = midNode.allSymbs.filter({midSymb in dClone.selfOrChild.allSymbs.contains(where: {$0.isSymbType(type: midSymb.type?.key)})})
        aClone.selfOrChild.allSymbs.replaceSimilarKeys(with: midNodeASymbs.flatSKs, withPow: true)
        dClone.selfOrChild.allSymbs.replaceSimilarKeys(with: midNodeDSymbs.flatSKs, withPow: true)
        aClone.selfOrChild.allRadicals.replaceSimilarKeys(with: midNode.allRadicals.flatSKs, withPow: true)
        dClone.selfOrChild.allRadicals.replaceSimilarKeys(with: midNode.allRadicals.flatSKs, withPow: true)
        //
        let midValueSK = midNode.valueSK.filter({$0 != nodes[midNodeIdx].valueSK.first!})
        aClone.selfOrChild.valueSK.replaceSimilarKeys(similarKeys: midValueSK)
        dClone.selfOrChild.valueSK.replaceSimilarKeys(similarKeys: midValueSK.dropSKs(aClone.valueSK))

        //
        if !aClone.isBrackets {
            aClone.setSelfToBrackets(extractOp: true)
        }
        if !dClone.isBrackets {
            dClone.setSelfToBrackets(extractOp: true)
        }
        
        //
        steps.lastMarked.append(contentsOf: [StepNode](nodes[midNodeIdx...midNodeIdx+2]).flatSKs(.dropOp))
        steps.lastExplanation = "Rewrite \(midNode.flatSKs(.dropOp).strForExpl) as 3\(aClone.flatSKs(.dropOp).strForExpl)\(dClone.flatSKs(.dropOp).strForExpl)"
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipRemoveUslessBrackets])
    }
    
    private func factorToCubedBrkt(newParent: StepNode, excludedNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        var nodes: [StepNode] {newParent.children.dropNode(node: excludedNode)}

        //
        steps.lastMarked = nodes.flatSKs(.dropOp)
        let opStr = nodes[1].isMinus ? "-" : "+"
        steps.lastExplanation = "Use a³\(opStr)3a²b+3ab²\(opStr)b³ = (a\(opStr)b)³ to factor the expression"
        
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
        let middleIsBrkts = directNodes.count == 8
        let bFirstStepExprIDs = middleIsBrkts ? directNodes[2].children.first!.flatSKs(.dropOp).ids : directNodes[1].allSymbs.first!.flatSKs(.dropOp).ids
        let bLastStepExprIDs = middleIsBrkts ? directNodes[3].children.first!.flatSKs(.dropOp).ids : directNodes[1].allSymbs.last!.flatSKs(.dropOp).ids
        let cFirstStepExprIDs = middleIsBrkts ? directNodes[5].children.first!.flatSKs(.dropOp).ids : directNodes[2].allSymbs.first!.flatSKs(.dropOp).ids
        let cLastStepExprIDs = middleIsBrkts ? directNodes[6].children.first!.flatSKs(.dropOp).ids : directNodes[2].allSymbs.last!.flatSKs(.dropOp).ids
        let directNodesStepExpr = directNodes.flatSKs
        let opsIds = [directNodes.last!.op.id] + (directNodes[1].isPlus ? [directNodes[middleIsBrkts ? 4 : 2].op.id] : [])
        directNodes.last!.op = directNodes[1].op
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
        steps.appendMergeIDs(originalKeysIDs: directNodes.first!.flatSKs(.dropOp).ids, mergesKeysIDs: [bFirstStepExprIDs, cFirstStepExprIDs])
        steps.appendMergeIDs(originalKeysIDs: directNodes.last!.flatSKs(.dropOp).ids, mergesKeysIDs: [bLastStepExprIDs, cLastStepExprIDs])
        steps.appendMergeIDs(originalKeysIDs: [directNodes.last!.op.id], mergesKeysIDs: opsIds.map({[$0]}))
    }
}
