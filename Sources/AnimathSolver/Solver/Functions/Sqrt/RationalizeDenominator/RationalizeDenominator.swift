//
//  RationalizeDenominator.swift
//  Hulul
//
//  Created by Ahmad on 14/07/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func rationalizeDenominator(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        rationalizeSingleDenominator(node: node, fnCtrl: fnCtrl, &steps)
        rationalizeMultiDenominator(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func rationalizeDenominatorAllowed(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if fnCtrl.contains(.skipRationalizeDen) {return false}
        let nodeClone = node.clone(changeID: false, withParent: true)
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        tmpSteps[0].dynamicNodeR = nodeClone.otherSide.root
        tmpSteps[0].nodeR = nodeClone.otherSide.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        rationalizeSingleDenominator(node: nodeClone, fnCtrl: [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeClone.pinnedRootDidChange

    }
}
