//
//  PoweredRoot.swift
//  Hulul
//
//  Created by Ahmad on 17/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func evaluateNthRootToTheNthPower(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
       
        // Conditions
        if radicalParent.isPoweredByWholeNumber && Int(radicalParent.powerValue) == radicalParent.indexSK.getInt {} else {return}
        if !fnCtrl.isForced && radicalParent.children.isSingleRootablePowered(indexValue: radicalParent.indexValue) {return}
        if radicalParent.indexIsEven && !radicalParent.children.hasVarOrNotVarXFlat && radicalParent.children.resultValue() < 0 {return}
        
        //
        steps.lastMarked = radicalParent.opIndex + radicalParent.power.flatSKs
        steps.lastExplanation = "Apply the rule: (ⁿ√a)ⁿ = a"
        steps.lastNote = "assuming n is odd or a ≥ 0"

        //
        radicalParent.extractRadicalContent(markedKeys: &steps.lastMarked)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    func simplifyNthRootToTheMthPower(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !radicalParent.exist {return}
        if radicalParent.isPoweredByWholeNumber {} else {return}
        if radicalParent.children.isSimplestForm {} else {return}
        if radicalParent.children.hasRootable(indexValue: radicalParent.indexValue) {return}
        var firstRadicand = radicalParent.children.first!
        
        //
        for node in radicalParent.children {
            reorderTermsFromIn(node: node, fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        if radicalParent.children.shouldSetBrktIfPowered {
            radicalParent.children.setBrackets()
            firstRadicand = radicalParent.children.first!
            steps.lastMarked = firstRadicand.valueSK
        }
        
        //
        divideRootPowerByIndex(radicalParent: radicalParent, firstRadicand: firstRadicand, fnCtrl: fnCtrl, &steps)
        getPowerInsideRadical(radicalParent: radicalParent, firstRadicand: firstRadicand, fnCtrl: fnCtrl, &steps)
    }
    private func divideRootPowerByIndex(radicalParent: StepNode, firstRadicand: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let radPowInt = Int(radicalParent.powerValue)
        if radPowInt.isMultiple(of: radicalParent.indexInt) && radPowInt > radicalParent.indexInt {} else {return}
        
        //
        steps.lastMarked.append(contentsOf: radicalParent.valueSKpow(.any))
        steps.lastExplanation = "Apply the rule: (ⁿ√a)ᵐ = aᵐᐟⁿ"

        //
        var tmpFractionAsPower = StepNode()
        var markedKeys = [StepKey]()
        removeRadicalAndSetPow(radicalParent: radicalParent, markedKeys: &markedKeys) { newRadCoeff in
            let fractionAsPower = StepNode.newFractionNode
            fractionAsPower.numerator = radicalParent.power
            fractionAsPower.denominator = [StepNode(valueSK: radicalParent.indexSK)]
            fractionAsPower.valueSK[0].id = radicalParent.op.id
            steps.lastMarked.append(fractionAsPower.valueSK.first!)
            newRadCoeff.baseOrTermNode.power = [fractionAsPower]
            tmpFractionAsPower = fractionAsPower
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        reduceFraction(node: tmpFractionAsPower, fnCtrl: fnCtrl + [.force], &steps)
    }
    private func getPowerInsideRadical(radicalParent: StepNode, firstRadicand: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !radicalParent.exist {return}
        let radPowInt = Int(radicalParent.powerValue)
        if radPowInt.isMultiple(of: radicalParent.indexInt) || radPowInt == radicalParent.indexInt {return}

        //
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Use (ᵐ√a)ⁿ = ᵐ√aⁿ to rewrite the root"
        
        //
        firstRadicand.baseOrTermNode.power = radicalParent.power
        radicalParent.removePower()
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if radicalParent.children.isBrackets && radicalParent.children.first!.children.isOneSingleTerm {
            distributePowerIntoBrackets(node: radicalParent.children.first!, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}

extension CalcBrain {
    func getPowerOutsideRadical(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !radicalParent.exist {return}
        let firstRadicand = radicalParent.children.first!
        if radicalParent.children.count == 1 && firstRadicand.isPlus && firstRadicand.isWholeNumber(mayBePowered: true, mayBeCoeff: false) {} else {return}
        if firstRadicand.isPoweredByWholeNumber {} else {return}
        let radicandPowInt = Int(firstRadicand.powerValue)
        if radicandPowInt < radicalParent.indexInt {} else {return}
        if firstRadicand.isRootable(indexValue: radicalParent.indexValue) {} else {return}

        //
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Use ᵐ√aⁿ = (ᵐ√a)ⁿ to rewrite the root"
        
        //
        radicalParent.power = firstRadicand.power
        firstRadicand.removePower()
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
