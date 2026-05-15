//
//  ExpressionEngine.swift
//  Hulul
//
//  Created by Ahmad on 07/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func EquationEngine(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        repeat {
            nodeL.pinRootExpr()
            flipsSignsIfNegX(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
            swapSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        } while nodeL.pinnedRootDidChange
        divideBothSidesByGCD(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.divBothForHighDegOrNoBrkt], &steps)
        multiplyBothSidesCases(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        multBothSidesToGetRidOfDecimals(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        swapSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        divideBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        powerBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        rootBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        factorOutX(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        reorderVarTerms(parentNode: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        flipsSignsIfNegX(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        solveNonLinearEq(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        if steps.hasSplittedSteps {return}
    }
}
