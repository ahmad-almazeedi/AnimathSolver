//
//  ReduceEqualBase.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func reduceFirstEqualBaseNodes(numNode: StepNode, denChain: [StepNode], fnCtrl: [FnCtrl], sameFraction: Bool, _ steps: inout [StepModel]) {
        
        // Conditions
        guard var denNode = denChain.first(where: {$0.hasEqualBase(with: numNode) && $0.isPoweredByPosOrNotPowered && numNode.isPoweredByPosOrNotPowered && (($0.power+numNode.power).hasOnlyWholeNumbers ? $0.powerResult != numNode.powerResult : !$0.power.isEqualTo(nodes: numNode.power)) && (!sameFraction || $0.isInSameFraction(with: numNode, shouldBeSingle: true))}) else {return}
        if fnCtrl.isCheckAllowed {numNode.root.changeContent(); return}
        numNode.numeratorMultChain(termMix: true).setSurfedToTrue()
        denChain.setSurfedToTrue()
        numNode.isReduced = true
        denNode.isReduced = true
        
        //
        numNode.pinRootExpr()
        multiplySameBaseWithFractionAsPower(node: numNode.baseNode, fnCtrl: fnCtrl + [.skipMergeSameBaseIfAlone], &steps)
        multiplySameBaseWithFractionAsPower(node: denNode.baseNode, fnCtrl: fnCtrl + [.skipMergeSameBaseIfAlone], &steps)
        if numNode.pinnedRootDidChange {return}
        
        // Flip Positions if appropriate
        if numNode.isBrackets && numNode.children.count == 2 && !numNode.children.first!.isEqualTo(node: denNode.children.first!) {
            let toFlipBrkt = [numNode, denNode].first(where: {$0.children.isMinus}) ?? numNode
            flipPositionsOfTwoNodes(node1: toFlipBrkt.children.first!, node2: toFlipBrkt.children.last!, fnCtrl: fnCtrl, &steps)
        }
        
        // set
        let allPowers = numNode.power+denNode.power
        var largerBase = allPowers.hasVarFlat || numNode.powerResult > denNode.powerResult ? numNode : denNode
        var smallerBase = allPowers.hasVarFlat || numNode.powerResult > denNode.powerResult ? denNode : numNode
        var willHaveNotPosSingle = numNode.isPoweredByMultiple || denNode.isPoweredByMultiple || allPowers.hasFraction(flat: true)
        
        // Mark and strike and explain
        steps.lastMarked = numNode.flatSKsNoTerms(.dropOp) + denNode.flatSKsNoTerms(.dropOp)
        steps.lastExplanation = allPowers.hasTerm ? "Simplify the expression" : "Cancel out the common factor \(smallerBase.flatSKsNoTerms(.dropOp).strForExpl)" // determineMarkedNodes() is depending on this string
        steps.lastStrikeKeys = [numNode.strikeKey, denNode.strikeKey]
        
        // Mark terms if in brackets
        if numNode.isBrackets {
            steps.lastMarked.append(contentsOf: numNode.allTerms.flatSKs + denNode.allTerms.flatSKs)
        }
        
        // Init substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Set power to one
        var bothNodes = [smallerBase, largerBase]
        for i in 0...1 {
            if !bothNodes[i].isPowered {
                // Mark and explain
                steps.lastStepSubsteps.lastExplanation = setExponentToOneExplanation
                // set power to one
                if bothNodes[i].parent!.valueKeys == [.fraction] {
                    bothNodes[i].children.setBrackets()
                    bothNodes[i] = bothNodes[i].children.first!
                    if denNode.hasEqualID(with: bothNodes[i].parent!) {
                        denNode = bothNodes[i]
                    }
                }
                bothNodes[i].power = [.newOneNode]
                steps.lastStepSubsteps.lastMarked = bothNodes[i].valueSKOrStepExprIfBrkts + [bothNodes[i].power.first!.valueSK.first!]
                // append step
                appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
            }
        }
        smallerBase = bothNodes.first!
        largerBase = bothNodes.last!
        
        // mark and explain
        steps.lastStepSubsteps.lastMarked.append(contentsOf: largerBase.power.flatSKs + smallerBase.power.flatSKs)
        steps.lastStepSubsteps.lastExplanation = "Divide the \(numNode.isBrackets ? "parenthesis" : "terms") with the same base by subtracting their exponents"
        
        // move exponent
        let origFraction = denNode.baseNode.parentFraction ?? numNode.baseNode.parentFraction!
        largerBase.power.append(contentsOf: smallerBase.power.withOp(.minus))
        var newOneSK = [StepKey]()
        smallerBase.baseNodeIfOneSingleTerm.removeInFraction(isTerm: smallerBase.isTerm, markedKeys: &newOneSK)
        steps.lastStepSubsteps.lastMarked.append(contentsOf: newOneSK)
        
        // append step
        steps.lastStepSubsteps.lastMarked.append(largerBase.power.last!.op)
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        // Substract
        var toEvalNodeBase = largerBase
        if let tmpEvalNodeBase = origFraction.level!.termMix.first(where: {$0.valueSK.first! == largerBase.valueSK.first!}) {
            toEvalNodeBase = tmpEvalNodeBase
        }
        if toEvalNodeBase.power.isSimplestForm {
            willHaveNotPosSingle = true
        }
        for node in toEvalNodeBase.power {
            evaluateAddition(node: node, fnCtrl: fnCtrl + [.force, .forcePowerAddition], &steps.lastStepSubsteps)
        }
        
        // Remove Power 1
        if toEvalNodeBase.isPoweredByOne {
            removeHighOpOne(node: toEvalNodeBase, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // Append Main step
        if toEvalNodeBase.isPowered && toEvalNodeBase.power.first!.valueSK.contains(where: {smallerBase.power.valuesSK.contains($0)}) {
            toEvalNodeBase.power.first!.changeIDs()
        }
        steps.lastMarked.append(contentsOf: toEvalNodeBase.power.flatSKs + newOneSK)
        appendStep(&steps, fnCtrl: fnCtrl + (willHaveNotPosSingle ? [.forceFlatSubsteps] : []))
        
        // remove times one
        if denNode.parent!.hasParent {
            removeHighOpOne(node: denNode.parent!.parent!, fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        if let powerParent = toEvalNodeBase.powerParent {
            surfAndEvaluateAndApplyFnTillEnd(parent: powerParent, fnCtrl: fnCtrl + [.skipPow], &steps)
            removePowerOne(node: toEvalNodeBase, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}
