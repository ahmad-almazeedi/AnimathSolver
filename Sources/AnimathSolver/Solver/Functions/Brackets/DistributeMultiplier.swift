//
//  DistributeMultInBrackets.swift
//  Hulul
//
//  Created by Ahmad on 01/06/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func distributeMultiplier(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if fnCtrl.contains(.skipDistribute) {return}
        if node.children.isMulti {} else {return}
        if node.isBrackets(.simplest) || (node.isBrackets(.complete) && fnCtrl.isForced) {} else {return}
        if node.isPowered {return}
        var multNode = StepNode()
        var isPrevMult = true
        if !node.prev.isBrackets(.complete) && node.isTimes && !node.isDivide && node.nextNonMultBrkt == nil && !node.prev.isTimes && !node.prev.isPowered {multNode = node.prev}
        else if node.next.isTimes && !node.next.isPowered && !node.next.isBrackets && node.next.nextNonMultBrkt == nil {
            multNode = node.next
            isPrevMult = false
        } else {return}
        if multNode.isSurfed && !fnCtrl.isForced {return}
        if multNode.isOne || multNode.isDivide || multNode.isFraction(.notSimplestReduced) {return}
        guard let level = node.level else {return}
        if node.parent!.isDivide && level.isMultChain {return}
        if !fnCtrl.contains(.forceDistribute) && node.children.hasOnlyFractions && node.children.denominatorsParents.nodesAreEqual {return}
        if node.isInDenominatorAndWillAddFractions {return}
        if node.isInFraction && level.isMultChain && (node.parentFraction!.isInFraction && node.parentFraction!.isAlone || node.otherPartOfTheFraction.isFraction) {return}
        if !node.children.hasVarFlat && !node.children.hasFraction(flat: true) && multNode.isOneSingleVar(mayBeInSqrt: true) && node.isEquation && !node.otherSide.hasVarFlat && level.dropNode(node: multNode).dropNode(node: node).isEmpty {return}
        if multNode.isFraction(.notSingle(for: .any)) || multNode.flatTree.contains(where: {$0.isPoweredByNegative}) {return}
        if multNode.isFraction(part: .denominator, {$0.hasRadicalFlat}) {
            multNode.pinRootExpr()
            rationalizeSingleDenominator(node: multNode, fnCtrl: fnCtrl + [.forceRationalizeDen], &steps)
            if multNode.pinnedRootDidChange {return}
        }
        let multChain = node.multChain(forward: false)
        if !fnCtrl.contains(.forceDistribute) && multNode.isFraction && willHaveFractionAfterDistribute(multNode: multNode) && (multNode.denominator.hasVar && !node.children.hasFraction(flat: true) || multChain.dropNode(node: node).hasBrackets(.any) && !multChain.onlyBrackets.hasFraction(flat: true)) {return}
        if node.root.otherSide.isEmpty || fnCtrl.isForced {}
        else {
            if !node.isInFractionGeneral && willHaveFractionAfterDistribute(multNode: multNode) {
                if node.isChild {}
                else if !node.root.flatTree.hasVar && node.root.otherSide.children.isNumberWithX(mayBeDecimal: true, mayBeOneVar: true) {
                    if !fnCtrl.contains(.forceDistribute) && willDivideBothSides(nodeL: node.root, nodeR: node.otherSide) {return}
                } else {
                    //                  if !multNode.isFraction && node.otherSide.children.isSingle(mayBeFraction: false, mayBePowered: true) {} else {return}
                    if multBothSidesAllowed(nodeL: node.root, nodeR: node.root.otherSide, fnCtrl: fnCtrl) {return}
                    if !fnCtrl.contains(.forceDistribute) && willMultBothSides(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl + [.skipDistribute]) {return}
                    if !fnCtrl.contains(.forceDistribute) && willDivideBothSides(nodeL: node.root, nodeR: node.otherSide) {return}
                }
            } else if multNode.isFraction {
                let factorNode = multNode.denominator.first!.clone(changeID: true, withParent: false)
                extractCommonFactorFromBrackets(node: node, factorNode: factorNode, fnCtrl: fnCtrl, &steps)
                return
            } else {
                if multNode.isDecimal {
                    if !fnCtrl.contains(.forceDistribute) && !node.children.hasDecimal && !willHaveOneSingleVarAfterDistribute(multNode: multNode) && willHaveDecimalInEquation(nodeL: multNode.root, nodeR: multNode.otherSide, fnCtrl: fnCtrl + [.forceDistribute]) {return}
                } else {
                    if multBothSidesAllowed(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl) {return}
                    if !fnCtrl.contains(.forceDistribute) && willDivideBothSides(nodeL: node.root, nodeR: node.otherSide) {return}
                }
            }
            if removeAllDenominatorsAllowed(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl) {return}
        }
        if let radParent = multNode.radicalParent {
            if radParent.children.isFraction {return}
            if radParent.children.hasVarFlat {
                radParent.pinRootExpr()
                factorPerfectSquareThenEvalOrSimpSqrt(radicalParent: radParent, fnCtrl: fnCtrl, &steps)
                evaluateNthPowerInNthRoot(radicalParent: radParent, fnCtrl: fnCtrl, &steps)
                evaluateMultipleOfNthPowerInNthRoot(radicalParent: radParent, fnCtrl: fnCtrl, &steps)
                if radParent.pinnedRootDidChange {return}
            }
        }
        if !fnCtrl.isForced && node.root.otherSide.isEmpty && multNode.isFraction && !willHaveFractionAfterDistribute(multNode: multNode) {
            let factorNode = multNode.denominator.first!.clone(changeID: true, withParent: false)
            extractCommonFactorFromBrackets(node: node, factorNode: factorNode, fnCtrl: fnCtrl, &steps)
            return
        }
        if node.root.children.isSimplestFormWithVarTimesBrkts {return}
        if let parentFraction = node.parentFraction {
            if willBeReducible(node: parentFraction, fnCtrl: fnCtrl + [.skipDistribute]) {return}
        }
        if fnCtrl.isCheckAllowed {node.changeContent(); return}
        
        //
        if !fnCtrl.contains(.forceDistribute) {
            let root = node.root
            solveNonLinearEq(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl, &steps)
            if root.children.flatTree.hasBrackets {} else {return}
        }
        
        //
        executeDistributeMultiplier(node: node, multNode: multNode, isPrevMult: isPrevMult, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    private func executeDistributeMultiplier(node: StepNode, multNode: StepNode, isPrevMult: Bool, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
  
        //
        let originalBrktsContent = node.children.clone(changeID: false, withParent: false).children
        
        // Mark and explain
        let dropFirstOp = isPrevMult && multNode.isPlus && node.children.isPlus
        steps.lastMarked = multNode.flatSKs(dropFirstOp ? .dropOp : .any) + node.flatSKs(node.isMinus || !isPrevMult ? .dropOp : .any)
        let isSingleFraction = multNode.isFraction(.singlePositiveNumber(mayBePowered: false, mayHaveCoeff: false, for: .all))
        steps.lastExplanation = "Distribute \(multNode.flatSKs(.onlyMinus).filter({!isSingleFraction || !$0.key.isCurlyBrkt}).strForExpl) through the parentheses" // account for next mult being minus single bracket
        
        // Init Substeps
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastMarked = multNode.flatSKs(.dropPlus) + node.opValueSK(node.isMinus || !isPrevMult ? .dropOp : .any)
        steps.lastStepSubsteps.lastExplanation = "Multiply each term in the parentheses by \(multNode.flatSKs(.onlyMinus).filter({!isSingleFraction || !$0.key.isCurlyBrkt}).strForExpl)"
        
        // Distribute
        var bracketsContent = [StepNode]()
        var distNodes = [StepNode]()
        if isPrevMult {
            distributePrevMult(brktNode: node, multNode: multNode, bracketsContent: &bracketsContent, distNodes: &distNodes, steps: &steps.lastStepSubsteps)
        } else {
            distributeNextMult(brktNode: node, multNode: multNode, bracketsContent: &bracketsContent, distNodes: &distNodes)
        }
        
        //
        for distNode in distNodes {
            steps.lastStepSubsteps.lastMarked.append(contentsOf: distNode.flatSKs(multNode.isMinus ? .any : .dropOp) + bracketsContent.flatSKs.filter({$0.key.isTimes}))
            steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: multNode.flatSKs(multNode.isMinus || multNode.isTimes ? .any : .dropOp).ids, clonesKeysIDs: distNodes.map({$0.flatSKs(multNode.isMinus || multNode.isTimes ? .any : .dropOp).ids}))
        }
        
        // Reorder no steps
        var fakeSteps = [StepModel()]
        for node in bracketsContent {
            reorderTermsFromOut(node: node, fnCtrl: fnCtrl + [.skipAppendStep], &fakeSteps)
        }
        
        // Append step
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        // Skip rest
        if fnCtrl.contains(.skipDistributeEval) {
            appendStep(&steps, fnCtrl: fnCtrl)
            return
        }
        
        // Evaluate
        let nonBrktContent = bracketsContent.first!.level!.dropNodes(nodes: bracketsContent)
        surfAndApplyFn(mainNode: bracketsContent.parent!, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: .removeHighOpOne, &steps.lastStepSubsteps)
        repeat {
            bracketsContent.first!.pinRootExpr()
            for inNode in bracketsContent.first!.level!.dropNodes(nodes: nonBrktContent) {
                if let radicalParent = inNode.radicalParent {
                    let coeff = radicalParent.coeffNode
                    coeff.pinRootExpr()
                    nthRootTimesEqualNthRootNTimes(radicalParent: radicalParent, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
                    if coeff.pinnedRootDidChange {continue}
                }
                evaluateChildren(node: inNode, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps.lastStepSubsteps)
                determineChainSign(node: inNode, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
                reduceFraction(node: inNode, fnCtrl: fnCtrl + [.force, .forceReduce, .skipFlattenning], &steps.lastStepSubsteps)
                mergeWithFraction(node: inNode, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
                evaluateMult(node: inNode, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps.lastStepSubsteps)
                reorderTermsFromOut(node: inNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
                reorderTermsFromIn(node: inNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            }
        } while bracketsContent.first!.pinnedRootDidChange
        
        //
        if !fnCtrl.contains(where: {$0 == .skipAppendStep || $0 == .skipPrintStep}) && steps.lastStepLastSubsteps.count > 2 {
            var newBrktsContent = (nonBrktContent.isEmpty ? bracketsContent.first(where: {$0.exist})!.level! : nonBrktContent.first!.level!.dropNodes(nodes: nonBrktContent))
            newBrktsContent = isPrevMult ? newBrktsContent : newBrktsContent.reversed()
            if originalBrktsContent.count == newBrktsContent.count {
                let multNodeAndFirstChild = [multNode, isPrevMult ? originalBrktsContent.first! : originalBrktsContent.last!]
                if let fractionNode = multNodeAndFirstChild.first(where: {$0.isFraction}), !multNodeAndFirstChild.hasOnlyFractions && newBrktsContent.first!.isFraction {
                    let numStepExpr = fractionNode.numerator.flatSKs(.dropPlus)
                    let denStepExpr = fractionNode.denominator.flatSKs(.dropPlus)
                    newBrktsContent.first!.numerator.first!.changeIDs()
                    newBrktsContent.first!.denominator.first!.changeIDs()
                    newBrktsContent.first!.numerator.replaceSimilarKeys(with: numStepExpr, withPow: false)
                    newBrktsContent.first!.denominator.replaceSimilarKeys(with: denStepExpr, withPow: false)
                    steps.lastMarked.append(contentsOf: newBrktsContent.first!.flatSKs(dropFirstOp || !isPrevMult ? .dropOp : .any))
                }
                for i in 0..<originalBrktsContent.count {
                    if ![multNode, newBrktsContent[i]].hasFraction(flat: false) {
                        newBrktsContent[i].replaceSimilarKeys(with: (isPrevMult ? originalBrktsContent : originalBrktsContent.reversed())[i].flatSKsNoPow.dropFirstIfOp, withPow: false)
                    }
                }
                steps.lastStep.appendCloneIDs(originalNode: multNode, cloneNodes: newBrktsContent, withOp: false)
            }
        }
        
        // Append changes to main steps
        steps.lastMarked.append(contentsOf: bracketsContent.filter({$0.exist}).opValuesSK(dropFirstOp || !isPrevMult ? .dropOp : .any) + steps.lastStepSubsteps.allMarkedKeys.dropFirstIfOp)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    private func distributePrevMult(brktNode: StepNode, multNode: StepNode, bracketsContent: inout [StepNode], distNodes: inout [StepNode], steps: inout [StepModel]) {
        for inNode in brktNode.children.filter({$0.isPlusOrMinus}) {
            let distNode = multNode.clone(changeID: inNode.isFirst ? false : true, withParent: false)
            distNode.changeStaticIDWithChildren()
            let originalOp = inNode.op
            if distNode.isMinus {
                inNode.setTimesAndParenIfNeg()
                if inNode.isBrackets {
                    steps.lastMarked.append(contentsOf: inNode.valueSK)
                }
            }
            if inNode.isMinus || !inNode.isFirst {
                if !distNode.isMinus {
                    distNode.op = inNode.op
                } else if !originalOp.key.isMinus {
                    steps.lastMarked.append(originalOp)
                }
            }
            if !inNode.isFirst {
                distNodes.append(distNode)
            }
            inNode.op = .times
            inNode.insertBefore(distNode)
        }
        brktNode.op = multNode.isPlus ? multNode.op : .plus
        // Don't add op to markedKeys because of explain how opacity problems in this: 1−2×(𝒙+1)×(𝒙+2)
        multNode.remove()
        bracketsContent = brktNode.children
        if brktNode.isPlus && !brktNode.isMultipliedOrDivided {
            brktNode.justRemoveBrackets()
        }
    }
    
    private func distributeNextMult(brktNode: StepNode, multNode: StepNode, bracketsContent: inout [StepNode], distNodes: inout [StepNode]) {
        for inNode in brktNode.children {
            if inNode.next.isTimes {continue}
            let distNode = multNode.clone(changeID: inNode.isLast ? false : true, withParent: false)
            distNode.changeStaticIDWithChildren()
            if !inNode.isLast {
                distNodes.append(distNode)
            }
            inNode.insertAfter(distNode)
        }
        bracketsContent = brktNode.children
        multNode.remove()
        if brktNode.isPlus && !brktNode.isMultipliedOrDivided {
            brktNode.justRemoveBrackets()
        }
    }
}

extension CalcBrain {
    func distributeAllowed(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeClone = node.clone(changeID: false, withParent: true)
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        distributeMultiplier(node: nodeClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed, .forceDistribute], &tmpSteps)
        return nodeClone.pinnedRootDidChange
    }
}
