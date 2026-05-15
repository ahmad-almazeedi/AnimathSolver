//
//  DivideBothSidesActions.swift
//  Hulul
//
//  Created by Ahmad on 25/05/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func divideBothSidesByGCD(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if fnCtrl.isCheckAllowed && nodeL.children.first!.isCommaNode {return}
        if nodeL.forceStop {return}
        if nodeL.children.isSimplestFormNegletTimesBracket && nodeR.children.isSimplestFormNegletTimesBracket {} else {return}
        let allNodes = nodeL.children + nodeR.children
        if allNodes.onlyFractions.numeratorsParents.contains(where: {$0.children.isMulti}) || allNodes.hasDecimal {return}
        let allNodesDropMultBrkt = allNodes.dropMultipliedBrackets
        if fnCtrl.contains(.forceDivideBothSides) || allNodes.allSymbs.shouldMoveAllToSide && allNodes.filter({!($0.isZero && $0.isAlone)}).isSimplestFormNegletTimesBracket {}
        else if fnCtrl.contains(.divBothForHighDegOrNoBrkt) && !allNodes.hasBrackets(.any) && allNodes.numeratorsFirsts?.nodesHaveEqualValues ?? false && allNodes.hasOnlyFractions {}
        else if !fnCtrl.contains(.divBothForHighDegOrNoBrkt) && !allNodes.hasFraction(flat: false) && allNodes.hasBrackets(.notSingle(mayBeFraction: true)) && allNodesDropMultBrkt.count == 2 {
            if allNodes.allSymbs.isHighDegree || allNodes.hasDirectRadVar {}
            else if allNodesDropMultBrkt.hasOnlyNumbers && allNodesDropMultBrkt.nodesHaveEqualValues || allNodesDropMultBrkt.allVars.count > 1 || allNodesDropMultBrkt.contains(where: {$0.hasVar && ($0.multiplierBrkt?.hasVarFlat ?? false)}) {}
            else if allNodesDropMultBrkt.areAllMultiplied || allNodesDropMultBrkt.allVars.count == 1 {return}
        }
        else {return}
        if let fractionWithVar = allNodes.first(where: {$0.isFraction && $0.hasVarFlat}), fnCtrl.contains(.divBothForHighDegOrNoBrkt) {
            if allNodes.dropNode(node: fractionWithVar).hasFraction(flat: false) {} else {return}
        }
        if fnCtrl.contains(.divBothForHighDegOrNoBrkt) && (allNodes.numeratorChain.hasDecimal || removeAllDenominatorsAllowed(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl) || multBothSidesByFractionAllowed(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl) || moveCoeffAllowed(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl)) {return}
        var gcdValue: Double = 1
        if let tmpGcdValue = allNodes.getGCD {gcdValue = tmpGcdValue}
        let commonSymbs = allNodes.dropBrackets.numeratorChain.getCommonSymbs.filter({!$0.isVar})
        var commonRadical = allNodes.dropBrackets.numeratorChain.getCommonRadical
        if commonRadical?.hasRadicalFlat ?? false {commonRadical = nil}
        if commonSymbs.isEmpty && commonRadical == nil && gcdValue == 1 {return}
        let gcdNode = StepNode(valueSK: gcdValue.newSKs)
        gcdNode.directSymbs = commonSymbs
        gcdNode.radicalParent = commonRadical
        if fnCtrl.contains(.forceDivideBothSides) || allNodes.allSymbs.shouldMoveAllToSide || fnCtrl.contains(.divBothForHighDegOrNoBrkt) || !gcdNode.directTerms.isEmpty || allNodes.contains(where: {$0.valueKeys == gcdNode.valueKeys}) {} else {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        // Set symbol
        let allOneTerms = gcdNode.isOneTerm ? allNodes.dropBrackets.dropZeros.filter({$0.isOneSingleTerm}) + (fnCtrl.contains(.divBothForHighDegOrNoBrkt) ? allNodes.onlyFractions.map({$0.children.first!}).filter({$0.children.isOneSingleTerm}) : []) : []
        
        // Mark and Explain
        var toMark: [StepKey] {
            (gcdNode.isOneTerm ? [] : (nodeL.children.dropBrackets.dropZeros.numeratorsFirsts!.flatSKsNoTerms(.dropOp) + (nodeR.children.dropBrackets.dropZeros.numeratorsFirsts?.flatSKsNoTerms(.dropOp) ?? [])).filter({!$0.key.isOp})) + allNodes.dropBrackets.allSymbs.filter({symb in gcdNode.allSymbs.contains(where: {$0.isSymbType(type: symb.type?.key)})}).flatSKs + (commonRadical != nil ? allNodes.dropBrackets.allRadicals.flatSKs : [])
        }
        steps.lastMarked = toMark
        steps.lastExplanation = "Divide both sides by \(gcdNode.flatSKs(.dropPlus).strForExpl)"
        
        // Init substeps
        steps.lastStepSubsteps = [steps.last!]
        
        // Divide both sides
        appendHighOpOnBothSides(opNodes: [gcdNode], highOp: .divide, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // Evaluate Division
        distributeDivider(node: nodeL.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        surfAndEvaluateAndApplyFnTillEnd(parent: nodeL, fnCtrl: fnCtrl + [.skipDistribute, .skipRemoveOneTimesBrkt, .skipMergeFraction, .forceReduce, .forceReduceToOne], &steps.lastStepSubsteps)
        if fnCtrl.contains(.divBothForHighDegOrNoBrkt) {
            removeHighOpOne(node: nodeL.children.last!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        distributeDivider(node: nodeR.children.first!, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        surfAndEvaluateAndApplyFnTillEnd(parent: nodeR, fnCtrl: fnCtrl + [.skipDistribute, .skipRemoveOneTimesBrkt, .skipMergeFraction, .forceReduce, .forceReduceToOne], &steps.lastStepSubsteps)
        if fnCtrl.contains(.divBothForHighDegOrNoBrkt) {
            removeHighOpOne(node: nodeR.children.last!, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // nextmark and append step
        steps.lastMarked.append(contentsOf: toMark + allOneTerms.map({$0.flatSKs(.dropOp)}).flatMap({$0}) + (nodeL.children+nodeR.children).onlyOnes.valuesSK)
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Remove Times One
        removeHighOpOne(node: nodeL.children.first!, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func removeMultByDivBothSidesOneIsZero(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        var allNodes: [StepNode] {nodeL.children + nodeR.children}
        if nodeL.children.isZero || nodeR.children.isZero {} else {return}
        if allNodes.count == 2 && allNodes.contains(where: {$0.isVarWithCoeff}) {}
        else if let brktsNode = allNodes.first(where: {$0.isBrackets(.simplest)}), allNodes.count == 3 && allNodes.isSimplestFormNegletTimesBracket {
            if let multNode = brktsNode.multiplierNode {
                if multNode.isNumber(mayBePowered: false) && !multNode.hasVarFlat {} else {return}
            } else {return}
        } else {return}
        if fnCtrl.isCheckAllowed {nodeL.changeContent(); return}
        
        // Set MultNode
        let multNode = nodeR.children.isZero ? nodeL.children.first(where: {!$0.isBrackets(.notSingle(mayBeFraction: false))})! : nodeR.children.first(where: {!$0.isBrackets(.notSingle(mayBeFraction: false))})!
        let enhancedMultNode = multNode.dropVarAndRadVar(dropNotVarX: false).clone(changeID: false, withParent: false)
        
        // Mark and explain
        steps.lastMarked = enhancedMultNode.flatSKs(.any)
        steps.lastExplanation = "Since the other side is 0, remove \(enhancedMultNode.flatSKs(.onlyMinus).strForExpl) by dividing it on both sides"
        steps.lastStrikeKeys = [enhancedMultNode.strikeKeyWithSymb]
        
        // Init substeps
        steps.lastStepSubsteps = [steps.last!]
        
        // Append Divider
        let toAppendMultNode = enhancedMultNode.clone(changeID: true, withParent: false)
        if !toAppendMultNode.isPlusOrMinus {
            toAppendMultNode.op = .plus
        }
        appendHighOpOnBothSides(opNodes: [toAppendMultNode], highOp: .divide, nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        //
        surfAndEvaluateAndApplyFnTillEnd(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // nextmark and append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
