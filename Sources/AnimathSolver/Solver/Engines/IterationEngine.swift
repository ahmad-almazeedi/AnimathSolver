//
//  IterationEngine.swift
//  Hulul
//
//  Created by Ahmad on 19/05/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func iterationEngine(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if steps.hasSplittedSteps {return}
        repeat {
            nodeL.pinRootExpr()
            nodeR.pinRootExpr()
            surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .removeZero, &steps)
            surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .cancelOppositeTermsSameSide, &steps)
            surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .cancelEqualTermsBothSides, &steps)
            surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .removeHighOpOne, &steps)
            surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .determineSignOfPoweredBrackets, &steps)
            surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .convertNegativeExponent, &steps)
            repeat {
                nodeL.pinRootExpr()
                nodeR.pinRootExpr()
                surfAndApplyFnBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, surfFnCases: .decimalTofraction, &steps)
            } while !nodeL.forceStop && (nodeL.pinnedRootDidChange || nodeR.pinnedRootDidChange)
        } while !nodeL.forceStop && (nodeL.pinnedRootDidChange || nodeR.pinnedRootDidChange)
    }
}
