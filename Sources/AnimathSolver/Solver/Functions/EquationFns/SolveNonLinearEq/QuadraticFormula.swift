//
//  QuadraticFormula.swift
//  Hulul
//
//  Created by Ahmad on 07/01/2023.
//  Copyright © 2023 Ahmad. All rights reserved.
//

extension CalcBrain {
    func solveByQuadraticFormula(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fnCtrl.contains(.skipRootSidesOrSolveNonLinear) {return}
        if nodeL.children.isSimplestFormMulti && nodeR.children.isZero(opCase: .plus) {
            guard nodeL.children.onlyHasVar.count == 2 else {return}
            guard nodeL.children.dropHasVar.count >= 1 else {return}
        } else {return}
        if nodeL.children.hasFraction(flat: true) {return}
        guard let aNode = nodeL.children.first, aNode.hasVar else {return}
        let bNode = nodeL.children[1]
        if bNode.hasVar {} else {return}
        let cNodes = nodeL.children.dropHasVar
        guard aNode.directVar!.powerKeys(equalTo: [.two]) && !bNode.directVar!.isPowered && !cNodes.isEmpty && !cNodes.hasVarFlat else {return}
        
        //
        let cNode = cNodes.count > 1 ? cNodes.clonesInBrackets : cNodes.first!
        
        //
        steps.lastStep.setTitle(title: "Solving: \(nodeL.flatSKs(dropEqual: false).strForExpl)", subtitle: "Using the Quadratic Formula")
        
        //
        showOneVars(nodes: nodeL.children, fnCtrl: fnCtrl, &steps)

        //
        steps.lastMarked = nodeL.children.map({$0.dropVarAndRadVar(dropNotVarX: false).flatSKs(.dropPlus)}).flatMap({$0})
        steps.lastExplanation = "Identify the coefficients a, b and c of the quadratic equation:"
        let coeffsStr = "a = \(aNode.dropVarAndRadVar(dropNotVarX: false).flatSKs(.dropPlus).strForExpl),  b = \(bNode.dropVarAndRadVar(dropNotVarX: false).flatSKs(.dropPlus).strForExpl),  c = \(cNode.dropVarAndRadVar(dropNotVarX: false).flatSKs(.dropPlus).strForExpl.dropOuterBrackets(flag: true))"
        steps.lastNote = coeffsStr
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        var newFraction = StepNode()
        subtituteInQuadraticFormulaAndEval(nodeL: nodeL, nodeR: nodeR, aNode: aNode, bNode: bNode, cNode: cNode, coeffsStr: coeffsStr, newFraction: &newFraction, fnCtrl: fnCtrl, &steps)
        
        //
        if steps.last!.nodeR.hasIFlat && steps.hasEvenRadVar {
            steps.setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
            return
        }
        
        //
        if newFraction.hasI {
            seperateFractionToRealAndI(fractionNode: newFraction, fnCtrl: fnCtrl, &steps)
        } else {
            setEvenRootOfNegativeToUndefined(nodeL: newFraction.root, nodeR: newFraction.otherSide, fnCtrl: fnCtrl, &steps)
            if steps.last!.nodeL.isUndefined {return}
        }
        
        //
        seperateIntoTwoPlusAndMinusEquations(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.skipMergeFraction], &steps)
        
        //
        steps.lastStep.multiSubSteps.removeAll(where: {!$0.isEmpty && $0.last!.isTitleStep})
    }
}

extension CalcBrain {
    func showOneVars(nodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if nodes.contains(where: {$0.isOneSingleVar(mayBeInSqrt: false)}) {} else {return}
        
        //
        steps.lastExplanation = "If a term doesn't have a coefficient it is considered that the coefficient is 1"
       
        //
        for node in nodes {
            if node.isOneSingleVar(mayBeInSqrt: false) {
                node.showOneTerm = true
            }
        }
        
        //
        steps.lastMarked = nodes.filter({$0.isOneTerm}).valuesSK.compactMap({$0})
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    private func subtituteInQuadraticFormulaAndEval(nodeL: StepNode, nodeR: StepNode, aNode: StepNode, bNode: StepNode, cNode: StepNode, coeffsStr: String, newFraction: inout StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
      
        //
        steps.lastMarked = nodeL.allNodes.flatSKs + [nodeR.valueSK.first!]
        let quadraticFormulaStr = "\(bNode.directVar!.type!.title) = (-b ± √(b² - 4ac)) / 2a"
        steps.lastExplanation = "Subtitute \(coeffsStr) into the quadratic formula:"
        steps.lastNote = "\(quadraticFormulaStr)"

        //
        nodeL.children = [.newOneNodeWithVar(type: aNode.directVar!.type!)]
             
        // -b
        let minusB = bNode.isMinus ? StepNode.newBracketsNode.withOp(.minus).withChildren(children: [StepNode(op: bNode.op, valueSK: bNode.valueSK)]) : StepNode(op: .minus, valueSK: bNode.valueSK)
        minusB.selfOrChild.directSymbs = bNode.dropVarAndRadVar(dropNotVarX: false).directSymbs.cloneWithChangedStaticIDs
        minusB.selfOrChild.radicalParent = bNode.radicalParent?.cloneWithChangedStaticIDs

        // ±√(b²-4ac)
        let bSquared = bNode.isMinus || bNode.hasConstSymbOrRad ? StepNode.newBracketsNode.withChildren(children: [StepNode(op: bNode.op.newSK, valueSK: bNode.valueSK.newSKs)]) : bNode.valueSK.newSKs.newNode
        bSquared.selfOrChild.directSymbs = bNode.dropVarAndRadVar(dropNotVarX: false).directSymbs.cloneWithChangedStaticIDs
        bSquared.selfOrChild.radicalParent = bNode.radicalParent?.cloneWithChangedStaticIDs
        bSquared.power = [StepNode(valueKeys: [.two])]
        steps.lastStep.appendCloneIDs(originalKeysIDs: bNode.dropVarAndRadVar(dropNotVarX: false).flatSKs(.dropPlus).ids, clonesKeysIDs: [bSquared.selfOrChild.flatSKs(.dropPlus).ids])
        let a1 = StepNode.newBracketsNode.withOp(.times).withChildren(children: [StepNode(op: aNode.op, valueSK: aNode.valueSK)])
        a1.children.first!.directSymbs = aNode.dropVarAndRadVar(dropNotVarX: false).directSymbs.cloneWithChangedStaticIDs
        a1.children.first!.radicalParent = aNode.radicalParent?.cloneWithChangedStaticIDs
        let c = cNode.isBrackets ? cNode.withOp(.times) : StepNode.newBracketsNode.withOp(.times).withChildren(children: [StepNode(op: cNode.op, valueSK: cNode.valueSK)])
        if !cNode.isBrackets {
            c.children.first!.directSymbs = cNode.dropVarAndRadVar(dropNotVarX: false).directSymbs.cloneWithChangedStaticIDs
            c.children.first!.radicalParent = cNode.radicalParent?.cloneWithChangedStaticIDs
        }
        let plusMinusSqrt = StepNode.newOneNodeWithSqrt(indexSK: [.two])
        plusMinusSqrt.op = .plusMinus
        plusMinusSqrt.radicalParent!.children = [bSquared, 4.newNode.withOp(.minus), a1, c]
        
        //
        let a2 = StepNode.newBracketsNode.withOp(.times).withChildren(children: [StepNode(op: aNode.op.newSK, valueSK: aNode.valueSK.newSKs)])
        a2.children.first!.directSymbs = aNode.dropVarAndRadVar(dropNotVarX: false).directSymbs.cloneWithChangedStaticIDs
        a2.children.first!.radicalParent = aNode.radicalParent?.cloneWithChangedStaticIDs
        steps.lastStep.appendCloneIDs(originalKeysIDs: a1.children.first!.flatSKs(.dropPlus).ids, clonesKeysIDs: [a2.children.first!.flatSKs(.dropPlus).ids])
        
        //
        newFraction = StepNode.newFractionNode
        newFraction.numerator = [minusB, plusMinusSqrt]
        newFraction.denominator = [2.newNode, a2]
        
        //
        nodeR.children = [newFraction]
        
        //
        steps.lastMarked.append(contentsOf: newFraction.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl + [.skipSetNegRootToUndef])

        //
        steps.appendMergeIDs(originalKeysIDs: [aNode.directVar!.type!.id], mergesKeysIDs: [[bNode.directVar!.type!.id]])

        //
        removeNegativeBrackets(node: minusB, fnCtrl: fnCtrl + [.force, .skipSetNegRootToUndef], &steps)
        determineSignOfPoweredBrackets(node: bSquared, fnCtrl: fnCtrl + [.force, .skipSetNegRootToUndef], &steps)
        evaluatePow(node: bSquared, fnCtrl: fnCtrl + [.force, .skipSetNegRootToUndef], &steps)
        surfAndEvaluateAndApplyFnTillEnd(parent: nodeR, fnCtrl: fnCtrl + [.skipSetNegRootToUndef, .skipEqualityCheck], &steps)
        
        //
        if let radicalParent = plusMinusSqrt.radicalParent {
            extractIFromSqrt(radicalParent: radicalParent, fnCtrl: fnCtrl + [.skipSetNegRootToUndef], &steps)
            surfAndEvaluateAndApplyFnTillEnd(parent: nodeR, fnCtrl: fnCtrl + [.skipSetNegRootToUndef], &steps)
        }
    }
}
