//  CalcBrain.swift
//  Hulul
//
//  Created by Ahmad on 20/12/2020.
//  Copyright © 2020 Ahmad. All rights reserved.
//


extension CalcBrain {
    func solveForX(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl] = [], shouldCheckEquality: Bool) -> [StepModel] {
        
        //
        if nodeL.allNodes.flatKeys.contains(where: {$0.isCustom}) {return []}

        
        // First Engine No Steps
        firstEngineNoSteps(nodeL: nodeL, nodeR: nodeR)
        if nodeL.isEmpty || nodeL.isIncomplete || nodeL.resultCase == .unableToSolve {return []}
                
        // Steps Init
        var steps = [StepModel()]
        stepsInit(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, steps: &steps)
        if nodeL.resultCase == .undefined {return steps}
                
        // Solve
        simplifyAndMoveToSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)

        // Compare Equality
        if shouldCheckEquality {
            checkEquality(nodeL: nodeL, nodeR: nodeR, steps: &steps)
        }
        
        // set result case if no main variable
        if [nodeL.resultCase, nodeR.resultCase].contains(.unableToSolve) || nodeL.resultCase == .none && steps.mixedWithSubsteps.contains(where: {$0.nodeL.resultCase == .unableToSolve}) || nodeL.shouldBeUnableToSolve || steps.map({$0.splittedSteps ?? []}).filter({!$0.isEmpty}).flatMap({$0}).map({$0.last!}).contains(where: {$0.nodeL.resultCase == .unableToSolve}) {
            steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
        }
        
        // Return
        return steps
    }
}

extension CalcBrain {
    func replaceXWithNotVarXIfApplicable(nodeL: StepNode) {
        //
        guard nodeL.isEquationWithYNoZ else {return}
        //
        for node in nodeL.allNodes.allVarsFlat {
            if node.isSymbType(type: .x) {
                if let valueKeyXIdx = node.valueSK.firstIndex(where: {$0.key == .x}) {
                    node.valueSK[valueKeyXIdx].key = .notVarX
                }
            }
        }
    }
}

extension CalcBrain {
    private func simplifyAndMoveToSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        let allowCommonFactorEnd = !nodeL.children.isHighOpChain
        nodeL.pinRootExpr()
        highCostSolve(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        if !nodeL.children.isSimplestForm || nodeL.isEquation && !nodeR.children.isSimplestForm || nodeL.allNodes.hasFraction(part: .denominator, {$0.count > 1}) {
            surfAndEvaluateAndApplyFnAndSolveEqTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.force], &steps)
        }
        let pinnedRootDidChange = nodeL.pinnedRootDidChange
        if allowCommonFactorEnd && !pinnedRootDidChange {
            convertToCommonFactorOrAddFractions(nodes: nodeL.children, &steps)
        } else if !pinnedRootDidChange && !nodeL.isEquation && nodeL.children.isOneSingleRadical {
            let radicalParent = nodeL.children.first!.radicalParent!
            if radicalParent.children.isSingleNode && radicalParent.children.first!.baseOrTermNode.isVar {
                radicalToExponent(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            }
        } else {
            reorderVarTerms(parentNode: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        }
    }
}

extension CalcBrain {
    func highCostSolve(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if nodeL.isEquation {
            determineTheDefinedRange(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        } else if nodeL.children.isSingle(mayBeFraction: false, mayBePowered: false) {
            if !nodeL.children.first!.isCoeff && nodeL.children.first!.isDecimal {
                convertDecimalToFraction(node: nodeL.children.first!, fnCtrl: [.force, .forceConvertDecimalToFraction], &steps)
                return
            }
        }
        surfAndEvaluateAndApplyFnAndSolveEqTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
    func surfAndEvaluateAndApplyFnAndSolveEqTillEnd(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        repeat {
            nodeL.pinRootExpr()
            nodeR.pinRootExpr()
            surfAndEvaluateAndApplyFnTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
            if !nodeL.forceStop && !nodeR.isEmpty {
                EquationEngine(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl.filter({$0 != .force}), &steps)
                iterationEngine(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
            }
        } while !nodeL.forceStop && (nodeL.pinnedRootDidChange || nodeR.pinnedRootDidChange)
        setEvenRootOfNegativeToUndefined(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
}
