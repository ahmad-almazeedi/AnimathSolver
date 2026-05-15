//
//  SurfAndReduce.swift
//  Hulul
//
//  Created by Ahmad on 06/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    enum ReduceCase {
        case equal, equalBase, divisibleNumToDen, divisibleDenToNum, simplify, commonFactor//, exponentiable
    }
    func reduceFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if fnCtrl.contains(.skipReduce) {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isTerm {return}
        let multChain = node.multChain(forward: true)
        if multChain.count == 1 && node.isNumber(mayBePowered: true) {return}
        if !multChain.hasFraction(flat: false) {return}
        let hasFractionNotOnlyTimesNotSimplestForm = multChain.hasFraction(part: .any, {!$0.hasOnlyTimes && !$0.isSimplestForm})
        if fnCtrl.contains(.skipCommonFactor) && hasFractionNotOnlyTimesNotSimplestForm {return}
        if multChain.hasFraction(part: .any, {!$0.isSmplstFormOrMultChainOrIs4TermsFactorable}) {return}
        let chainNodes = multChain.chain1stLevelFlatNodes
        if chainNodes.hasNegPower {return}
        if chainNodes.contains(where: {!$0.power.isSimplestForm || $0.isDoublePowered}) {return}
        if !fnCtrl.contains(.forceReduce) && chainNodes.hasBrackets({!$0.isSmplstFormOrMultChainOrIs4TermsFactorable}) {return}
        if !hasFractionNotOnlyTimesNotSimplestForm && multChain.hasNegativeDropFirst {return}
        if !fnCtrl.contains(.forceReduce) && multChain.count == 1 && !node.isReducingEqualsAndNoLargerMultiples && !node.denIsMultipleOfAllDensAfterReduce && (node.willBeAddedToFraction || node.denIsMultipleOrDividerOfOtherDens) {return}
        if !fnCtrl.contains(.forceReduce) && !node.otherSide.isEmpty && removeAllDenominatorsAllowed(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl) {return}

        // Reduce
        if !hasFractionNotOnlyTimesNotSimplestForm && (fnCtrl.contains(.forceReduce) || !chainNodes.hasBrackets({!$0.hasOnlyTimes && !$0.isSimplestForm})) {
            reduceForCase(.equal, node: node, fnCtrl: fnCtrl + [.keepTargets], &steps)
            reduceForCase(.equalBase, node: node, fnCtrl: fnCtrl + [.force], &steps)
            if !fnCtrl.contains(.skipReduceDivisible) {
                reduceForCase(.divisibleNumToDen, node: node, fnCtrl: fnCtrl + [.force, .keepTargets], &steps)
                reduceForCase(.divisibleDenToNum, node: node, fnCtrl: fnCtrl + [.force, .keepTargets], &steps)
            }
            if !fnCtrl.contains(.skipReduceToSimplify) {
                reduceForCase(.simplify, node: node, fnCtrl: fnCtrl + [.force, .keepTargets], &steps)
            }
        }
        if !fnCtrl.contains(.skipCommonFactor) {
            reduceForCase(.commonFactor, node: node, fnCtrl: fnCtrl + [.force, .keepTargets], &steps)
        }
        if !fnCtrl.isKeepTargets {
            node.root.setTargetedToFalse()
        }
    }
    func reduceForCase(_ reduceCase: ReduceCase, node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if fnCtrl.isCheckAllowed && node.root.isCommaNode {return}
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if reduceCase != .equal && node.isInDividedMultChain {return}
        if node.isPlusOrMinus {} else {return}
        let equalBaseOrEqual = reduceCase == .equal || reduceCase == .equalBase
        let isDivisibleCase = reduceCase == .divisibleDenToNum || reduceCase == .divisibleNumToDen
        var denChain: [StepNode] {node.denominatorMultChain(termMix: equalBaseOrEqual).filter({equalBaseOrEqual || !($0.isDecimal && !isDivisibleCase || $0.isBrackets && reduceCase != .commonFactor)})}
        var numChain: [StepNode] {node.numeratorMultChain(termMix: equalBaseOrEqual).filter({equalBaseOrEqual || !($0.isDecimal && !isDivisibleCase || $0.isBrackets && reduceCase != .commonFactor)})}

        // Reduce
        for sameFraction in (fnCtrl.contains(.skipReduceSameFraction) || reduceCase == .commonFactor ? [false] : [true, false]) {
            for numNode in numChain {
                if fnCtrl.isCheckAllowed && node.root.isCommaNode {return}
                if !node.exist {return}
                var tmpNumNode = numNode
                if numNode.hasParent && !numNode.parent!.valueSK.isEmpty && numNode.parent!.valueSK.first!.key.isCurlyBrkt && !numNode.isInFraction {
                    tmpNumNode = numNode.parent!.parent!
                }
                if !numChain.containsNode(tmpNumNode) {continue}
                if fnCtrl.targetOnly && !tmpNumNode.isBrktsNotSqrt && !tmpNumNode.isTarget {continue}
                switch reduceCase {
                case .equal:
                    reduceFirstEqualNodes(numNode: &tmpNumNode, denChain: denChain, fnCtrl: fnCtrl, sameFraction: sameFraction, &steps)
                case .equalBase:
                    tmpNumNode.pinRootExpr()
                    reduceFirstEqualBaseNodes(numNode: tmpNumNode, denChain: denChain, fnCtrl: fnCtrl, sameFraction: sameFraction, &steps)
                    if tmpNumNode.pinnedRootDidChange {continue}
                    reduceFirstEqualBaseNodesAfterConverting(numNode: tmpNumNode, denChain: denChain, fnCtrl: fnCtrl, &steps)
                case .divisibleNumToDen:
                    reduceFirstDivisibleNodes(numNode: tmpNumNode, denChain: denChain.dropBracketsNotSingleNeg, numToDen: true, fnCtrl: fnCtrl, sameFraction: sameFraction, &steps)
                case .divisibleDenToNum:
                    reduceFirstDivisibleNodes(numNode: tmpNumNode, denChain: denChain.dropBracketsNotSingleNeg, numToDen: false, fnCtrl: fnCtrl, sameFraction: sameFraction, &steps)
                case .simplify:
                    reduceFirstToSimplifyNodes(numNode: tmpNumNode, denChain: denChain, fnCtrl: fnCtrl, sameFraction: sameFraction, &steps)
                case .commonFactor:
                    tmpNumNode.pinRootExpr()
                    reduceFirstCommonFactoredPolynomials(brktNode: tmpNumNode, divChain: denChain, fnCtrl: fnCtrl, &steps)
                    if tmpNumNode.pinnedRootDidChange {continue}
                    reduceFirstCommonFactorNodes(brktNode: tmpNumNode, divChain: denChain, fnCtrl: fnCtrl, &steps)
                }
                if !node.exist {return}
            }
        }
        
        if reduceCase == .commonFactor { //}|| reduceCase == .exponentiable {
            
            if fnCtrl.isCheckAllowed && node.root.isCommaNode {return}
            if !node.exist {return}

            for denNode in denChain {
              
                // Conditions
                if fnCtrl.isCheckAllowed && node.root.isCommaNode {return}
                if !node.exist {return}
                if !denChain.containsNode(denNode) {continue}
                if fnCtrl.targetOnly && !denNode.isBrackets && !denNode.isTarget {continue}

                // Actions
                if reduceCase == .commonFactor {
                    denNode.pinRootExpr()
                    reduceFirstCommonFactoredPolynomials(brktNode: denNode, divChain: numChain, fnCtrl: fnCtrl, &steps)
                    if denNode.pinnedRootDidChange {continue}
                    reduceFirstCommonFactorNodes(brktNode: denNode, divChain: numChain, fnCtrl: fnCtrl, &steps)
                } else {
//                    reduceFirstExponentiable(numNode: denNode, denChain: numChain, fnCtrl: fnCtrl, sameFraction: false, &steps)
                    if !denNode.exist {return}
                }
            }
        }
    }
}

extension CalcBrain {
    func isReducible(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
      
        //
        if fnCtrl.contains(.skipReduce) {return false}
        if !node.baseNode.root.isRoot {return false}
        let nodeClone = node.clone(changeID: false, withParent: true)
        let multChain = nodeClone.multChain(forward: false)
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        stepsInit(nodeL: nodeClone.root, nodeR: StepNode(), fnCtrl: fnCtrl + [.skipPrintStep], steps: &tmpSteps)      
        
        //
        nodeClone.pinRootExpr()
        reduceDividedFraction(node: nodeClone, fnCtrl: fnCtrl, &tmpSteps)
        if nodeClone.pinnedRootDidChange {return true}
       
        //
        if multChain.isEmpty {return false}
        let multChainFirst = multChain.first!

        //
        nodeClone.pinRootExpr()
        reduceSubFractionDens(node: multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep, .checkAllowed], &tmpSteps)
        if nodeClone.pinnedRootDidChange {return true}
    
        //
        nodeClone.pinRootExpr()
        if multChainFirst.exist {
            reduceFraction(node: multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep, .forceReduce, .checkAllowed], &tmpSteps)
        }
        
        //
        if nodeClone.pinnedRootDidChange {
            return true
        } else if let parentFraction = node.parentFraction {
            return isReducible(node: parentFraction, fnCtrl: fnCtrl)
        }
        return false
    }
    func isReducibleAfterDetermineMinus(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
     
        //
        if !node.baseNode.root.isRoot {return false}
        let nodeClone = node.clone(changeID: false, withParent: true)
        let multChain = nodeClone.multChain(forward: false)
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        
        //
        nodeClone.pinRootExpr()
        reduceDividedFraction(node: nodeClone, fnCtrl: fnCtrl, &tmpSteps)
        if nodeClone.pinnedRootDidChange {return true}
       
        //
        if multChain.isEmpty {return false}
        let multChainFirst = multChain.first!

        //
        determineChainSignTillEnd(node: nodeClone.root, fnCtrl:  fnCtrl + [.skipPrintStep], &tmpSteps)
     
        //
        nodeClone.pinRootExpr()
        reduceSubFractionDens(node: multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep, .checkAllowed], &tmpSteps)
        if nodeClone.pinnedRootDidChange {return true}

        //
        nodeClone.pinRootExpr()
        if multChainFirst.exist {
            reduceFraction(node: multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep, .forceReduce, .checkAllowed], &tmpSteps)
        }
        
        //
        return nodeClone.pinnedRootDidChange
    }
    func isReducibleAfterFactoring(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        
        //
        if !node.baseNode.root.isRoot {return false}
        let nodeClone = node.clone(changeID: false, withParent: true)
        let multChainFirst = nodeClone.multChain(forward: false).first!
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        
        //
        nodeClone.pinRootExpr()
        reduceForCase(.commonFactor, node: multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep], &tmpSteps)
        return nodeClone.pinnedRootDidChange
    }
    func isNestedFractionReducibleAfterDetermineMinus(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if !node.baseNode.root.isRoot {return false}
        let nodeClone = node.clone(changeID: false, withParent: true)
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        determineChainSignTillEnd(node: nodeClone.root, fnCtrl:  fnCtrl + [.skipPrintStep], &tmpSteps)
        nodeClone.pinRootExpr()
        reduceSubFractionDens(node: nodeClone, fnCtrl: fnCtrl + [.force, .skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeClone.pinnedRootDidChange
    }
    func willHaveFractionAfterReduce(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeClone = node.clone(changeID: false, withParent: true)
        let multChain = nodeClone.multChain(forward: false)
        if multChain.isEmpty {return false}
        let multChainFirst = multChain.first!
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        guard let level = nodeClone.level else {return false}
        let multNode = level.last!
        reduceFraction(node: multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep, .forceReduce], &tmpSteps)
        return (level.hasFraction(flat: false) || nodeClone.isAlone) && multNode.exist
    }
    func willBeReducible(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if fnCtrl.isCheckAllowed || fnCtrl.skipPrintStep {return false}
        let nodeClone = node.clone(changeID: false, withParent: true)
        let multChain = nodeClone.multChain(forward: false)
        if multChain.isEmpty {return false}
        let newRoot = StepNode()
        newRoot.children = multChain
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = newRoot
        tmpSteps[0].nodeL = newRoot
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        surfAndEvaluateAndApplyFnTillEnd(parent: newRoot, fnCtrl: fnCtrl + [.skipPrintStep, .skipReduce], &tmpSteps)
        return isReducible(node: newRoot.children.first!, fnCtrl: fnCtrl + [.force, .skipPrintStep, .forceReduce, .checkAllowed])
    }
}
