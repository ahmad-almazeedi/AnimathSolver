//
//  SimplifyMultipleRadicands.swift
//  Hulul
//
//  Created by Ahmad on 06/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func simplifyMultipleRadicands(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !radicalParent.exist || fnCtrl.contains(.skipRadicalSimplifying) || fnCtrl.contains(.skipRadicalEval) {return}
        if radicalParent.children.isBrackets || radicalParent.children.isSingleNode {return}
        guard radicalParent.children.isMultChain else {return}
        if radicalParent.children.onlyNumbers.contains(where: {!$0.symbsAreInSimplestForm}) || radicalParent.children.onlyNumbers.hasRepeatedSymbType {return}
        if radicalParent.isSimplestRadicalMayBePowered {return}
        if radicalParent.children.dropFractions.hasRootableOrSimplifiable(indexValue: radicalParent.indexValue, isNotRootableIfMultiplied: true) {} else {return}
        if radicalParent.indexIsEven && radicalParent.children.isMinus || radicalParent.children.dropFirst.hasMinusFlatNoPow {return}
        if radicalParent.children.hasFraction(.notSimplestReduced) {return}
        if radicalParent.coeffNode.next.isDivide && radicalParent.coeffNode.next.isOneSingleRadical {return}
        
        //
        let originalRadicalOp = radicalParent.op
        let originalIndexSK = radicalParent.indexSK
        
        //
        simplifyExponentiablePoweredRadicand(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        mergeSameBaseInSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)

        //
        radicalParent.pinRootExpr()
        reduceIndexWithPower(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        if radicalParent.pinnedRootDidChange {return}
                
        //
        steps.lastMarked = radicalParent.opIndex + radicalParent.children.flatSKs
        steps.lastStepSubsteps = [steps.last!]
        
        //
        if radicalParent.isPowered {
            radicalParent.coeffNode.splitTermsAt(radicalParent)
            radicalParent.coeffNode.setBracketsAndExtractPower()
            steps.lastMarked.append(contentsOf: radicalParent.coeffNode.parent!.opValueSK(.onlyTimes))
        }
        
        //
        let originalRadicalContent = radicalParent.children.clone(changeID: false, withParent: false).children
        
        //
        extractMinusFromRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        if steps.lastStepSubsteps.count == 2 {
            steps.lastMarked.append(contentsOf: steps.lastStepSubsteps.beforeLastStep.markedKeys)
        }
                
        //
        radicalParent.pinRootExpr()
        expandSimplifiableRadicands(radicalParent: radicalParent, fnCtrl: fnCtrl + [.keepTargets], &steps.lastStepSubsteps)
        let didntExpand = !radicalParent.pinnedRootDidChange
        let newRadicalContent = radicalParent.children.termMix
        
        //
        let mayReorder = radicalParent.children.count == 1
        let rootableNodes = radicalParent.rootableNodes(indexValue: radicalParent.indexValue)
        splitRadicalContent(rootableNodes: rootableNodes, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        for rootableNode in rootableNodes {
            let radicalParent = rootableNode.baseNode.parent!
            if radicalParent.children.count == 1 {} else {continue}
            evaluateNthPowerInNthRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            evaluateMultipleOfNthPowerInNthRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            evaluateRoot(radicalParent: radicalParent, fnCtrl: fnCtrl + (didntExpand && rootableNodes.count == 1 ? [] : [.skipFlattenning]), &steps.lastStepSubsteps)
        }
        
        // Multiply results
        let nodesProducts = rootableNodes.baseNodes.nodesProducts
        let remainingRadicals = newRadicalContent.filter({$0.baseNode.parent!.isSqrt && $0.baseNode.parent!.exist}).map({$0.baseNode.parent!}).dropDuplicates

        // reorder
        if remainingRadicals.count == 1 && mayReorder {
            reorderTermsFromIn(node: remainingRadicals.first!.coeffNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        //
        if let newCoeff = remainingRadicals.first?.coeffNode {
            newCoeff.radicalParent!.indexSK = originalIndexSK
            let flatSKsNoPow = originalRadicalContent.flatSKsNoPow
            let exceptSKs = remainingRadicals.flatSKs+nodesProducts.dropNode(node: newCoeff).flatSKs+flatSKsNoPow.filter({$0.key.isOp})
            newCoeff.replaceSimilarKeys(with: flatSKsNoPow.dropSKs(exceptSKs).dropOps, exceptSKs: exceptSKs, withPow: false)
            if remainingRadicals.first!.children.count == 1 && originalRadicalContent.count == 1 { // The second condition is for this: √9[2^[9]×7^[6]]
                for node in remainingRadicals.first!.children.symbMix {
                    if node.isPowered {
                        let originalRadicandPowerSKs = originalRadicalContent.symbMix.first(where: {node.isSymb && $0.isSymb && node.type?.key == $0.type?.key || !node.isTerm && !$0.isTerm})!.power.first!.valueSK
                        node.power.first!.valueSK[0].id = originalRadicandPowerSKs.first!.id
                        node.power.first!.valueSK.replaceSimilarKeys(similarKeys: originalRadicandPowerSKs)
                    }
                }
            }
            if let node = nodesProducts.first(where: {node in !node.valueIsOne && node.staticID == originalRadicalContent.first!.staticID && node.hasEqualBase(with: originalRadicalContent.first!) && node.hasEqualBase(with: remainingRadicals.first!.children.first!)}) {
                steps.lastStep.appendCloneIDs(originalKeysIDs: node.valueSK.ids, clonesKeysIDs: [remainingRadicals.first!.children.first!.valueSK.ids])
            }
            for symbNode in nodesProducts.directSymbs {
                if let originalSymbNode = remainingRadicals.first!.children.first!.directSymbs.first(where: {$0.type?.key == symbNode.type?.key}), originalRadicalContent.allSymbs.contains(where: {$0.isPowered && $0.staticID == symbNode.staticID}) {
                    steps.lastStep.appendCloneIDs(originalKeysIDs: symbNode.valueSK.ids, clonesKeysIDs: [originalSymbNode.valueSK.ids])
                }
            }
        }
        
        //
        remainingRadicals.first?.op = originalRadicalOp
        if remainingRadicals.count > 1 {
            steps.lastStep.appendCloneIDs(originalKeysIDs: [originalRadicalOp.id], clonesKeysIDs: remainingRadicals.dropFirst.getOps.map({[$0.id]}))
        }
        let sqrtOrRootStr = radicalParent.indexInt == 2 ? "square root" : "root"
        steps.lastMarked.append(contentsOf: nodesProducts.flatSKs(.onlyTimes) + remainingRadicals.flatSKs)
        steps.lastExplanation = !remainingRadicals.isEmpty ? "Simplify the radical expression" : "Evaluate the \(sqrtOrRootStr)"
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        for radical in remainingRadicals {
            simplifyMultipleRadicands(radicalParent: radical, fnCtrl: fnCtrl, &steps)
            reduceIndexWithPower(radicalParent: radical, fnCtrl: fnCtrl, &steps)
            surfAndEvaluateTillEnd(parent: radical, fnCtrl: fnCtrl, &steps)
        }
    }
}
