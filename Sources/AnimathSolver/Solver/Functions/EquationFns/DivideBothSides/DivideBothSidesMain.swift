//
//  DivideBothSidesMain.swift
//  Hulul
//
//  Created by Ahmad on 25/05/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func divideBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        removeMultByDivBothSidesOneIsZero(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        divideBothSidesByGCD(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        moveCoeff(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func divideBothSidesAllowedExceptMoveCoeff(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let swapped = nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        removeMultByDivBothSidesOneIsZero(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        divideBothSidesByGCD(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func divideBothSidesAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let swapped = nodeR.isLeft
        let nodeLClone = (swapped ? nodeR : nodeL).clone(changeID: false, withParent: true)
        let nodeRClone = (swapped ? nodeL : nodeR).clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        divideBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
}
