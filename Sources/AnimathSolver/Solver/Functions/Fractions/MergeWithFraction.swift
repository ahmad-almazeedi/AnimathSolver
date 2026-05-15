//
//  MergeWithFraction.swift
//  Hulul
//
//  Created by Ahmad on 18/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    
    func mergeWithFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        // Conditions
        if !node.exist {return}
        let isForceMerge = fnCtrl.contains(.forceMerge)
        if node.isSurfed && !fnCtrl.isForced || fnCtrl.contains(.skipMergeFraction) {return}
        var multChain = node.multChain(forward: false).dropNonTargets(fnCtrl: fnCtrl)
        if fnCtrl.contains(.skipMergeI) && multChain.contains(where: {$0.isOneSingleSymb && $0.directSymbs.first!.isSymbType(type: .imaginary)}) {return}
        if multChain.count > 1 {} else {return}
        if !multChain.isFirst(node: node) || !isForceMerge && !node.isPlusOrMinus {return}
        if !isForceMerge && (node.isInDividedMultChain || multChain.hasNotTermNorBrktPoweredFlat || multChain.hasRadicalNotSimplestFlat || multChain.flatTree.contains(where: {$0.isPowered && !$0.power.isSimplestForm})) {return}
        if multChain.hasFraction(.any) {} else {return}
        if multChain.hasFraction(.notOnlyTimes(andNotSimplestNotSingle: true)) {return} // revise
        if !isForceMerge && (multChain.hasFraction(.hasFraction) || multChain.hasBrackets(.hasFraction(fractionCase: .any)) || multChain.contains(where: {$0.hasDirectRadical && $0.radicalParent!.children.hasFraction(flat: true)}) || multChain.hasFraction(.toMergeRadicals)) {return}
        if multChain.hasNegativeDropFirst {return}
        let chainNodes = multChain.chain1stLevelFlatNodes
        if chainNodes.hasBrackets(.notSimplest) || chainNodes.hasBrackets(.singleNegGeneral) {return}
        if !isForceMerge && (isReducible(node: multChain.first!, fnCtrl: []) || multBothSidesAllowed(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl)) {return}
        
        // Set multchain to no brackets if appropriate
        if !fnCtrl.contains(.forceMergeWithBrkt) && !(node.isEquation && node.otherSide.children.isFraction && multChain.count == 2 && node.level!.count == 2 || multChain.hasFraction(.hasBrackets(.notSingle(mayBeFraction: true), for: .any)) || multChain.hasFraction(.simplestNotSingle(for: .any)) || multChain.onlyFractions.count == 1 && (multChain.onlyBrackets.count > 1 || multChain.onlyFractions.first!.denominator.hasVar) && multChain.dropBrackets.dropFractions.isEmpty) {
            multChain = node.multChainNoBrackets(forward: false, .notSingle(mayBeFraction: true)).dropNonTargets(fnCtrl: fnCtrl)
            if multChain.count == 1 {return}
        } else if multChain.hasBrackets(.hasFraction(fractionCase: .any)) {return}
        else if node.isEquation && multChain.onlyFractions.count == 1 && multChain.hasFraction(.single(simplest: false, for: .all)) && multChain.hasBrackets(.notSingle(mayBeFraction: true)) && multChain.dropBrackets.dropFractions.isEmpty {
            if willMultBothSides(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl + [.skipDistribute, .skipMergeFraction]) {return}
        }
        let firstOpIsTimes = multChain.op.key.isTimes
        
        //
        if let radicalParent = node.parent, radicalParent.isSqrt {
            node.pinRootExpr()
            mergeSameBaseInSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        if multChain.onlyFractions.count == 1 && multChain.dropFractions.hasOnlyBrackets(.any) {
            node.pinRootExpr()
            rationalizeDenominator(node: multChain.first(where: {$0.isFraction})!, fnCtrl: fnCtrl + [.force, .forceRationalizeDen], &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        steps.lastMarked = multChain.flatSKs(.dropOp)
        let isMultiFraction = multChain.filter({$0.isFraction}).count > 1
        let isMoreThan2 =  multChain.count > 2
        let numberStr = isMoreThan2 ? "numbers" : "number"
        let hasOnlyWholeNumbers = multChain.filter({!$0.isFraction}).hasOnlyWholeNumbers
        steps.lastExplanation = isMultiFraction ? "To multiply fractions, multiply the numerators together and the denominators together"
        : hasOnlyWholeNumbers ? "To multiply a fraction by \(isMoreThan2 ? "" : "a ")whole \(numberStr), multiply the numerator by the whole \(numberStr)"
        : "Express the multiplication as a single fraction."
       
        steps.lastNote = isMultiFraction && multChain.hasNonFraction ? "Note that any whole number can be represented as a fraction by setting the denominator to 1" : ""
        
        // set numerator chain
        var numeratorChain = multChain.numeratorChain
        var denominatorChain = multChain.denominatorChain
        let OriginalNumeratorChain = numeratorChain.clone(changeID: false, withParent: false).children
        
        // set brackets if appropriate
        for i in 0..<numeratorChain.count {
            if numeratorChain[i].parent!.isFraction {} else {continue}
            let newBrktNode = StepNode.newBracketsNode
            newBrktNode.children = numeratorChain[i].children
            numeratorChain[i].children = [newBrktNode]
            numeratorChain[i] = newBrktNode
        }
        for i in 0..<denominatorChain.count {
            if denominatorChain[i].parent!.isFraction {} else {continue}
            let newBrktNode = StepNode.newBracketsNode
            newBrktNode.children = denominatorChain[i].children
            denominatorChain[i].children = [newBrktNode]
            denominatorChain[i] = newBrktNode
        }
        
        // set denominator chain
        let firstNumIdx = node.level!.dropNonTargets(fnCtrl: fnCtrl).contains(numeratorChain.first!) ? numeratorChain.first!.idx : numeratorChain.first!.parentFraction!.idx
        let allFractions = multChain.filter({$0.isFraction})
        let targetedFraction = allFractions[allFractions.count%2==0 ? allFractions.count/2-1 : allFractions.count/2]
        let fractionNode = targetedFraction.clone(changeID: false, withParent: false)
        
        //
        let firstInNumerator = numeratorChain.first(where: {$0.isInFraction && !$0.isTimes})!
        fractionNode.numerator = numeratorChain.clone(changeID: false, withParent: false).children
        fractionNode.denominator = denominatorChain.clone(changeID: false, withParent: false).children
        
        //
        var originalKeys = [Int32]()
        var cloneKeys = [Int32]()
        for node in fractionNode.numerator.dropFirst+fractionNode.denominator.dropFirst {
            if !node.isTimes {
                if fractionNode.numerator.contains(node) {
                    let origClone = numeratorChain.first(where: {$0.valueSK == node.valueSK})!
                    if origClone.isInFraction && origClone.isFirst {
                        node.op = origClone.parentFraction!.op
                    } else if origClone.parent!.isFraction {
                        node.op = origClone.parent!.op
                    }
                    if node.staticID != firstInNumerator.staticID {
                        originalKeys.append(node.op.id)
                    }
                } else {
                    node.op = .times
                    steps.lastMarked.append(node.op)
                    if node.isOneTerm || node.isBrackets({$0.isSimplestFormMulti}) {} else {
                        cloneKeys.append(node.op.id)
                    }
                }
            }
        }
        
        //
        var numeratorHiddenTimeses = fractionNode.numerator.filter({($0.isOneRadical || $0.isOneSymb && !$0.prev.isBrackets || !fnCtrl.contains(.skipRemoveOneTimesBrkt) && $0.valueIsOne) && originalKeys.contains($0.op.id)})
        for node in fractionNode.denominator.dropFirst {
            if node.isTimes && cloneKeys.contains(node.op.id) && !numeratorHiddenTimeses.isEmpty {
                cloneKeys.removeAll(where: {$0 == node.op.id})
                originalKeys.removeAll(where: {$0 == numeratorHiddenTimeses.first!.op.id})
                node.op = numeratorHiddenTimeses.first!.op
                numeratorHiddenTimeses.first!.op.changeID()
                numeratorHiddenTimeses.removeFirst()
            }
        }
        steps.lastStep.appendCloneIDs(originalKeysIDs: originalKeys, clonesKeysIDs: [cloneKeys])
        
        //
        if fractionNode.isTimes && !firstOpIsTimes {
            fractionNode.op = numeratorChain.op
            if fractionNode.numerator.first!.isMinus {
                fractionNode.numerator.first!.op = .plus
            }
        } else if fractionNode.isTimes && firstOpIsTimes && !numeratorChain.first!.isInFraction {
            fractionNode.op = numeratorChain.op
            fractionNode.numerator.first!.op = .plus
        }
        
        //
        var firstOp = fractionNode.op
        if targetedFraction.idx != firstNumIdx {
            let firstInPrevMultChain = multChain.first!
            targetedFraction.remove()
            firstInPrevMultChain.insertBefore(targetedFraction)
            firstOp = firstInPrevMultChain.op
        }
        
        //
        multChain.filter({$0.id != targetedFraction.id}).removeNodesFromParent()
        targetedFraction.content = fractionNode.content
        targetedFraction.op = firstOp
        steps.lastMarked.append(contentsOf: fractionNode.flatSKs(.dropOp))
        
        // remove times one from numerator
        if targetedFraction.numerator.count > 1 && targetedFraction.numerator.first!.isOne && targetedFraction.numerator[1].isBracketsNotHidden {
            steps.lastStepSubsteps = [steps.last!]
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipPrintStep])
            removeOneTimesBracket(node: targetedFraction.numerator.first!, fnCtrl: fnCtrl.drop(.skipRemoveOneTimesBrkt) + [.force, .skipPrintStep], &steps.lastStepSubsteps)
            removeOneTimes(node: targetedFraction.numerator.first!, fnCtrl: fnCtrl.drop(.skipRemoveOneTimesBrkt) + [.force, .skipPrintStep], &steps.lastStepSubsteps)
            steps.lastStepSubsteps.removeAll()
        }
        if !fnCtrl.contains(.skipRemoveOneTimesBrkt) {
            steps.lastStepSubsteps = [steps.last!]
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipPrintStep])
            surfAndApplyFn(mainNode: targetedFraction.children.first!, otherNode: nil, fnCtrl: fnCtrl + [.skipPrintStep], surfFnCases: .removeHighOpOne, &steps.lastStepSubsteps)
            removePositiveBrackets(node: targetedFraction.numerator.first!, fnCtrl: fnCtrl + [.force, .skipPrintStep], &steps.lastStepSubsteps)
            steps.lastStepSubsteps.removeAll()
        } else if OriginalNumeratorChain.count == 2 {
            steps.lastStepSubsteps = [steps.last!]
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipPrintStep])
            targetedFraction.numerator.first!.showOneTerm = false
            steps.lastStepSubsteps.removeAll()
        }
        
        // multiply if isOneTerm
        if OriginalNumeratorChain.count == 2 {
            if targetedFraction.numerator.first!.isOne && targetedFraction.numerator.last!.isBrackets {
                steps.lastStepSubsteps = [steps.last!]
                appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
                removeOneTimesBracket(node: targetedFraction.numerator.first!, fnCtrl: fnCtrl.drop(.skipRemoveOneTimesBrkt), &steps.lastStepSubsteps)
            }
        }
        
        //
        node.nodeProduct = targetedFraction
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        for node in targetedFraction.numeratorAndDenominator {
            removeTimesOne(node: node, fnCtrl: fnCtrl + [.force], &steps)
            removeOneTerm(node: node, fnCtrl: fnCtrl + [.force], &steps)
            reorderTermsFromOut(node: node, fnCtrl: fnCtrl + [.force], &steps)
        }
      
        //
        if targetedFraction.numerator.count == 1 {
            reorderTermsFromIn(node: targetedFraction.numerator.first!, fnCtrl: fnCtrl, &steps)
        }
    }
}
