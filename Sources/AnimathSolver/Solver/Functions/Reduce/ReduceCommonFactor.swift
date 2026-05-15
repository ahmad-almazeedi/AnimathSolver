//
//  ReduceCommonFactor.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func reduceFirstCommonFactorNodes(brktNode: StepNode, divChain: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !brktNode.exist {return}
        if brktNode.isBrackets(.simplest) && brktNode.children.count > 1 && !brktNode.children.hasFraction(flat: true) {} else {return}
        if brktNode.isPowered {return}
        var onlyTerm = false
        var divNodes = [StepNode]()
        if let tmpDivNode = divChain.first(where: {!$0.isBrackets(.complete) && ([$0] + brktNode.children).getGCD != nil}) {
            divNodes = [tmpDivNode]
        } else {
            onlyTerm = true
        }
        if onlyTerm {
            if let tmpDivNode = divChain.first(where: {!$0.isBrackets(.complete) && !((brktNode.children+[$0]).getCommonSymbs.isEmpty && (brktNode.children+[$0]).getCommonRadical == nil)}) {
                divNodes = [tmpDivNode]
            }
        }
        if divNodes.isEmpty {
            onlyTerm = false
            if let tmpDivNode = divChain.first(where: {$0.isBrackets(.simplest) && !$0.isPowered && ($0.children + brktNode.children).getGCD != nil}) {
                divNodes = tmpDivNode.children
            } else {
                onlyTerm = true
            }
            if onlyTerm {
                if let tmpDivNode = divChain.first(where: {$0.isBrackets(.simplest) && !$0.isPowered && !((brktNode.children+$0.children).getCommonSymbs.isEmpty && (brktNode.children+$0.children).getCommonRadical == nil)}) {
                    divNodes = tmpDivNode.children
                }
            }
        }
        if divNodes.isEmpty {return}
        if fnCtrl.isCheckAllowed {brktNode.root.changeContent(); return}
        
        //
        var gcdNode = StepNode.newOneNode
        if !onlyTerm {
            let gcd = (divNodes + brktNode.children).getGCD!
            gcdNode = gcd.newSKs.newNode
        }
        gcdNode.directSymbs = (brktNode.children+divNodes).getCommonSymbs
        gcdNode.radicalParent = (brktNode.children+divNodes).getCommonRadical
        let otherGCDNode = gcdNode.clone(changeID: false, withParent: false)
        
        //
        var newBrktNode = brktNode
        if brktNode.parent!.isFraction {
            newBrktNode = StepNode.newBracketsNode
            newBrktNode.children = brktNode.children
            brktNode.children = [newBrktNode]
        }
        extractCommonFactorFromBrackets(node: newBrktNode, factorNode: gcdNode, fnCtrl: fnCtrl, &steps)
        
        //
        if divNodes.count > 1 {
            var newDivBrktNode = StepNode()
            newDivBrktNode = divNodes.parent!
            if !newDivBrktNode.isBrackets {
                steps.setToUnableToSolve(nodeL: brktNode.root, nodeR: brktNode.otherSide)
                return
            }
            if newDivBrktNode.parent!.isFraction {
                let fractionHiddenBracketsNode = newDivBrktNode
                newDivBrktNode = StepNode.newBracketsNode
                newDivBrktNode.children = divNodes
                fractionHiddenBracketsNode.children = [newDivBrktNode]
            }
            otherGCDNode.directSymbs.matchStaticIDOfFirstEquaSymbs(symbNodes: newDivBrktNode.allSymbs)
            extractCommonFactorFromBrackets(node: newDivBrktNode, factorNode: otherGCDNode, fnCtrl: fnCtrl, &steps)
        }
        
        // reduce
        let firstInChain = newBrktNode.isInFraction ? newBrktNode.parentFraction!.multChain(forward: false).first! : newBrktNode.multChain(forward: false).first!
        reduceFraction(node: firstInChain, fnCtrl: fnCtrl + [.skipCommonFactor, .forceReduce], &steps)
    }
}
