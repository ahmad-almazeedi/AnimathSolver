//
//  MultSameBase.swift
//  Hulul
//
//  Created by Ahmad on 26/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func multSameBase(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        let timesDefaultChain = fnCtrl.isForced || node.parent!.isSqrt ? node.multChain(forward: true) : node.timesDefaultChainWithPow
        let multChainMix = timesDefaultChain.symbMixCoeffsFirst
        if multChainMix.hasPoweredByNotSimplestForm {return}
        var hasOnlySymbs = true
        var symbChanged = false
        guard multChainMix.allSatisfy({$0.illegibleForHasEqualBase}) else {return}
        for mainNode in multChainMix {
            guard mainNode.exist else {continue}
            guard mainNode.isNumber(mayBePowered: true) else {continue}
            if mainNode.isSymb && fnCtrl.contains(.skipSymbMultOrOrder) {continue}
            if mainNode.isSymb && hasOnlySymbs && timesDefaultChain.dropNode(node: mainNode.baseNode).contains(where: {!$0.isOneTerm}) {return}
            guard mainNode.hasDuplicateAndNotPoweredByFraction(In: multChainMix) else {continue}
            let sameBasesNotFltrd = multChainMix.filter({$0.hasEqualBase(with: mainNode)})
            guard mainNode.isSymb || sameBasesNotFltrd.hasPowered else {continue}
            let sameBasesPoweredByFraction = sameBasesNotFltrd.filter({$0.power.hasFraction(flat: true)})
            if sameBasesPoweredByFraction.count > 1 && sameBasesPoweredByFraction.first!.idx! < mainNode.idx! {continue}
            let sameBases = sameBasesNotFltrd.filter({!$0.power.hasFraction(flat: true)})
            guard sameBases.count > 1 else {continue}
            if sameBases.allPowers.contains(where: {!$0.isSimplestForm}) {return}
            
            //
            if mainNode.isSymb {
                symbChanged = false
            } else {
                hasOnlySymbs = false
            }
            
            // Compute Power first
            if mainNode.isSymb && mainNode.coeffNode.isPowered {
                evaluatePow(node: node, fnCtrl: fnCtrl, &steps)
            }
            
            // set symb
            let sameBasesNotPowered = sameBases.filter({!$0.isPowered})
            
            //
            steps.lastMarked = sameBases.opValuesSKpows.dropFirstIfOp + sameBases.dropFirst.baseNodes.filter({$0.isOneTerm}).getOps.dropPluses
            steps.lastExplanation = calcProdExpl
            
            // Mark and explain
            steps.lastStepSubsteps = [steps.last!]
            steps.lastStepSubsteps.lastMarked = sameBasesNotPowered.opValuesSKpows.dropOps
            steps.lastStepSubsteps.lastExplanation = setExponentToOneExplanation
            
            // Set power to one
            if !sameBasesNotPowered.isEmpty {
                for tmpSymb in sameBasesNotPowered {
                    tmpSymb.power = [.newOneNode]
                }
                
                // Nextmark and append step
                steps.lastStepSubsteps.lastMarked.append(contentsOf: sameBasesNotPowered.opValuesSKpows.dropOps)
                appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
            }
            
            // Mark and explain
            steps.lastStepSubsteps.lastMarked = sameBases.opValuesSKpows.dropFirstIfOp + sameBases.baseNodes.filter({$0.isOneTerm}).getOps.filter({$0.key == .times})
            steps.lastStepSubsteps.lastExplanation = multTermsWithSameBaseExpl
            
            // make all the powers in the first symbol
            let symbsPower = sameBases.map({$0.power}).flatMap({$0})
            mainNode.power = symbsPower
            
            // Remove the other symbols
            if mainNode.isSymb {
                let coeffs = sameBases.dropFirst.parents.dropRedundantNodes()
                sameBases.dropFirst.removeNodesFromParent()
                coeffs.onlyOnes.removeNodesFromParent()
            } else {
                sameBases.dropFirst.extractTermsFromEachCoeff()
                sameBases.dropFirst.removeNodesFromParent()
            }
            
            // mark and append step
            steps.lastStepSubsteps.lastMarked.append(contentsOf: mainNode.power.flatSKs)
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
            
            //
            steps.lastStepSubsteps.appendMergeIDs(originalKeysIDs: mainNode.valueSK.ids, mergesKeysIDs: sameBases.dropFirst.map({$0.valueSK.ids}))
            
            // Evaluate Addition
            surfAndEvaluateTillEnd(parent: mainNode.powerParent!, fnCtrl: fnCtrl + [.force, .forcePowerAddition, .skipFlattenning], &steps.lastStepSubsteps)
            
            //
            removePowerOne(node: mainNode, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
            
            //
            steps.lastMarked.append(contentsOf: mainNode.power.flatSKs)
            appendStep(&steps, fnCtrl: fnCtrl)
            
            //
            steps.appendMergeIDs(originalKeysIDs: mainNode.valueSK.ids, mergesKeysIDs: sameBases.dropFirst.map({$0.valueSK.ids}))
        }
        
        // remove times and reorderTermsFromIn
        if symbChanged {
            for coeffNode in timesDefaultChain {
                reorderTermsFromIn(node: coeffNode, fnCtrl: fnCtrl, &steps)
            }
        }
    }
}

extension CalcBrain {
    func willMultSameBase(node: StepNode) -> Bool {
        guard node.exist else {return false}
        var tempSteps = [StepModel()]
        let nodeClone = node.clone(changeID: false, withParent: true)
        nodeClone.pinRootExpr()
        multSameBase(node: nodeClone, fnCtrl: [.skipPrintStep], &tempSteps)
        return nodeClone.pinnedRootDidChange
    }
}
