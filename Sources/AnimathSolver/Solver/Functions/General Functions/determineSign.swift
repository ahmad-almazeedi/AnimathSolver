//
//  determineSign.swift
//  Hulul
//
//  Created by Ahmad on 04/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    
    func determineChainSign(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        extractMinusFromNumOrDen(node: node, fnCtrl: fnCtrl, &steps)
        determineChainSignForHighOpChain(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {

    func extractMinusFromNumOrDen(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.exist || fnCtrl.contains(.isInSplittedSteps) {return}
        if node.isSurfed && !fnCtrl.isForced || !steps.first!.inMainSteps {return}
        if !node.isMultipliedOrDivided && node.isFraction(.simplestReduced) {} else {return}
        if node.isAlone && !node.isChild {} else {return}
        if !node.isEquation || !node.isLeft && node.otherSide.children.isOneSingleVar(mayBeInSqrt: false) {} else {return}
        
        //
        for nodes in [node.numerator, node.denominator] {
            var tmpNodes = nodes
            extractMinusFromExpr(nodes: &tmpNodes, fnCtrl: fnCtrl, &steps)
        }
    }
    
    func extractMinusFromExpr(nodes: inout [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        guard nodes.count > 1 else {return}
        if fnCtrl.contains(.forceExtractMinus) && nodes.contains(where: {$0.isMinus}) || nodes.allSatisfy({$0.op.key == .minus}) {}
        else if nodes.first!.isMinus {
            if let parentFraction = nodes.first!.parentFraction {
                if parentFraction.isMinus {}
                else {
                    let numOrDen = (nodes.first!.isInNumerator ? parentFraction.denominator : nodes.first!.isInDenominator ? parentFraction.numerator : []).clone(changeID: false, withParent: false).children
                    if numOrDen.isEmpty {
                        steps.setToUnableToSolve(nodeL: nodes.root, nodeR: nodes.root.otherSide)
                        return
                    }
                    numOrDen.flipSigns()
                    if nodes.isEqualTo(nodes: numOrDen) {} else {return}
                }
            } else {return}
        } else if nodes.count == 2 && nodes.last!.isMinus {
            if let parentFraction = nodes.first!.parentFraction {
                let numOrDenFirst = nodes.first!.isInNumerator ? parentFraction.denominator.first! : parentFraction.numerator.first!
                let ops = [parentFraction, numOrDenFirst].getOps.keys
                if ops == [.minus, .plus] || ops == [.plus, .minus] && numOrDenFirst.isAlone {} else {return}
            } else {return}
        } else {return}
        
        //
        if let parentFraction = nodes.first!.parentFraction {
            parentFraction.pinRootExpr()
            reduceForCase(.commonFactor, node: parentFraction, fnCtrl: fnCtrl + [.force], &steps)
            if parentFraction.pinnedRootDidChange {return}
        }
        
        //
        if nodes.isPlus {
            swapTwoChildren(bracketsNode: nodes.parent!, fnCtrl: fnCtrl, &steps)
            nodes = nodes.parent!.children
        }
        
        //
        let originalOps = nodes.getOps
        
        //
        steps.lastMarked = originalOps
        steps.lastExplanation = "Factor out the negative sign from the expression"
        
        //
        nodes.flipSigns()
        
        //
        nodes.setBrackets()
        let newBrackets = nodes.first!.parent!
        
        //
        newBrackets.op = originalOps.first!
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: [newBrackets.op.id], mergesKeysIDs: [originalOps.dropFirst.ids])
    }
}

extension CalcBrain {
    func isDetermineChainSign(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let highOpChain = node.highOpChain.filter({!fnCtrl.targetOnly || $0.isTarget})
        if highOpChain.isEmpty {return false}
        if highOpChain.first!.isFirstInHighOpChain || fnCtrl.targetOnly {} else {return false}
        if highOpChain.hasFraction(.notOnlyTimes(andNotSimplestNotSingle: true)) {return false}
        let chainNodes = highOpChain.chain1stLevelFlatNodes
        if chainNodes.contains(where: {!$0.isBrackets(.singleNegGeneral) && $0.isBrackets(.notSimplest)}) || chainNodes.hasBrackets(.poweredSingleNegative) {return false}
        if highOpChain.isMinus && !chainNodes.dropNode(node: highOpChain.first!).hasNegative {return false}
        if chainNodes.filter({$0.isNegative}).isEmpty {return false}
        return true
    }
    
    private func determineChainSignForHighOpChain(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if isDetermineChainSign(node: node, fnCtrl: fnCtrl) {} else {return}
        let highOpChain = node.highOpChain.filter({!fnCtrl.targetOnly || $0.isTarget})
        let chainNodes = highOpChain.chain1stLevelFlatNodes
        
        // Actions
        cancelFirstMinusCoupleInChain(chainNodes: chainNodes, fnCtrl: fnCtrl, &steps)
        moveChainMinusToStart(highOpChain: highOpChain, chainNodes: chainNodes, fnCtrl: fnCtrl, &steps)
    }
    
    private func cancelFirstMinusCoupleInChain(chainNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        var minusCount: Int {
            chainNodes.filter({$0.isNegative}).count
        }
        while minusCount > 1  {
            
            // Drop first if appropriate
            let shouldDropFirst = minusCount > 2 && !chainNodes.first!.isBrackets(.singleNeg(mayBePowered: false))
            let modifiedChainNodes = shouldDropFirst ? chainNodes.dropFirst : chainNodes
            
            // set minus nodes
            let firstMinusNode = modifiedChainNodes.first(where: {$0.isNegative})!
            let secondMinusNode = modifiedChainNodes.first(where: {$0.id != firstMinusNode.id && $0.isNegative})!
            
            // Set mult or divide title
            let isDivide = secondMinusNode.selfOrParentFraction.isDivide || firstMinusNode.isInNumeratorOrNotInFraction && secondMinusNode.isInDenominator || firstMinusNode.isInDenominator && secondMinusNode.isInNumeratorOrNotInFraction
            
            // mark and explain and strike
            steps.lastMarked = [firstMinusNode.dynamicInnerMinus, secondMinusNode.dynamicInnerMinus]
            steps.lastExplanation = "\(isDivide ? "Dividing" : "Multiplying") two negatives equals a positive, so cancel both negative signs"
            steps.lastStrikeKeys = [firstMinusNode.dynamicInnerMinus.strikeKey, secondMinusNode.dynamicInnerMinus.strikeKey]
            
            // remove signs
            firstMinusNode.dynamicInnerMinus = .plus
            secondMinusNode.dynamicInnerMinus = .plus
            
            // mark new plus
            if !firstMinusNode.isBrackets(.single(mayBePowered: false)) {
                steps.lastMarked.append(firstMinusNode.op)
            }
            
            // append step
            appendStep(&steps, fnCtrl: fnCtrl)
        }
    }
    
    private func moveChainMinusToStart(highOpChain: [StepNode], chainNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if highOpChain.hasFraction(.any) || highOpChain.hasBrackets(.notSingle(mayBeFraction: false)) || chainNodes.contains(where: {$0.isDivide || $0.isTimes}) || fnCtrl.contains(.forceMoveMinusOut) {} else {return}
        if chainNodes.filter({$0.isNegative}).count == 1 {} else {return}
        if !chainNodes.first!.isInFraction && (chainNodes.isMinus || chainNodes.first!.isBrackets(.hasFraction(fractionCase: .any))) {return}
        if chainNodes.first!.isHighOp {
            steps.setToUnableToSolve(nodeL: chainNodes.root, nodeR: chainNodes.root.otherSide)
            return
        }
        if !fnCtrl.contains(.skipMultBothSidesBySingleCheck) && multBothSidesBySingleAllowed(nodeL: highOpChain.root, nodeR: highOpChain.first!.otherSide, fnCtrl: fnCtrl) && highOpChain.first!.isFraction && highOpChain.first!.denominator.isMinus && !highOpChain.first!.isMinus {return}
        
        // set minus nodes
        let minusNode = chainNodes.first(where: {$0.isNegative})!
        let firstNode = highOpChain.first!
        if firstNode.id == minusNode.id {return}
        
        // Actions
        if firstNode.isPlus {
            moveInnerMinusToStartForChain(firstNode: firstNode, minusNode: minusNode, fnCtrl: fnCtrl, &steps)
        } else {
            cancelInnerAndStartMinusSignsForChain(firstNode: firstNode, minusNode: minusNode, fnCtrl: fnCtrl, &steps)
        }
    }
    
    private func moveInnerMinusToStartForChain(firstNode: StepNode, minusNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !fnCtrl.contains(.forceMoveMinusOut) && firstNode.isFraction(.single(simplest: false, for: .all)) && firstNode.numerator.isMinus && !firstNode.isInMultChain && firstNode.hasCommonTerm(in: firstNode.level!.onlyFractions) && firstNode.isFirstOfCommonTerms(in: firstNode.level!.onlyFractions) {return}
        
        //
        firstNode.pinRootExpr()
        if firstNode.isFraction && minusNode.isBrackets && minusNode.children.isMinus && minusNode.isInFraction(node: firstNode) && !firstNode.isMultipliedOrDivided && !(minusNode.children.hasPlusAndMinus && minusNode.otherPartOfTheFraction.hasPlusAndMinusFlat) && !minusNode.children.isEqualTo(nodes: minusNode.otherPartOfTheFraction) {
            removeBrackets(node: minusNode, fnCtrl: fnCtrl + [.force], &steps)
        }
        if firstNode.pinnedRootDidChange {return}
        
        // Set mult or division title
        let isDivisionExpr = minusNode.selfOrParentFraction.isDivide
        
        // mark and explain
        steps.lastMarked = [firstNode.op, minusNode.dynamicInnerMinus]
        let isJustFraction = firstNode.isFraction && [firstNode.numerator.first!, firstNode.denominator.first!].containsNode(minusNode)
        steps.lastExplanation = isJustFraction ? "Move the negative sign out from the fraction" : "\(isDivisionExpr ? "Dividing" : "Multiplying") a positive and a negative equals a negative"
        
        // move sign
        firstNode.op = minusNode.dynamicInnerMinus
        minusNode.dynamicInnerMinus = .plus
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    private func cancelInnerAndStartMinusSignsForChain(firstNode: StepNode, minusNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Set mult or divide title
        let secondIsDivide = minusNode.selfOrParentFraction.isDivide || minusNode.isInDenominator

        // mark and explain
        steps.lastMarked = [firstNode.op, minusNode.dynamicInnerMinus]
        steps.lastExplanation = "\(secondIsDivide ? "Dividing" : "Multiplying") two negatives equals a positive, so cancel both negative signs"
        steps.lastStrikeKeys = [firstNode.op.strikeKey, minusNode.dynamicInnerMinus.strikeKey]
        
        // remove signs
        firstNode.op = .plus
        minusNode.dynamicInnerMinus = .plus
        
        // mark new plus
        steps.lastMarked.append(firstNode.op)
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}

extension CalcBrain {
    func determineChainSignTillEnd(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        repeat {
            node.pinRootExpr()
            surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl + [.force], surfFnCases: .determineSign, &steps)
            if !node.isRoot {
                determineChainSign(node: node, fnCtrl: fnCtrl + [.force], &steps)
            }
        } while node.pinnedRootDidChange
    }
}
