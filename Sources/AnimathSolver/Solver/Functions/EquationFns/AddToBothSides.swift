//
//  AddToBothSides.swift
//  Hulul
//
//  Created by Ahmad on 23/05/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {

    private enum SymbToMove {
        case radXIfOne, radX, x, const, all
    }
    
    func addToBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if powBothRadicalsAllowed(nodeL: nodeL, nodeR: nodeR, dynamicSwap: false, fnCtrl: fnCtrl) {return}
        addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, symbToMove: .radXIfOne, &steps)
        addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, symbToMove: .all, &steps)
        addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, symbToMove: .radX, &steps)
        addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, symbToMove: .x, &steps)
        addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, symbToMove: .const, &steps)
    }

    private func addToBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], symbToMove: SymbToMove, _ steps: inout [StepModel]) {
        
        // Conditions
        if nodeL.forceStop {return}
        guard fnCtrl.isForced || symbToMove == .const && nodeL.children.hasBrackets(.powered) || nodeL.children.isSimplestFormNegletTimesBracket && nodeR.children.isSimplestFormNegletTimesBracket else {return} // Second condition because of: (𝒙+1)^[2]−1=0
        var allNodes: [StepNode] {nodeL.children + nodeR.children}
        if !allNodes.hasVarFlat {return}
        let hasRadX = allNodes.hasDirectRadVar
        var leftToRight = symbToMove == .const || symbToMove == .all && hasRadX
        if symbToMove == .const && fnCtrl.isForced {}
        else if hasRadX && symbToMove == .all {
            if nodeL.children.hasDirectRadVar {} else {return}
        } else if nodeL.children.isSimplestFormForMoveToSides && nodeR.children.isSimplestFormForMoveToSides {
            if !nodeL.children.hasVarFlat && nodeR.children.count > 1 && nodeR.children.contains(where: {$0.isFraction && $0.denominator.hasVarFlat && !$0.numerator.hasVarFlat}) && nodeR.children.contains(where: {$0.isConst}) {
                if symbToMove == .x {return} else {leftToRight = false}
            }
        } else if !(symbToMove == .radXIfOne && hasRadX) {
            if nodeL.children.isSimplestFormWithFractionTimesBracket && nodeR.children.isSimplestFormForMoveToSides && !nodeR.children.hasVarFlat && symbToMove == .const {} else
            if nodeR.children.isSimplestFormWithFractionTimesBracket && nodeL.children.isSimplestFormForMoveToSides && !nodeL.children.hasVarFlat && symbToMove == .const {leftToRight = false} else {return}
        }
        
        if leftToRight {
            if !nodeL.children.contains(where: {!$0.isMultiplied}) {return}
        } else {
            if !nodeR.children.contains(where: {!$0.isMultiplied}) {return}
        }
        let sourceNode = leftToRight ? nodeL : nodeR
        let receiveNode = leftToRight ? nodeR : nodeL
        let nodesToMove = getNodesToMove(nodeL: nodeL, nodeR: nodeR, symbToMove: symbToMove, leftToRight: leftToRight)
        if nodesToMove.isEmpty || nodesToMove.hasNestedFraction || nodesToMove.hasDirectRadical({$0.children.hasFraction(flat: true)}) {return}
        
        // Mark and explain
        steps.lastMarked = nodesToMove.flatSKs(.any)
        if receiveNode.children.isZero {
            steps.lastMarked.append(receiveNode.children.first!.valueSK.first!)
        }
        explainAddToBothSides(nodesToMove: nodesToMove, symbToMove: symbToMove, hasRadX: hasRadX, steps: &steps)
        
        // append opposite const on both sides
        let oppNodesL = nodesToMove.cloneWithChangedStaticIDs
        let oppNodesR = nodesToMove.clone(changeID: true, withParent: false).children
        oppNodesL.flipSigns()
        oppNodesR.flipSigns()
        sourceNode.children.append(contentsOf: oppNodesL)
        var idxToMove = receiveNode.children.idxToMove(nodesToMove: nodesToMove)+1
        receiveNode.children.insert(contentsOf: oppNodesR, at: idxToMove)
        
        // Mark and append
        steps.lastStepSubsteps.lastMarked = oppNodesL.flatSKs(.any) + oppNodesR.flatSKs(.any)
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        // Evaluate LHS
        repeat {
            sourceNode.pinRootExpr()
            surfAndApplyFn(mainNode: leftToRight ? nodeL : nodeR, otherNode: nil, fnCtrl: fnCtrl + [.forceCancelOppositeTerms], surfFnCases: .cancelOppositeTermsSameSide, &steps.lastStepSubsteps)
        } while sourceNode.pinnedRootDidChange
        surfAndApplyFn(mainNode: nodeR, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: .removeZero, &steps.lastStepSubsteps)

        // Change oppNode IDs to match original node
        if nodesToMove.count > 1 {
            receiveNode.children.removeLast(nodesToMove.count)
            idxToMove = receiveNode.children.count
        } else {
            idxToMove = receiveNode.children.firstIndex(where: {$0.id == oppNodesR.first!.id})!
            receiveNode.children.remove(at: idxToMove)
        }
        let rhsConstsNodes = nodesToMove.clone(changeID: false, withParent: false).children
        rhsConstsNodes.flipSigns()
        receiveNode.children.insert(contentsOf: rhsConstsNodes, at: idxToMove)
        
        // nextMark and append
        steps.lastMarked.append(contentsOf: rhsConstsNodes.getOps)
        if sourceNode.children.isZero {
            steps.lastMarked.append(sourceNode.children.first!.valueSK.first!)
        }
        appendStep(&steps, fnCtrl: fnCtrl)
        
        if symbToMove == .x {
            addToBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl + [.force], symbToMove: .const, &steps)
        }
    }
}

extension CalcBrain {
    private func getNodesToMove(nodeL: StepNode, nodeR: StepNode, symbToMove: SymbToMove, leftToRight: Bool) -> [StepNode] {
        var allNodes: [StepNode] {nodeL.children + nodeR.children}
        let sourceNode = leftToRight ? nodeL : nodeR
        let firstRadX = sourceNode.children.first(where: {$0.hasDirectRadical && $0.radicalParent!.children.hasVarFlat}) ?? .commaNode
        switch symbToMove {
        case .radXIfOne:
            if allNodes.directRadicals.filter({$0.children.hasVarFlat}).count == 1 && sourceNode.children.hasDirectRadVar {} else {return []}
            return [sourceNode.children.first(where: {$0.hasDirectRadical && $0.radicalParent!.children.hasVarFlat})!.clone(changeID: false, withParent: false)]
        case .radX: // Example: 8√2[𝒙]=3√2[3]+3√2[𝒙]
            if !(allNodes.allSymbs.shouldMoveAllToSide || !allNodes.allRadicals.hasVarFlat) && sourceNode.children.contains(where: {$0.hasDirectRadical && $0.hasVarFlat && !$0.isMultiplied}) {} else {return []}
            guard let radXNode = sourceNode.children.first(where: {!$0.isMultiplied && $0.hasDirectRadical && $0.radicalParent!.children.hasVarFlat}) else {return []}
            let receiveNode = leftToRight ? nodeR : nodeL
            guard receiveNode.children.contains(where: {!$0.isMultiplied && $0.hasDirectRadical && $0.radicalParent!.isEqualTo(node: radXNode.radicalParent!)}) else {return []}
            return [radXNode]
        case .x:
            if !(allNodes.allSymbs.shouldMoveAllToSide || allNodes.allRadicals.hasVarFlat) && sourceNode.children.contains(where: {$0.hasVarFlat && !$0.isMultiplied}) {} else {return []}
            return [sourceNode.children.first(where: {$0.hasVarFlat && !$0.isMultiplied})!.clone(changeID: false, withParent: false)]
        case .const:
            if !(allNodes.allSymbs.shouldMoveAllToSide || allNodes.hasDirectRadVar) && sourceNode.children.contains(where: {$0.isConst && !$0.isMultiplied}) {} else {return []}
            return sourceNode.children.filter({$0.isConst && !$0.isMultiplied}).clone(changeID: false, withParent: false).children
        case .all:
            if allNodes.allSymbs.shouldMoveAllToSide && !nodeR.children.isZero(opCase: .plus) && !nodeL.children.isZero(opCase: .plus) || allNodes.hasDirectRadVar {} else {return []}
            return sourceNode.children.dropNode(node: firstRadX).dropHighOpChains.clone(changeID: false, withParent: false).children
        }
    }
    
    private func explainAddToBothSides(nodesToMove: [StepNode], symbToMove: SymbToMove, hasRadX: Bool, steps: inout [StepModel]) {
        var leftToRight: Bool {symbToMove == .const || symbToMove == .all && hasRadX}
        let sideStr = leftToRight ? "right" : "left"
        let isMulti = nodesToMove.isMulti
        let nodesStr = nodesToMove.flatSKs.dropFirstIfPlus.strForExpl
        
        let pronounStr = isMulti ? "their" : "its"
        let signStr = isMulti ? "signs" : "sign"
        steps.lastExplanation = "Move \(nodesStr) to the \(sideStr)-hand side and change \(pronounStr) \(signStr)"
        steps.lastNote = "by adding the opposite of \(nodesStr) to both sides"
        
        // Init Substeps
        steps.lastStep.shouldShowMainStep = true
        steps.lastStepSubsteps = [steps.last!]
        
        // Mark and explain
        steps.lastStepSubsteps.lastExplanation = "Add the opposite of \(nodesStr) to both sides"
        steps.lastStepSubsteps.lastNote.removeAll()
    }
}
