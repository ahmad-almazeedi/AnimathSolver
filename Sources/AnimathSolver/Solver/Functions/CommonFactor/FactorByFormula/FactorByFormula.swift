//
//  FactorByFormula.swift
//  Hulul
//
//  Created by Ahmad on 13/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func factorByFormula(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fnCtrl.contains(.skipAllExceptFctrBrkt) {return}
        var nodes: [StepNode] {parent.children}
        if nodes.hasFraction(flat: true) || nodes.hasDecimal {return}
        guard nodes.isEqualTo(nodes: nodes.first!.level!) && nodes.isSimplestForm else {return}
        if nodes.getGCDWithTerms(withOp: false)?.hasVarFlat ?? false {return}
        if !nodes.hasVarFlat || nodes.hasRadicalFlat {return}
        
        //
        parent.pinRootExpr()
        reduceAfterFactorPoly(brktNode: parent, fnCtrl: fnCtrl, &steps)
        if parent.pinnedRootDidChange {return}
        
        //
        if nodes.count == 2 {
            factorDiffOfTwoSquares(parent: parent, fnCtrl: fnCtrl, &steps)
            factorSumOrDiffOfTwoCubes(parent: parent, fnCtrl: fnCtrl, &steps)
            return
        }
        
        //
        if nodes.hasBrackets {return}
        factorPrefectSquares(parent: parent, fnCtrl: fnCtrl, &steps)
        factorPrefectCubed(parent: parent, fnCtrl: fnCtrl, &steps)
        
        //
        guard (parent.isRoot || parent.exist) && nodes.count == 3 else {return}
        if nodes.hasBrackets {return}
        guard nodes.areDegreeOrdered else {return}
        let clones = nodes.clone(changeID: false, withParent: false).children
        let aNode = clones[0]
        let bNode = clones[1]
        let cNode = clones[2]
        factorTriReguler(parent: parent, aNode: aNode, bNode: bNode, cNode: cNode, fnCtrl: fnCtrl, &steps)
        factorTriWithCoeff(parent: parent, aNode: aNode, bNode: bNode, cNode: cNode, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func representNodeAsPowered(to powValue: Int, node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if node.isPowered {return}
        representValueAsPowered(to: powValue, node: node, fnCtrl: fnCtrl, &steps)
        representDirectSymbsAsPowered(to: powValue, node: node, fnCtrl: fnCtrl, &steps)
        mergePowersOfProduct(node: node.exist ? node : node.parent!.children.first!, fnCtrl: fnCtrl, &steps)
    }
    
    private func representValueAsPowered(to powValue: Int, node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if node.valueIsOne && node.isCoeff {return}
        steps.lastMarked = node.valueSK
        steps.lastExplanation = "Write the number in exponential form with an exponent of \(powValue)"
        var poweredSKs = pow(node.valueDouble, 1/Double(powValue)).rounded.newSKs
        poweredSKs.replaceSimilarKeys(similarKeys: node.valueSK)
        node.valueSK = poweredSKs
        node.power = [powValue.newNode]
        steps.lastMarked.append(contentsOf: node.flatSKsNoTerms(.dropOp))
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    private func representDirectSymbsAsPowered(to powValue: Int, node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        for directSymb in node.directSymbs.reversed() {
            
            if directSymb.powerValue > Double(powValue) {} else {continue}
            
            //
            let fristPow = directSymb.power.first!
            let newPowNodes = [(fristPow.valueDouble/Double(powValue)).newNode, powValue.newNode.withOp(.times)]
            
            //
            steps.lastMarked = fristPow.flatSKs + newPowNodes.flatSKs
            steps.lastExplanation = "Rewrite \(fristPow.valueKeys.str) as \(newPowNodes.first!.valueKeys.str)×\(powValue)"
            
            //
            directSymb.power = newPowNodes
            
            //
            appendStep(&steps, fnCtrl: fnCtrl)
            
            //
            steps.lastMarked = directSymb.flatSKs(.dropOp)
            steps.lastExplanation = "Use aᵐⁿ = (aᵐ)ⁿ to transform the expression"
            
            //
            node.extractTerm(directSymb)
            node.next.setBracketsAndExtractOp()
            steps.lastMarked.append(contentsOf: node.next.valueSK)
            node.next.op.idIsZero = true
            node.next.power = [directSymb.power.last!.withOp(.plus)]
            directSymb.power.removeLast()
            if node.isOne {
                node.next.op = node.op
                node.remove()
            }
            
            //
            appendStep(&steps, fnCtrl: fnCtrl)
        }
    }
    func flipPositionsOfTwoNodes(node1: StepNode, node2: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if node1.level!.isEqualTo(nodes: [node1,node2]) {} else {return}
        
        //
        steps.lastMarked = node1.flatSKs + node2.flatSKs
        steps.lastExplanation = UseCommutativePropExplanation
        
        //
        node2.remove()
        node1.insertBefore(node2)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    func reduceAfterFactorPoly(brktNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if !brktNode.exist {return}
        if fnCtrl.contains(.reduceAfterFctrPoly) && brktNode.isBracketsNotHidden {} else {return}
        var fractionNode = StepNode()
        if brktNode.isInFractionGeneral {
            fractionNode = brktNode.parentFractionGeneral!
        } else if let tmpFractionNode = brktNode.multChain(forward: false).first(where: {$0.isFraction}) {
            fractionNode = tmpFractionNode
        }
        reduceFraction(node: fractionNode, fnCtrl: fnCtrl + [.force, .forceReduce, .skipCommonFactor, .skipReduceDivisible, .skipReduceToSimplify], &steps)
    }
}
