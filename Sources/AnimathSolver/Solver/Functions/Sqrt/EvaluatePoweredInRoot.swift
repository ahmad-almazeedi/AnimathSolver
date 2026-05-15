//
//  PoweredInRoot.swift
//  Hulul
//
//  Created by Ahmad on 17/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func evaluateNthPowerInNthRoot(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if radicalParent.exist {} else {return}
        guard radicalParent.children.isSingleNode && (fnCtrl.contains(.forceEvaluateNthPowerInNthRoot) || !radicalParent.children.isBrackets(.notSimplest) || radicalParent.children.isBrackets({$0.isMultChain && $0.hasOnlyBrackets(.any)})) else {return}
        let firstRadicand = radicalParent.children.first!
        if firstRadicand.isMinus && radicalParent.indexIsEven {return}
        if firstRadicand.baseOrTermNode.isPoweredByWholeNumber {} else {return}
        if firstRadicand.baseOrTermNode.powerValue == radicalParent.indexSK.getDouble {} else {return}
        var radCoeff: StepNode {radicalParent.coeffNode}
        
        //
        if !fnCtrl.contains(.forceRadVarEval) && radicalParent.indexIsEven && radicalParent.hasVarFlat && radicalParent.isEquation {
            steps.setToUnableToSolve(nodeL: radicalParent.root, nodeR: radicalParent.otherSide)
            return
        }
        
        //
        if let innerRadicalParent = firstRadicand.radicalParent, firstRadicand.isOneRadical {
            radicalParent.pinRootExpr()
            evaluateNthPowerInNthRoot(radicalParent: innerRadicalParent, fnCtrl: fnCtrl, &steps)
            if radicalParent.pinnedRootDidChange {return}
        }

        //
        extractMinusFromRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)

        //
        steps.lastMarked = radicalParent.opIndex + (firstRadicand.isBrackets ? firstRadicand.baseOrTermNode.valueSKpow : firstRadicand.baseOrTermNode.power.flatSKs)
        steps.lastExplanation = "Apply the rule: ⁿ√aⁿ = a"
        steps.lastNote = "assuming n is odd or a ≥ 0"
        
        //
        removeRadicalAndSetPow(radicalParent: radicalParent, markedKeys: &steps.lastMarked) { newRadCoeff in
            newRadCoeff.baseOrTermNode.powerParent = radicalParent.powerParent
        }
             
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func evaluateMultipleOfNthPowerInNthRoot(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if radicalParent.exist {} else {return}
        let firstRadicand = radicalParent.children.first!
        if radicalParent.children.isSingleNode {} else {return}
        if firstRadicand.isMinus && radicalParent.indexIsEven {return}
        if firstRadicand.baseOrTermNode.isPoweredByWholeNumber {} else {return}
        let firstRadPowInt = Int(firstRadicand.baseOrTermNode.powerValue)
        if firstRadPowInt > radicalParent.indexInt {} else {return}
        if firstRadPowInt.isMultiple(of: radicalParent.indexInt) {} else {return}
        var radCoeff: StepNode {radicalParent.coeffNode}

        //
        extractMinusFromRoot(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        
        //
        steps.lastMarked = radicalParent.opIndex + radicalParent.children.flatSKs
        steps.lastExplanation = radToExpExplanation
        
        //
        var tmpFractionAsPower = StepNode()
        var markedKeys = [StepKey]()
        removeRadicalAndSetPow(radicalParent: radicalParent, markedKeys: &markedKeys) { newRadCoeff in
            let fractionAsPower = StepNode.newFractionNode
            fractionAsPower.numerator = firstRadicand.baseOrTermNode.power
            fractionAsPower.denominator = [StepNode(valueSK: radicalParent.indexSK)]
            fractionAsPower.valueSK[0].id = radicalParent.op.id
            steps.lastMarked.append(fractionAsPower.valueSK.first!)
            newRadCoeff.baseOrTermNode.power = [fractionAsPower]
            let radPowParent = radicalParent.powerParent
            if let radPowParent = radPowParent {
                newRadCoeff.setBrackets()
                newRadCoeff.parent!.powerParent = radPowParent
                newRadCoeff.parent!.op = newRadCoeff.op
                newRadCoeff.op = .plus
                steps.lastMarked.append(contentsOf: newRadCoeff.parent!.valueSK)
            }
            tmpFractionAsPower = fractionAsPower
        }
        
        //
        steps.lastMarked.append(contentsOf: markedKeys)

        //
        appendStep(&steps, fnCtrl: fnCtrl)
        reduceFraction(node: tmpFractionAsPower, fnCtrl: fnCtrl + [.force], &steps)
    }
}
