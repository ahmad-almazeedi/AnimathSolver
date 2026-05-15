//
//  ConvertNegSqrtToI.swift
//  Hulul
//
//  Created by Ahmad on 04/01/2023.
//  Copyright © 2023 Ahmad. All rights reserved.
//

extension CalcBrain {
    func extractIFromSqrt(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !fnCtrl.contains(.skipExtractI) && fnCtrl.contains(.skipSetNegRootToUndef) {} else {return}
        
        //
        convertSqrtOfNegOneToI(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
        
        //
        if !radicalParent.exist {return}
        if radicalParent.indexIsTwo && radicalParent.children.isMinus {} else {return}
        if radicalParent.children.isMultChain {} else {return}
        let firstRadicand = radicalParent.children.first!
        if firstRadicand.isFraction && firstRadicand.children.hasMinusFlatNoPow {return}
        
        //
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Rewrite √-\(radicalParent.children.flatSKs(.dropOp).strForExpl) as √\(radicalParent.children.flatSKs(.dropOp).strForExpl)×i"

        //
        steps.lastStepSubsteps = [steps.last!]

        //
        let minusOp = radicalParent.children.op
        radicalParent.children.op = .plus
        let brktWithNegOne = StepNode.newBracketsNode.withOp(.times).withChildren(children: [.newOneNode.withOp(minusOp)])
        radicalParent.children.append(brktWithNegOne)

        //
        steps.lastStepSubsteps.lastExplanation = "Rewrite the number as a product with the factor -1"
        steps.lastStepSubsteps.lastMarked = radicalParent.children.firstNodes(2).flatSKs
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        splitRadOfNegOneTimesNumberAndConvertToI(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        steps.lastMarked.append(radicalParent.root.allSymbs.first(where: {$0.type?.key == .imaginary})!.valueSK.first!)
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    private func splitRadOfNegOneTimesNumberAndConvertToI(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if radicalParent.isSqrt && !radicalParent.exist {return}
        if radicalParent.indexIsTwo && radicalParent.children.count > 1 && radicalParent.children.isMultChain {} else {return}
        let lastChild = radicalParent.children.last!
        if lastChild.isBrackets && lastChild.children.isOne(opCase: .minus) {} else {return}
        
        //
        splitRadicalContent(rootableNodes: [radicalParent.children.last!], fnCtrl: fnCtrl + [.splitRadicalFromEnd], &steps)
        
        //
        convertSqrtOfNegOneToI(radicalParent: lastChild.parent!, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    private func convertSqrtOfNegOneToI(radicalParent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !radicalParent.exist {return}
        if radicalParent.indexIsTwo && radicalParent.children.isOne(opCase: .minus) {} else {return}
        var radCoeff: StepNode {radicalParent.coeffNode}
        
        //
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Rewrite √-1 as i"
        
        //
        radicalParent.remove()
        
        //
        let iNode = StepNode.newSymbNode(type: .i)
        radCoeff.directSymbs.append(iNode)
        
        //
        steps.lastMarked.append(iNode.valueSK.first!)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
