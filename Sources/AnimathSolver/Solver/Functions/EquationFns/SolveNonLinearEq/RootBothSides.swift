//
//  RootBothSides.swift
//  Hulul
//
//  Created by Ahmad on 16/12/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func rootBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if nodeR.isEmpty || fnCtrl.contains(.skipRootSidesOrSolveNonLinear) {return}
        if !fnCtrl.contains(.skipRootBothSidesCheck) && rootBothSidesAllowed(nodeL: nodeR, nodeR: nodeL, fnCtrl: fnCtrl + [.skipRootBothSidesCheck]) {
            swapSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.force], &steps)
        }
        
        //
        if nodeL.hasVarFlat && !nodeR.hasVarFlat {} else {return}
        if nodeR.hasIFlat {return}
        let rhsIsZero = nodeR.children.isZero
        if nodeL.children.isPlus && (nodeL.children.isBrackets(.simplest) || nodeL.children.isBrackets && rhsIsZero || nodeL.children.isOneSingleVar(mayBeInSqrt: false) && nodeL.children.isSimplestForm) {} else {return}
        if nodeR.children.isSimplestForm || nodeR.children.isSingleNode && nodeR.children.first!.baseOrTermNode.isPoweredByPosWholeNumber {} else {return}
        if nodeL.children.first!.baseOrTermNode.isPoweredByPosWholeNumber {} else {return}
        let lhsPoweredNode = nodeL.children.first!.baseOrTermNode
        if !(lhsPoweredNode.powerKeys(equalTo: [.two]) || rhsIsZero) || nodeL.allNodes.contains(where: {!$0.power.isSimplestForm}) {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        //
        let powValue = lhsPoweredNode.power.resultValue()
        let rootStr = powValue == 2 ? "square root" : powValue == 3 ? "cubic root" : "root"
        steps.lastExplanation = "Take the \(rootStr) of both sides of the equation"
        if !rhsIsZero && powValue.isEven {
            steps.lastNote = "Remember to introduce ± when taking the even root of both sides"
        }
        
        //
        if nodeR.children.isPlus && nodeR.children.isSingleNode && nodeR.children.first!.baseOrTermNode.isPowered && nodeR.children.first!.baseOrTermNode.power.resultValue() == powValue {
            rootBothPoweredSides(nodeL: nodeL, nodeR: nodeR, lhsPoweredNode: lhsPoweredNode, powValue: powValue, rootStr: rootStr, fnCtrl: fnCtrl, &steps)
        } else {
            movePowToSideAsRoot(nodeL: nodeL, nodeR: nodeR, lhsPoweredNode: lhsPoweredNode, powValue: powValue, rootStr: rootStr, fnCtrl: fnCtrl, &steps)
            if nodeL.resultCase == .unableToSolve {return}
        }
        
        //
        if rhsIsZero {
            addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        }
        
        //
        seperateIntoTwoPlusAndMinusEquations(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    }
    
    func rootBothPoweredSides(nodeL: StepNode, nodeR: StepNode, lhsPoweredNode: StepNode, powValue: Double, rootStr: String, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        //
        let rhsPoweredNode = nodeR.children.first!.baseOrTermNode
        steps.lastMarked = lhsPoweredNode.power.flatSKs + (lhsPoweredNode.isBrackets ? lhsPoweredNode.valueSK : []) + rhsPoweredNode.power.flatSKs + (rhsPoweredNode.isBrackets ? rhsPoweredNode.valueSK : [])
        
        //
        nodeR.pinRootExpr()
        removeZeroPowered(node: rhsPoweredNode, fnCtrl: fnCtrl, &steps)
        if nodeR.pinnedRootDidChange {return}
        
        //
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        //
        steps.lastStepSubsteps.lastExplanation = "Take the \(rootStr) of both sides of the equation"

        //
        nodeL.children.setInRoot(ofIndex: powValue)
        nodeR.children.setInRoot(ofIndex: powValue)
        
        //
        if powValue.isEven {
            nodeR.children.first!.op = .plusMinus
        }
        
        //
        steps.lastStepSubsteps.lastMarked = nodeL.children.first!.radicalParent!.opValueSK + nodeR.children.first!.radicalParent!.opValueSK + [nodeR.children.first!.op]
        steps.lastMarked.append(nodeR.children.first!.op)

        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        evaluateNthPowerInNthRoot(radicalParent: nodeL.children.first!.radicalParent!, fnCtrl: fnCtrl + [.force, .forceRadVarEval], &steps.lastStepSubsteps)
        evaluateNthPowerInNthRoot(radicalParent: nodeR.children.first!.radicalParent!, fnCtrl: fnCtrl + [.force, .forceRadVarEval], &steps.lastStepSubsteps)

        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func movePowToSideAsRoot(nodeL: StepNode, nodeR: StepNode, lhsPoweredNode: StepNode, powValue: Double, rootStr: String, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        //
        steps.lastMarked = lhsPoweredNode.power.flatSKs + (lhsPoweredNode.isBrackets ? lhsPoweredNode.valueSK : [])
        
        //
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        //
        steps.lastStepSubsteps.lastExplanation = "Take the \(rootStr) of both sides of the equation"

        //
        let lhsPowSK = lhsPoweredNode.power.first!.valueSK
        let rhsIsZero = nodeR.children.isZero
        nodeL.children.setInRoot(ofIndex: powValue)
        nodeR.children.setInRoot(ofIndex: powValue)
        
        //
        let rhsCoeffNode = nodeR.children.first!
        guard rhsCoeffNode.op.key.isPlus else {
            steps.setToUnableToSolve(nodeL: nodeL.root, nodeR: nodeR.otherSide)
            return
        }
        if !rhsIsZero && powValue.isEven {
            rhsCoeffNode.op = .plusMinus
        }
        
        //
        steps.lastStepSubsteps.lastMarked = nodeL.children.first!.radicalParent!.opValueSK + rhsCoeffNode.radicalParent!.opValueSK + [rhsCoeffNode.op]
        steps.lastMarked.append(contentsOf: [rhsCoeffNode.radicalParent!.op, rhsCoeffNode.op])

        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipSetNegRootToUndef])
        
        //
        evaluateNthPowerInNthRoot(radicalParent: nodeL.children.first!.radicalParent!, fnCtrl: fnCtrl + [.force, .forceRadVarEval, .skipSetNegRootToUndef], &steps.lastStepSubsteps)
        if rhsIsZero {
            removeRadicalOneOrZero(node: nodeR.children.first!, fnCtrl: fnCtrl + [.skipSetNegRootToUndef], &steps.lastStepSubsteps)
        } else {
            if rhsCoeffNode.radicalParent!.indexValue != powValue {
                steps.setToUnableToSolve(nodeL: nodeL.root, nodeR: nodeR.otherSide)
                return
            }
            rhsCoeffNode.radicalParent!.indexSK = lhsPowSK
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipSetNegRootToUndef])
        
        //
        if let radicalParent = nodeR.children.first!.radicalParent, !radicalParent.children.hasVarOrNotVarXFlat {
            if radicalParent.children.resultValue() < 0 {
                var nodes = radicalParent.children
                extractMinusFromExpr(nodes: &nodes, fnCtrl: fnCtrl + [.skipSetNegRootToUndef, .forceExtractMinus], &steps)
                radicalParent.children = nodes.parent!.id == radicalParent.id ? nodes : [nodes.parent!]
            }
            extractIFromSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl + [.skipSetNegRootToUndef], &steps)
            if radicalParent.exist && radicalParent.children.resultValue() < 0 {
                steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
                return
            }
        }
        
        //
        surfAndEvaluateAndApplyFnTillEnd(parent: nodeR, fnCtrl: fnCtrl + [.force, .forceRationalizeDen, .skipMergeI], &steps)
        if !nodeL.children.isOneSingleVar(mayBeInSqrt: false) {
            mergeWithFraction(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force, .forceMerge], &steps)
        }
    }
}

extension CalcBrain {
    func rootBothSidesAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let nodeLClone = nodeL.clone(changeID: false, withParent: true)
        let nodeRClone = nodeR.clone(changeID: false, withParent: true)
        nodeLClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        rootBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
    func willRootBothSides(nodeL: StepNode, nodeR: StepNode, targetNode: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeL.isEmpty || nodeR.isEmpty {return false}
        let nodeLClone = nodeL.clone(changeID: false, withParent: true)
        let nodeRClone = nodeR.clone(changeID: false, withParent: true)
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeLClone.root
        tmpSteps[0].nodeL = nodeLClone.root
        tmpSteps[0].dynamicNodeR = nodeRClone.root
        tmpSteps[0].nodeR = nodeRClone.root
        if fnCtrl.contains(.targetToSkipPowOnly) {
            guard let targetNodeClone = nodeLClone.allNodes.flatTree.firstHasSameStaticID(with: targetNode) else {return false}
            targetNodeClone.isTarget = true
        }
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep, .keepTargets])
        surfAndEvaluateAndApplyFnAndSolveEqTillEnd(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .skipPow, .skipRootSidesOrSolveNonLinear], &tmpSteps)
        nodeLClone.pinRootExpr()
        rootBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeLClone.pinnedRootDidChange
    }
}
