//
//  RationalizeMultiDenominator.swift
//  Hulul
//
//  Created by Ahmad on 14/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func rationalizeMultiDenominator(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.exist || fnCtrl.contains(.skipRationalizeDen) {return}
        if node.isFraction(.simplest(for: .all)) && node.denominator.count == 2 {} else {return}
        if node.isMultipliedOrDivided || node.isInFraction || node.numerator.isFraction {return}
        if node.denominator.directRadicals.contains(where: {$0.indexIsTwo}) && !node.denominator.directRadicals.contains(where: {!$0.indexIsTwo}) {} else {return}
        if node.isReducibleFraction {return}
        if willMultBothSides(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl + [.skipRationalizeDen]) {return}
        if fnCtrl.isCheckAllowed {node.changeContent(); return}
        
        //
        node.pinRootExpr()
        extractMinusFromNumOrDen(node: node, fnCtrl: fnCtrl + [.force], &steps)
        if node.pinnedRootDidChange {return}
        
        //
        if node.denominator.isMinus && node.denominator.hasPlusAndMinus {
            swapTwoChildren(bracketsNode: node.children.last!, fnCtrl: fnCtrl, &steps)
        }
        
        //
        let originalDenominator = node.denominator.clone(changeID: false, withParent: false).children
        steps.lastMarked = node.denominator.flatSKs
        steps.lastExplanation = "Rationalize the denominator"
        steps.lastStep.shouldShowMainStep = true

        //
        steps.lastStepSubsteps = [steps.last!]
        
        //
        let newFraction = StepNode.newFractionNode.withOp(.times)
        newFraction.numerator = node.denominator.conjugate
        newFraction.denominator = node.denominator.conjugate
        
        //
        steps.lastStepSubsteps.lastMarked = newFraction.flatSKs
        steps.lastStepSubsteps.lastExplanation = "Multiply the fraction by\n\(newFraction.flatSKs(.dropOp).strForExpl.withPaddedFractions)"

        //
        node.insertAfter(newFraction)
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        mergeWithFraction(node: node, fnCtrl: fnCtrl + [.force, .forceMerge], &steps.lastStepSubsteps)
        var conjugateInNum = node.numerator.first(where: {$0.hasStaticIDsOverlap(staticIDs: newFraction.numerator.first!.staticIDs)})!
        if !conjugateInNum.isBrackets {
            conjugateInNum = conjugateInNum.parent!
        }
        steps.lastMarked.append(contentsOf: conjugateInNum.flatSKs)

        //
        evaluateBrktsTimesConjugate(node: node.denominator.first!, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps.lastStepSubsteps)
        surfAndEvaluateAndApplyFnTillEnd(parent: node.children.last!, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps.lastStepSubsteps)
        
        //
        steps.lastStep.appendCloneIDs(originalKeysIDs: originalDenominator.dropSqrtOpValue.flatSKs.ids, clonesKeysIDs: [conjugateInNum.children.dropSqrtOpValue.flatSKs.ids])
        if node.denominator.count > 1 {
            for i in 0..<conjugateInNum.children.count {
                let conjNumNode = conjugateInNum.children[i]
                let toReplaceSKs = originalDenominator[i].valueSK.filter({origDenSK in !node.denominator[i].valueSK.contains(origDenSK)})
                conjNumNode.replaceOpValueSKWithSimilarKeys(toReplaceSKs)
                steps.lastCloneIDs.removeAll(where: {toReplaceSKs.ids.contains($0.originalKeyID)})
                if let radicalParent = conjNumNode.radicalParent {
                    let toReplaceSKs = originalDenominator[i].radicalParent!.children.flatSKs.filter({origDenSK in !node.denominator[i].flatSKs.contains(origDenSK)})
                    radicalParent.op = originalDenominator[i].radicalParent!.op
                    radicalParent.children.replaceSimilarKeys(with: toReplaceSKs, withPow: true)
                    steps.lastCloneIDs.removeAll(where: {toReplaceSKs.ids.contains($0.originalKeyID)})
                }
                for symbNode in conjNumNode.directSymbs {
                    let toReplaceSKs = originalDenominator[i].directSymbs.flatSKs.filter({origDenSK in !node.denominator[i].flatSKs.contains(origDenSK)})
                    symbNode.replaceSimilarKeys(with: toReplaceSKs, withPow: true)
                    steps.lastCloneIDs.removeAll(where: {toReplaceSKs.ids.contains($0.originalKeyID)})
                }
            }
        } else {
            for i in 0..<conjugateInNum.children.count {
                let conjNumNode = conjugateInNum.children[i]
                let toReplaceSKs = originalDenominator[i].flatSKs.filter({origDenSK in !node.denominator.flatSKs.contains(origDenSK)}).dropOps
                conjNumNode.replaceSimilarKeys(with: toReplaceSKs, withPow: true)
                steps.lastCloneIDs.removeAll(where: {toReplaceSKs.ids.contains($0.originalKeyID)})
            }
        }
        
        //
        node.denominator.last!.op.id = originalDenominator.last!.op.id
        steps.lastMarked.append(contentsOf: node.denominator.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
