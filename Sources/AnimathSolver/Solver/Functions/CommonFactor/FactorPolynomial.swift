//
//  FactorPolynomial.swift
//  Hulul
//
//  Created by Ahmad on 27/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func factorPolynomial(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fnCtrl.contains(.forceSkip) {return}
        var nodes: [StepNode] {parent.children}
        guard nodes.isSimplestFormNegletTimesBracket || nodes.is4TermsFactorable else {return}
        
        //
        var otherBrktsStaticIDs = [Int32]()
        if parent.isBrackets {
            otherBrktsStaticIDs = parent.level!.dropNode(node: parent).onlyBrackets.levelStaticIDs
        }
        
        //
        if !fnCtrl.contains(.skipAllExceptFctrBrkt) {
            reorderVarTerms(parentNode: parent, nodeR: StepNode(), fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        extractCommonFactor(nodes: nodes, withOp: nodes.getGCDWithTerms(withOp: false) != nil, fnCtrl: fnCtrl + (nodes.isMinus && !nodes.hasOnlyMinus && nodes.getGCDWithTerms(withOp: false) != nil ? [.forceExtractMinus] : []), &steps)
        removeMultByDivBothSidesOneIsZero(nodeL: parent.root, nodeR: parent.otherSide, fnCtrl: fnCtrl, &steps)
        factorByFormula(parent: nodes.first(where: {$0.isBrackets}) ?? parent, fnCtrl: fnCtrl, &steps)
        factor4TermsByGrouping(nodes: nodes.first(where: {$0.isBrackets})?.children ?? nodes, fnCtrl: fnCtrl, &steps)
        factorOutBrkts(node: nodes.first!, fnCtrl: fnCtrl, &steps)
        factorByRationalRootTheorem(parent: nodes.first(where: {$0.isBrackets}) ?? parent, fnCtrl: fnCtrl, &steps)
        
        //
        for brktNode in (nodes.first(where: {$0.isBrackets}) ?? parent).parent?.children.onlyBrackets.filter({!otherBrktsStaticIDs.contains($0.staticID)}) ?? [] {
            brktNode.pinRootExpr()
            reduceAfterFactorPoly(brktNode: brktNode, fnCtrl: fnCtrl, &steps)
            if brktNode.pinnedRootDidChange {return}
            factorByFormula(parent: brktNode, fnCtrl: fnCtrl.drop(.reduceAfterFctrPoly), &steps)
        }
        for brktNode in (nodes.first(where: {$0.isBrackets}) ?? parent).parent?.children.onlyBrackets ?? [] {
            mergeAndEvaluateEqualBrackets(node: brktNode, fnCtrl: fnCtrl + [.skipPow, .force], &steps)
        }

        //
        if !fnCtrl.contains(.skipAllExceptFctrBrkt) {
            reorderVarTerms(parentNode: parent, nodeR: StepNode(), fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        specialDistributePowerIntoBrackets(node: parent, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func extractCommonFactor(brktNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fnCtrl.contains(.skipExtractCommonFactor) {return}
        if !brktNode.isBrackets || brktNode.children.count == 1 || brktNode.children.hasDecimal {return}
        var gcdNode = brktNode.children.getGCDWithTerms(withOp: true)
        if fnCtrl.contains(.forceExtractMinus) {
            if gcdNode == nil {
                gcdNode = .newOneNode.withOp(.minus)
            } else {
                gcdNode!.op = .minus
            }
        }
        if gcdNode == nil {return}
        
        //
        extractCommonFactorFromBrackets(node: brktNode, factorNode: gcdNode!, fnCtrl: fnCtrl, &steps)
    }
    
    func extractCommonFactor(nodes: [StepNode], withOp: Bool, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        if fnCtrl.contains(.skipExtractCommonFactor) {return}
        if nodes.count > 1 {} else {return}
        if nodes.hasDecimal {return}
        if fnCtrl.contains(.forceExtractMinus) || nodes.getGCDWithTerms(withOp: withOp) != nil {} else {return}
        var brktNode = StepNode()
        if let parent = nodes.parent, parent.isBracketsNotHidden && !parent.isPowered && nodes.first!.level!.isEqualTo(nodes: nodes) {
            brktNode = parent
        } else {
            nodes.setBrackets()
            brktNode = nodes.parent!
        }
        
        //
        extractCommonFactor(brktNode: brktNode, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func willHaveCommonBrkts(nodes: [StepNode], fnCtrl: [FnCtrl]) -> Bool {
        if nodes.isEqualTo(nodes: nodes.first!.level!) && nodes.count == 4 && nodes.isSimplestForm {} else {return false}
        let nodesClones = nodes.clone(changeID: false, withParent: false).children
        let parent = nodesClones.parent!
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = parent.root
        tmpSteps[0].nodeL = parent.root
        appendStep(&tmpSteps, fnCtrl: fnCtrl + [.skipPrintStep])
        groupAndExtractFactor(nodes: nodesClones, fnCtrl: fnCtrl + [.skipPrintStep], &tmpSteps)
        parent.pinRootExpr()
        factorOutBrkts(node: parent.children.first!, fnCtrl: fnCtrl + [.skipPrintStep], &tmpSteps)
        return parent.pinnedRootDidChange
    }
}

extension CalcBrain {
    func specialDistributePowerIntoBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if node.isBrackets(.powered) && (node.children.isMultChain && !node.children.isSingleNode || node.children.isBrackets(.powered)) {} else {return}
        
        // Mark and explain
        steps.lastMarked = node.power.flatSKs
        steps.lastExplanation = "Distribute the exponent over the multiplication"
        
        //
        var shouldBeDroppedFromMerged = StepNode()
        for childNode in node.children.termMix {
            let shouldKeepIDs = childNode.isTerm && childNode.baseNode.isOneTerm && childNode.isFirstTerm || !childNode.isTerm && childNode.isFirst
            if shouldKeepIDs {
                shouldBeDroppedFromMerged = childNode
            }
            let powerClone = node.power.first!.clone(changeID: !shouldKeepIDs, withParent: false)
            if childNode.isPowered {
                powerClone.op = .times
                childNode.power.append(powerClone)
            } else {
                childNode.power = [powerClone]
            }
            steps.lastMarked.append(contentsOf: powerClone.flatSKs(.any))
        }
        
        //
        steps.lastStep.appendCloneIDs(originalKeysIDs: node.power.flatSKs.ids, clonesKeysIDs: node.children.termMix.dropNode(node: shouldBeDroppedFromMerged).map({$0.power.last!}).map({$0.flatSKs.ids}))
        
        // remove parent power
        node.removePower()
        node.removeBracketsGeneral()
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if let powerFirst = node.power.first {
            evaluateMult(node: powerFirst, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}
