//
//  DistributeRadicalOnFraction.swift
//  Hulul
//
//  Created by Ahmad on 21/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func distributeRadicalsOnFractions(rootableNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if rootableNodes.isEmpty {return}
        let radicalParent = rootableNodes.first!.baseNode.parent!
        if radicalParent.isPowered {return}
        if radicalParent.children.isMultiNotHighOpChain {return}
        let fractionRadicands = rootableNodes.onlyFractions
        if fractionRadicands.isEmpty {return}
        if fractionRadicands.contains(where: {$0.isMinus || $0.numeratorAndDenominator.negtaiveCount > 1}) {return}
        
        //
        for fractionRadicand in fractionRadicands {
            distributeRadicalOnFraction(radicalParent: radicalParent, fractionRadicand: fractionRadicand, fnCtrl: fnCtrl, &steps)
        }
    }
    private func distributeRadicalOnFraction(radicalParent: StepNode, fractionRadicand: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !radicalParent.exist {return}
        if rationalizeDenominatorAllowed(node: fractionRadicand, fnCtrl: fnCtrl) {return}
        if !fractionRadicand.children.hasPoweredFlat && willBeReducible(node: fractionRadicand, fnCtrl: fnCtrl) {return}
        
        //
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "To take a root of a fraction, take the root of the numerator and denominator separately"
        
        //
        var radCoeff: StepNode {radicalParent.coeffNode}
        radicalParent.splitAtRadical(markedKeys: &steps.lastMarked)
        
        // remove radical
        let newFraction = radCoeff
        let originalOp = newFraction.op
        newFraction.removeRadical()
        newFraction.content = fractionRadicand.content
        newFraction.op = originalOp

        // distribute the radical
        let numRadicalCoeff = StepNode.newOneNodeWithSqrt(indexSK: radicalParent.indexSK)
        numRadicalCoeff.radicalParent!.op = radicalParent.op
        let denRadicalCoeff = StepNode.newOneNodeWithSqrt(indexSK: radicalParent.indexSK.newSKs)
        numRadicalCoeff.radicalParent!.children = newFraction.numerator
        denRadicalCoeff.radicalParent!.children = newFraction.denominator
        newFraction.numerator = [numRadicalCoeff]
        newFraction.denominator = [denRadicalCoeff]
        
        //
        steps.lastMarked.append(contentsOf: denRadicalCoeff.radicalParent!.opIndex)
        
        //
        steps.lastStep.appendCloneIDs(originalKeysIDs: [radicalParent.op.id], clonesKeysIDs: [[denRadicalCoeff.radicalParent!.op.id]])
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        removeRadicalOneOrZero(node: newFraction.numerator.first!, fnCtrl: fnCtrl, &steps)
        
        //
        let numMultChain = numRadicalCoeff.multChain(forward: false)
        let denMultChain = denRadicalCoeff.multChain(forward: false)
        numMultChain.setSurfedToFalse(keepTargets: fnCtrl.isKeepTargets)
        denMultChain.setSurfedToFalse(keepTargets: fnCtrl.isKeepTargets)
        simplifyAndEvaluateRadicals(node: numRadicalCoeff,  fnCtrl: fnCtrl, &steps)
        simplifyAndEvaluateRadicals(node: denRadicalCoeff,  fnCtrl: fnCtrl, &steps)
    }
}
