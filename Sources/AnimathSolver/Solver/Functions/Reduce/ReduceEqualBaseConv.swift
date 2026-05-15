//
//  ReduceEqualBaseConv.swift
//  Hulul
//
//  Created by Ahmad on 12/12/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func reduceFirstEqualBaseNodesAfterConverting(numNode: StepNode, denChain: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if numNode.isSqrt && numNode.baseNode.isInFraction && numNode.baseNode.parentFraction!.isInFraction {return}
        
        //
        var numNode = numNode
        var denNode = StepNode()
        if numNode.isSqrt, let tmpDenNode = denChain.allSqrts.first(where: {tmpDenNode in
            if tmpDenNode.children.first!.baseOrTermNode.hasEqualBaseIfExpo(with: numNode.children.first!.baseOrTermNode) {} else {return false}
            let allRadicals = [numNode,tmpDenNode]
            if allRadicals.contains(where: {!$0.children.isSingleNode}) {return false}
            if allRadicals.hasPowered {return false}
            if allRadicals.hasRootableRadicand {return false}
            return true
        }) {
            if numNode.isEqualTo(node: tmpDenNode) {return}
            numNode.pinRootExpr()
            nthRootTimesEqualNthRootNTimes(radicalParent: numNode, fnCtrl: fnCtrl, &steps)
            if numNode.pinnedRootDidChange {return}
            denNode = tmpDenNode
            radicalToExponent(radicalParent: numNode, fnCtrl: fnCtrl, &steps)
            radicalToExponent(radicalParent: denNode, fnCtrl: fnCtrl, &steps)
            numNode = numNode.nodeProduct!
            denNode = denNode.nodeProduct!
        } else if numNode.isWholeNumber(mayBePowered: true, mayBeCoeff: true) && numNode.isPowered && numNode.power.isFraction, let tmpDenNode = denChain.first(where: {tmpDenNode in
            numNode.hasEqualBaseIfExpo(with: tmpDenNode) && tmpDenNode.power.isPosSimplestFraction
        }) {
            denNode = tmpDenNode
        } else if numNode.isSqrt && numNode.children.isSingleNode && !numNode.isPowered && !numNode.isRootable(indexValue: numNode.indexValue), let tmpDenNode = denChain.first(where: {tmpDenNode in
            if tmpDenNode.power.isPosSimplestFraction {} else {return false}
            if numNode.children.first!.baseOrTermNode.hasEqualBaseIfExpo(with: tmpDenNode) {} else {return false}
            return true
        }) {
            numNode.pinRootExpr()
            nthRootTimesEqualNthRootNTimes(radicalParent: numNode, fnCtrl: fnCtrl, &steps)
            if numNode.pinnedRootDidChange {return}
            radicalToExponent(radicalParent: numNode, fnCtrl: fnCtrl, &steps)
            numNode = numNode.nodeProduct!
            denNode = tmpDenNode
        } else if numNode.isWholeNumber(mayBePowered: true, mayBeCoeff: true) && numNode.isPowered && numNode.power.isFraction, let tmpDenNode = denChain.allSqrts.first(where: {tmpDenNode in
            if tmpDenNode.children.isSingleNode && !tmpDenNode.isPowered && !tmpDenNode.isRootable(indexValue: tmpDenNode.indexValue) {} else {return false}
            if tmpDenNode.children.first!.baseOrTermNode.hasEqualBaseIfExpo(with: numNode) {} else {return false}
            return true
        }) {
            denNode = tmpDenNode
            radicalToExponent(radicalParent: denNode, fnCtrl: fnCtrl, &steps)
            denNode = denNode.nodeProduct!
        } else {return}
        
        //
        simplifyPoweredsByFraction(nodes: [numNode, denNode], fnCtrl: fnCtrl, &steps)
        
        //
        reduceFirstEqualBaseNodes(numNode: (numNode.nodeProduct ?? numNode).baseOrTermNodeOrSelfTerm, denChain: [(denNode.nodeProduct ?? denNode).baseOrTermNodeOrSelfTerm], fnCtrl: fnCtrl, sameFraction: false, &steps)
    }
}
