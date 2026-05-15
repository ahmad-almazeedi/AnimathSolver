//
//  StepLevel.swift
//  Hulul
//
//  Created by Ahmad on 21/02/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

// MARK: Operation Check
extension Array where Element == StepNode {
    var isPlus: Bool {
        op.key == .plus || op.key == .plusMinus
    }
    var isMinus: Bool {
        op.key == .minus
    }
    var isPlusOrMinus: Bool {
        isPlus || isMinus
    }
    var isTimes: Bool {
        op.key == .times
    }
    var isDivide: Bool {
        op.key == .divide
    }
    var isTimesOrDivide: Bool {
        op.key == .times || op.key == .divide
    }
    var isPow: Bool {
        op.key == .pow
    }
    var isHighOp: Bool {
        op.key.isHighOp
    }
}

extension Array where Element == StepNode {
    var op: StepKey {
        get {self.first!.op}
        set {self.first!.op = newValue}
    }
    var parent: StepNode? {
        get {
//            if contains(where: {$0.parent?.id != first!.parent?.id}) {fatalError()}
            return first!.parent
        }
        set {
            if contains(where: {$0.parent?.id != first!.parent?.id}) {fatalError()}
            first!.parent = newValue
        }
    }
    var parents: [StepNode] {
        map{$0.parent ?? StepNode()}
    }
    var root: StepNode {
        parent!.root
    }
    var flatSKs: [StepKey] {
        if isEmpty {return []}
        return first!.flatSKs(.any) + dropFirst().flatMap({$0.flatSKs(.any)})
    }
    func flatSKs(_ opCase: StepNode.OpPrintCase) -> [StepKey] {
        if isEmpty {return []}
        return first!.flatSKs(opCase) + dropFirst().flatMap({$0.flatSKs(.any)})
    }
    var flatSKsForSympy: [Key] {
        if isEmpty {return []}
        return first!.flatSKsForSympy(.dropPlus) + dropFirst().flatMap({$0.flatSKsForSympy(.any)})
    }
    var flatSKsForAISteps: [Key] {
        if isEmpty {return []}
        return first!.flatSKsForAISteps(.dropPlus) + dropFirst().flatMap({$0.flatSKsForAISteps(.any)})
    }
    var sympyStr: String? {
        flatSKsForSympy.sympyStr
    }
    var flatSKsForStrike: [StepKey] {
        if isEmpty {return []}
        return (first!.flatSKsForStrike(dropOp: true) + dropFirst().flatMap({$0.flatSKsForStrike(dropOp: false)}))
    }
    var flatSKsNoOps: [StepKey] {
        if isEmpty {return []}
        return first!.flatSKs(.dropOp) + dropFirst().flatMap({$0.flatSKs(.dropOp)})
    }
    func opValuesSK(_ opCase: StepNode.OpPrintCase) -> [StepKey] {
        if isEmpty {return []}
        return first!.opValueSK(opCase) + dropFirst().flatMap({$0.opValueSK})
    }
    func opValuesSK(opCaseForEach: StepNode.OpPrintCase) -> [StepKey] {
        if isEmpty {return []}
        return first!.opValueSK(opCaseForEach) + dropFirst().flatMap({$0.opValueSK(opCaseForEach)})
    }
    var opValuesSKpows: [StepKey] {
        if isEmpty {return []}
        return first!.valueSKpow(.any) + dropFirst().flatMap({$0.valueSKpow(.any)})
    }
    var valuesSK: [StepKey] {
        if isEmpty {return []}
        return first!.valueSK + dropFirst().flatMap({$0.valueSK})
    }
    var valuesKeys: [[Key]] {
        map({$0.valueKeys})
    }
    var symbStepExpr: [StepKey] {
        map({$0.allSymbs.flatSKs(.dropOp)}).flatMap({$0})
    }
    func flatSKsNoTerms(_ opCase: StepNode.OpPrintCase) -> [StepKey] {
        if isEmpty {return []}
        return first!.flatSKsNoTerms(opCase) + dropFirst().flatMap({$0.flatSKsNoTerms(.any)})
    }
    func flatSKsNoRadicals(_ opCase: StepNode.OpPrintCase) -> [StepKey] {
        if isEmpty {return []}
        return first!.flatSKsNoRadicals(opCase) + dropFirst().flatMap({$0.flatSKsNoRadicals(.any)})
    }
    var flatSKsOnlyPow: [StepKey] {
        if isEmpty {return []}
        return flatMap({$0.flatSKsOnlyPow})
    }
    var flatSKsNoPow: [StepKey] {
        flatMap({$0.flatSKsNoPow})
    }
    var flatKeys: [Key] {
        flatSKs(.any).keys
    }
    func printExpr() {
        let calcBrain = CalcBrain()
        calcBrain.printExprLB(keys: flatKeys)
    }
    var prev: StepNode {
        first!.prev
    }
    var next: StepNode {
        last!.next
    }
    func withOp(_ op: StepKey) -> [StepNode] {
        var newArray = [StepNode]()
        for i in 0..<self.count {
            newArray.append(i == 0 ? self[i].withOp(op) : self[i])
        }
        return newArray
    }
    var isSimplestForm: Bool {
        if hasBrackets(.any) {return false}
        for node in self {
            if node.isPowered || node.isMultipliedOrDivideOrDivided || node.isFraction(.notSimplest(for: .any)) || node.isFraction(.notSimplestReduced) || node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm {return false}
            if let radicalParent = node.radicalParent, !radicalParent.isSimplestRadical {return false}
            if node.hasCommonTerm(in: self) {return false}
        }
        return true
    }
    var isSimplestFormNegletRad: Bool {
        if hasBrackets(.any) {return false}
        for node in self {
            if node.isPowered || node.isMultipliedOrDivideOrDivided || node.isFraction(.notSimplest(for: .any)) || node.isFraction(.notSimplestReduced) || node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm {return false}
            if node.hasCommonTerm(in: self) {return false}
        }
        return true
    }
    var isSimplestFormNegletSimplifiableRadicand: Bool {
        if hasBrackets(.any) {return false}
        for node in self {
            if node.isPowered || node.isMultipliedOrDivideOrDivided || node.isFraction(.notSimplest(for: .any)) || node.isFraction(.notSimplestReduced) || node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm {return false}
            if let radicalParent = node.radicalParent, radicalParent.children.hasRootable(indexValue: radicalParent.indexValue) {return false}
            if node.hasCommonTerm(in: self) {return false}
        }
        return true
    }
    var isSimplestFormNegletPowered: Bool {
        if hasBrackets(.any) {return false}
        for node in self {
            if node.isMultipliedOrDivideOrDivided || node.isFraction(.notSimplest(for: .any)) || node.isFraction(.notSimplestReduced) || node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm {return false}
            if let radicalParent = node.radicalParent, !radicalParent.isSimplestRadical {return false}
            if node.hasCommonTerm(in: self) {return false}
        }
        return true
    }
    var isSimplestFormForMoveToSides: Bool {
        if onlyBrackets.count > 1 {return false}
        for node in self {
            if node.isBrackets {
                if node.isDivide || node.isMultipliedFromBothSides {return false}
                if node.isPowered && node.children.isSimplestForm && node.children.hasVar {continue}
                return false
            } else if node.isMultiplied && node.multiplierBrkt != nil {
                if node.isNumber(mayBePowered: false) && !node.isDivide {continue}
            }
            if node.isPowered || node.isMultipliedOrDivideOrDivided || node.isFraction(.notSimplest(for: .any)) || node.isFraction(.notSimplestReduced) && !node.willBeAddedToFraction || node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm {return false}
            if let radicalParent = node.radicalParent, !radicalParent.isSimplestRadical {return false}
            if node.hasCommonTerm(in: self.filter({!$0.isMultiplied})) {return false}
        }
        return true
    }
    var isSimplestFormNegletTimesBracket: Bool {
        if hasBrackets(.singleNeg(mayBePowered: true)) || hasBrackets(.notMultiplied) && count > 1 {return false}
        if isBrackets(.simplest) || hasOnlyBrackets(.simplest) && isMultChain {return true}
        for node in self {
            if node.isBrackets(.multipliedByNonBracket) {continue}
            if node.isBrackets(.complete) || node.isDivide || node.isPowered || node.isFraction(.notSimplestNegletTimesBrackets(for: .any)) {return false}
            if node.isPlusOrMinus && node.next.isBrackets(.multipliedByNonBracket) && !node.next.next.isHighOp {continue}
            if node.isTimes && node.prev.isBrackets(.multipliedByNonBracket) && node.prev.isPlusOrMinus {continue}
            if node.isTimes {return false}
            if !node.isMultiplied && (node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm) {return false}
            if let radicalParent = node.radicalParent, !radicalParent.isSimplestRadical {return false}
            if node.hasCommonTerm(in: self.dropMultipliedBracketChain) {return false}
        }
        return true
    }
    var isSimplestFormNegletTimesBracketAndVarFractionAddition: Bool {
        if hasBrackets(.singleNeg(mayBePowered: true)) || hasBrackets(.notMultiplied) && count > 1 {return false}
        if isBrackets(.simplest) {return true}
        for node in self {
            if node.isBrackets(.multipliedByNonBracket) {continue}
            if node.isBrackets(.complete) || node.isDivide || node.isPowered || node.isFraction(.notSimplestNegletTimesBrackets(for: .any)) {return false}
            if node.isPlusOrMinus && node.next.isBrackets(.multipliedByNonBracket) && !node.next.next.isHighOp {continue}
            if node.isTimes && node.prev.isBrackets(.multipliedByNonBracket) && node.prev.isPlusOrMinus {continue}
            if node.isTimes {return false}
            if !node.isMultiplied && (node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm) {return false}
            if let radicalParent = node.radicalParent, !radicalParent.isSimplestRadical {return false}
            if !node.hasVarFlat && node.hasCommonTerm(in: self.dropMultipliedBracketChain.filter({!$0.hasVarFlat})) {return false}
        }
        return true
    }
    var isSimplestFormNegletTimesBracketForRemoveAllDens: Bool {
        if hasBrackets(.singleNeg(mayBePowered: true)) || hasBrackets(.notMultiplied) && count > 1 {return false}
        if isBrackets(.simplest) {return true}
        for node in self {
            if node.isBrackets(.multipliedByNonBracket) {continue}
            if node.isBrackets(.complete) || node.isDivide || node.isPowered || node.isFraction(.notSimplestNegletTimesBrackets(for: .any)) {return false}
            if node.isPlusOrMinus && node.next.isBrackets(.multipliedByNonBracket) && !node.next.next.isHighOp {continue}
            if node.isTimes && node.prev.isBrackets(.multipliedByNonBracket) && node.prev.isPlusOrMinus {continue}
            if node.isTimes {return false}
            if !node.isMultiplied && node.isNumber(mayBePowered: true) && !node.symbsAreInSimplestForm {return false}
            if let radicalParent = node.radicalParent {
                if !radicalParent.isSimplestRadical {return false}
            }
        }
        return true
    }
    var isSimplestFormWithVarTimesBrkts: Bool {
        if hasBrackets({$0.hasVar}) {return false}
        if first!.otherSide.isEmpty {return false}
        if first!.otherSide.children.hasVarFlat {return false}
        if !isSimplestFormNegletTimesBracket {return false}
        let multipliers = filter({$0.isMultiplied && !$0.isBrackets})
        if multipliers.isEmpty || multipliers.contains(where: {!($0.isOneSymb && $0.symbIsVar && $0.isTimes)}) {return false}
        return true
    }
    var isSimplestFormWithFractionTimesBracket: Bool {
        if isSimplestFormNegletTimesBracket {} else {return false}
        let multipliers = self.filter({$0.isMultiplied && !$0.isBrackets(.complete)})
        if multipliers.count == 1 && multipliers.first!.isFraction {return true}
        return false
    }
    var isSimplestFormMulti: Bool {
        count > 1 && isSimplestForm
    }
    var isSimplestFormNegletRadMulti: Bool {
        count > 1 && isSimplestFormNegletRad
    }
    var dropMultipliedBracketChain: [StepNode] {
        dropMultipliedBrackets.filter({!($0.next.isBrackets(.complete) && $0.next.isTimes || $0.isTimes && $0.prev.isBrackets(.complete))})
    }
    var dropHighOpChains: [StepNode] {
        filter({!$0.isHighOp && $0.noHighOpAfter})
    }
    var getOps: [StepKey] {
        map({$0.op})
    }
    var hasHighOp: Bool {
        contains(where: {$0.isTimesOrDivide || $0.isPowered})
    }
    var hasLowOp: Bool {
        contains(where: {$0.isPlusOrMinus})
    }
    var isHighDegree: Bool {
        contains(where: {$0.isVar && $0.isPowered && !$0.power.isOne(opCase: .any) && !$0.isPoweredByZero && !$0.power.isFraction})
    }
    var isDecimal: Bool {
        count == 1 && self.first!.isDecimal
    }
    func isZero(opCase: StepNode.OpCase) -> Bool {
        count == 1 && self.first!.isZero(opCase: opCase)
    }
    var isZero: Bool {
        count == 1 && self.first!.isZero
    }
    var isMulti: Bool {
        count > 1
    }
    func isSingle(mayBeFraction: Bool, mayBePowered: Bool) -> Bool {
        if !mayBeFraction && first!.isFraction {return false}
        return self.count == 1 && (first!.isNumber(mayBePowered: mayBePowered) || first!.isFraction(.simplestReduced))
    }
    func isSingle(mayBeFraction: Bool, fractionCase: StepNode.FractionCase, mayBePowered: Bool) -> Bool {
        if !mayBeFraction && first!.isFraction {return false}
        return self.count == 1 && (first!.isNumber(mayBePowered: mayBePowered) || first!.isFraction(fractionCase))
    }
    func isSingle(mayBeFraction: Bool, fractionCase: StepNode.FractionCase, mayBePowered: Bool, mayBeBrackets: Bool) -> Bool {
        if !mayBeFraction && first!.isFraction {return false}
        return self.count == 1 && (first!.isNumber(mayBePowered: mayBePowered) || first!.isFraction(fractionCase) || first!.isBrackets && mayBeBrackets)
    }
    var isSingleNeg: Bool {
        count == 1 && isMinus && !first!.isBrackets
    }
    var isFraction: Bool {
        count == 1 && first!.isFraction
    }
    func isFraction(_ fractionCase: StepNode.FractionCase) -> Bool {
        count == 1 && first!.isFraction(fractionCase)
    }
    func isFraction(part: StepNode.FractionPart, _ conditions: ([StepNode]) -> Bool) -> Bool {
        count == 1 && first!.isFraction(part: part, conditions)
    }
    var valueDouble: Double {
        if self.count != 1 {fatalError()}
        return self.first!.valueDouble
    }
    var valuesDouble: [Double] {
        map({$0.valueDouble})
    }
    var hasOnlyTimes: Bool {
        !self.dropFirst().contains(where: {!$0.isTimes})
    }
    var hasOnlyMinus: Bool {
        !contains(where: {!$0.isMinus})
    }
    var hasOnlyPlus: Bool {
        !contains(where: {!$0.isPlus})
    }
    func isOne(opCase: StepNode.OpCase) -> Bool {
        count == 1 && first!.isOne(opCase: opCase)
    }
    var denominatorsFirsts: [StepNode] {
        if self.contains(where: {!$0.isFraction || $0.denominator.count > 1}) {fatalError()}
        return map({$0.denominator.first!})
    }
    var numeratorsFirsts: [StepNode]? {
        var tmp = [StepNode]()
        for node in self {
            if node.isFraction {
                if node.numerator.count > 1 {return nil}
                tmp.append(node.numerator.first!)
            } else {
                tmp.append(node)
            }
        }
        if tmp.isEmpty || !tmp.hasOnlyNumbers {return nil}
        return tmp
    }
    var getGCD: Double? {
        if contains(where: {$0.isNumber(mayBePowered: true) && $0.isPowered}) {return nil}
        if contains(where: {$0.isBrackets(.notSingle(mayBeFraction: false)) && !$0.isMultipliedByNonBrackets}) {return nil}
        if contains(where: {$0.isFraction(.notSingle(for: .numerator))}) {return nil}
        let allCoeffsNodes = filter({!$0.isBrackets(.notSingle(mayBeFraction: false))}).map({$0.dynamicNumeratorFirst})
        let allCoeffs = allCoeffsNodes.map({$0.dynamicValue.getDouble})
        if allCoeffs.count == 1 {return nil}
        let gcdValue = allCoeffs.gcd
        let isTrueForDecimal = !allCoeffsNodes.hasDecimal || allCoeffsNodes.hasDecimal && allCoeffs.contains(gcdValue)
        return !isTrueForDecimal || gcdValue == 1 ? nil : gcdValue
    }
    var forcedGCD: Double {
        if contains(where: {$0.isNumber(mayBePowered: true) && $0.isPowered}) {fatalError()}
        if contains(where: {$0.isBrackets(.notSingle(mayBeFraction: false)) && !$0.isMultiplied}) {return 1}
        if contains(where: {$0.isFraction(.notSingle(for: .numerator))}) {return 1}
        let allCoeffsNodes = filter({!$0.isBrackets(.notSingle(mayBeFraction: false))}).map({$0.dynamicNumeratorFirst})
        let allCoeffs = allCoeffsNodes.map({$0.dynamicValue.getDouble})
        return allCoeffs.gcd
    }
    func getGCDWithTerms(withOp: Bool) -> StepNode? {
        var gcdNode = StepNode.newOneNode
        if let gcdValue = getGCD {
            gcdNode = gcdValue.newNode
        }
        gcdNode.directSymbs = getCommonSymbs
        gcdNode.radicalParent = getCommonRadical
        if withOp && hasOnlyMinus {
            gcdNode.op = .minus
            return gcdNode
        }
        return gcdNode.isOne ? nil : gcdNode
    }
    var isVarWithCoeff: Bool {
        count == 1 && first!.isVarWithCoeff
    }
    var flatTree: [StepNode] {
        flatMap({$0.flatTree})
    }
    var flatTreeNoPow: [StepNode] {
        flatMap({$0.flatTreeNoPow})
    }
    var dropBracketsNotSingleNeg: [StepNode] {
        filter({!$0.isBrackets(.notSingle(mayBeFraction: false))})
    }
    var dropBrktsAndNextTimes: [StepNode] {
        let newNodes = cloneWithChangedStaticIDs
        for node in newNodes {
            if !node.isBrackets {
                if node.isTimes && node.prev.isBrackets && node.prev.isPlusOrMinus {
                    node.op = .plus
                }
            }
        }
        newNodes.onlyBrackets.removeNodesFromParent()
        return newNodes.parent!.children
    }
    var dropBrackets: [StepNode] {
        filter({!$0.isBrackets})
    }
    var dropReduced: [StepNode] {
        filter({!$0.isReduced})
    }
    var dropMultipliedBrackets: [StepNode] {
        filter({!($0.isBrackets(.multipliedByNonBracket))})
    }
    var multipliedBracketsNodes: [StepNode] {
        filter({$0.isBrackets(.multipliedByNonBracket)})
    }
    var hasVar: Bool {
        numeratorChain.contains(where: {$0.hasVar})
    }
    var hasVarOrI: Bool {
        numeratorChain.contains(where: {$0.hasVarOrI})
    }
    var hasVarOrNotVarXOrI: Bool {
        numeratorChain.contains(where: {$0.hasVarOrNotVarXOrI})
    }
    var hasConstant: Bool {
        numeratorChain.contains(where: {$0.isConst})
    }
    var hasSymbFlat: Bool {
        flatTree.contains(where: {$0.hasDirectSymbs})
    }
    var hasVarFlat: Bool {
        flatTree.contains(where: {$0.hasVar})
    }
    var hasVarOrNotVarXFlat: Bool {
        flatTree.contains(where: {$0.hasVarOrNotVarX})
    }
    var hasIFlat: Bool {
        flatTree.contains(where: {$0.hasI})
    }
    var hasVarOrIFlat: Bool {
        flatTree.contains(where: {$0.hasVarOrI})
    }
    var hasVarOrNotVarXOrIFlat: Bool {
        flatTree.contains(where: {$0.hasVarOrNotVarXOrI})
    }
    var hasVarOrNotVarXOrIFlatNoPow: Bool {
        flatTreeNoPow.contains(where: {$0.hasVarOrNotVarXOrI})
    }
    var hasMinusFlatNoPow: Bool {
        flatTreeNoPow.contains(where: {$0.isMinus})
    }
    var hasPlusAndMinus: Bool {
        contains(where: {$0.isPlus}) && contains(where: {$0.isMinus})
    }
    var hasPlusAndMinusFlat: Bool {
        let flatTree = flatTree
        return flatTree.contains(where: {$0.isPlus}) && flatTree.contains(where: {$0.isMinus})
    }

    func hasFraction(flat: Bool) -> Bool {
        flat ? flatTreeNoPow.contains(where: {$0.isFraction}) : contains(where: {$0.isFraction})
    }
    func hasFractionFlat(part: StepNode.FractionPart, _ conditions: ([StepNode]) -> Bool) -> Bool {
        flatTreeNoPow.contains(where: {$0.isFraction(part: part, conditions)})
    }
    var hasOnlyFractions: Bool {
        if isEmpty {return false}
        return !contains(where: {!$0.isFraction})
    }
    func hasOnlyBrackets(_ bracketsCase: StepNode.BracketsCase) -> Bool {
        if isEmpty {return false}
        return !contains(where: {!$0.isBrackets(bracketsCase)})
    }
    var hasOnlyDecimals: Bool {
        if isEmpty {return false}
        return !contains(where: {!$0.isDecimal})
    }
    func hasNumber(mayBePowered: Bool) -> Bool {
        self.contains(where: {$0.isNumber(mayBePowered: mayBePowered)})
    }
    var hasOnlyNumbers: Bool {
        if isEmpty {return false}
        return !contains(where: {!$0.isNumber(mayBePowered: true)})
    }
    var isSurfed: Bool {
        get {contains(where: {$0.isSurfed})}
        set {
            for node in self {
                node.isSurfed = newValue
            }
        }
    }
    var isReduced: Bool {
        get {contains(where: {$0.isReduced})}
        set {
            for node in self {
                node.isReduced = newValue
            }
        }
    }
    func isBrackets(_ bracketsCase: StepNode.BracketsCase) -> Bool {
        count == 1 && first!.isBrackets(bracketsCase)
    }
    func isBrackets(_ conditions: ([StepNode]) -> Bool) -> Bool {
        count == 1 && first!.isBrackets(conditions)
    }
    var isBrackets: Bool {
        count == 1 && first!.isBrackets
    }
    var isBracketsNotHidden: Bool {
        count == 1 && first!.isBracketsNotHidden
    }
    var isBrktAloneInPoweredBrkt: Bool {
        count == 1 && first!.isBrktAloneInPoweredBrkt
    }
    func setSurfedToTrue() {
        for node in self {
            node.isSurfed = true
        }
    }
    func setSurfedToFalse(keepTargets: Bool) {
        for node in self {
            node.setSurfedToFalse(keepTargets: keepTargets)
        }
    }
    var onlyBrackets: [StepNode] {
        filter({$0.isBrktsNotSqrt})
    }
}

extension Array where Element == StepNode {
    
    mutating func replaceNodesWithResult(nodes: [StepNode], resultNode: StepNode) {
        let node = nodes.first!
        node.children.removeAll()
        let idx = node.idx!
        self.removeAll(where: {nodes.contains($0)})
        node.content = resultNode.content
        self.insert(node, at: idx)
    }
    
    func getResultNodeForAddition() -> StepNode {
        
        // Initializations
        let calcBrain = CalcBrain()
        let origStepExprNoTerms = flatSKsNoTerms(.onlyMinus)
        
        // Get Result
        let resultDouble = calcBrain.getResultByExecute(exprKeys: origStepExprNoTerms.keys, precision: 13)
        var resultStepKeys = resultDouble.newSKs
        
        // Replace Similer Keys
        if resultStepKeys.count > 1 || resultStepKeys.first!.key == origStepExprNoTerms.first!.key {
            resultStepKeys.replaceSimilarKeys(similarKeys: origStepExprNoTerms)
        }
        
        // Create a node out of the result step keys and fix plus ID
        var resultNode = resultStepKeys.newNode
        if resultNode.isPlus && self.isPlus {
            resultNode.op = self.op
        } else if self.isTimes {
            if resultNode.isMinus {
                let newBrackets = StepNode.newBracketsNode
                newBrackets.valueSK.replaceSimilarKeys(similarKeys: origStepExprNoTerms)
                newBrackets.op = self.op
                newBrackets.children.append(resultNode.clone(changeID: false, withParent: false))
                resultNode = newBrackets
            } else {
                resultNode.op = self.op
            }
        }
        
        // Return Symbols to node
        resultNode.radicalParent = first!.radicalParent
        resultNode.directSymbs = first!.directSymbs
        
        // Return result node
        return resultNode
    }
    
    func getResultNodeForHighOp(returnSymbs: Bool) -> StepNode {
        
        // Initializations
        let calcBrain = CalcBrain()
        let firstIsNegBrackets = first!.isBrackets(.complete) && isMinus
        let origStepExprNoTerms = self.flatSKsNoTerms(firstIsNegBrackets ? .dropOp : .onlyMinus)
        
        // Get Result
        let resultDouble = calcBrain.getResultByExecute(exprKeys: origStepExprNoTerms.keys, precision: 13)
        var resultStepKeys = resultDouble.newSKs
        
        // Replace Similer Keys
        resultStepKeys.replaceSimilarKeys(similarKeys: origStepExprNoTerms)
        
        // Create a node out of the result step keys and fix plus ID
        var resultNode = resultStepKeys.newNode
        if resultNode.isPlus && self.isPlus {
            resultNode.op = self.op
        } else if self.isTimes || firstIsNegBrackets {
            if resultNode.isMinus {
                let newBrackets = StepNode.newBracketsNode
                newBrackets.valueSK.replaceSimilarKeys(similarKeys: origStepExprNoTerms)
                newBrackets.op = self.op
                newBrackets.children.append(resultNode.clone(changeID: false, withParent: false))
                resultNode = newBrackets
            } else {
                resultNode.op = self.op
            }
        }
        
        // Return Symbols to node
        if returnSymbs {
            resultNode.radicalParent = self.first!.radicalParent
            resultNode.directSymbs = self.clone(changeID: false, withParent: false).flatTree.first(where: {$0.hasDirectSymbs})?.directSymbs ?? []
        }
        
        // Return result node
        return resultNode
    }
    
    func linkToParent(parentNode: StepNode?) {
        for i in 0..<self.count {
            self[i].parent = parentNode
        }
    }
    func flipSigns() {
        for i in 0..<self.count {
            self[i].flipSign()
        }
    }
    var withFlippedSigns: [StepNode] {
        let clones = clone(changeID: false, withParent: false).children
        clones.flipSigns()
        return clones
    }
    func flipSignsAndChangeIDs() {
        for i in 0..<self.count {
            self[i].flipSignsAndChangeIDs()
        }
    }
    func idxToMove(nodesToMove: [StepNode]) -> Int {
        if nodesToMove.count == 1 {
            if let idx = dropFractions.dropMultipliedBracketChain.last(where: {$0.directTerms.isEqualTo(nodes: nodesToMove.first!.directTerms)})?.idx {
                return idx
            } else if let idx = first(where: {$0.hasDirectI})?.idx {
                return idx-1
            }
        }
        return count-1
    }
    func hasEqualCommonFactor(with dividerNode: StepNode) -> Bool {
        for inNode in self.filter({!$0.isBrackets(.complete)}) {
            let inNodeValue = inNode.opValueSK(.dropPlus).getDouble
            let divider = [StepKey](dividerNode.valueSK).getDouble
            let result = inNodeValue/divider
            if result != floor(result) {
                return false
            }
        }
        return true
    }
    var dropPowBracketsFraction: [StepNode] {
        filter({!$0.isBrackets(.complete) && !$0.isPowered && !$0.isFraction})
    }
    var dropSurfed: [StepNode] {
        filter({!$0.isSurfed})
    }
    func containsNode(_ node: StepNode) -> Bool {
        self.map({$0.id}).contains(node.id)
    }
    func containsNodes(_ nodes: [StepNode]) -> Bool {
        for node in nodes {
            if !self.map({$0.id}).contains(node.id) {return false}
        }
        return true
    }
    func clone(changeID: Bool, withParent: Bool) -> StepNode {
        if isEmpty {
            return StepNode()
        } else if withParent {
            if let parent = parent  {
                if self.count != parent.children.count {fatalError()}
                return parent.clone(changeID: changeID, withParent: withParent)
            } else {fatalError()}
        } else {
            let newParent = StepNode()
            newParent.isLeft = self.first!.root.isLeft
            var nodesClone = [StepNode]()
            for node in self {
                nodesClone.append(node.clone(changeID: changeID, withParent: false))
            }
            newParent.children.append(contentsOf: nodesClone)
            return newParent
        }
    }
    func clones(changeID: Bool, withParent: Bool) -> [StepNode] {
        map({$0.clone(changeID: changeID, withParent: withParent)})
    }
    func resultNodes() -> [StepNode] {
        let calcBrain = CalcBrain()
        let tempNode = StepNode()
        tempNode.children = self
        let outputNode = calcBrain.surfAndEvaluateAndApplyFnTillEndOutput(nodeL: tempNode, nodeR: StepNode(), fnCtrl: []).nodeL
        return outputNode.children
    }
    func resultNodesClone() -> [StepNode] {
        let calcBrain = CalcBrain()
        let tempNode = StepNode()
        tempNode.children = self.clone(changeID: false, withParent: false).children
        let outputNode = calcBrain.surfAndEvaluateAndApplyFnTillEndOutput(nodeL: tempNode, nodeR: StepNode(), fnCtrl: []).nodeL
        return outputNode.children
    }
    func resultValue() -> Double {
        let calcBrain = CalcBrain()
        let clone = self.clone(changeID: false, withParent: false)
        calcBrain.removeExtras(nodeL: clone, nodeR: StepNode())
        return calcBrain.getResultByExecute(exprKeys: clone.children.flatSKs(.dropPlus).dropPlusMinuses.keys, precision: 13)
    }
    var nodesAreEqual: Bool {
        !self.contains(where: {!$0.isEqualTo(node: self.first!)})
    }
    var nodesHaveEqualBase: Bool {
        !self.contains(where: {!$0.hasEqualBase(with: self.first!)})
    }
    var nodesHaveEqualBaseIfExpo: Bool {
        !self.contains(where: {!$0.hasEqualBaseIfExpo(with: self.first!)})
    }
    var nodesDontHaveEqualBase: Bool {
        for node in self {
            if self.dropNode(node: node).contains(where: {$0.hasEqualBase(with: node)}) {
                return false
            }
        }
        return true
    }
    func removeNodesFromParent() {
        for node in self {
            node.remove()
        }
    }
    func setNodesToTimesOne() {
        for node in self {
            node.content = StepNode.newOneNode.withOp(.times).content
        }
    }
    func isEqualTo(nodes: [StepNode]) -> Bool {
        var tempNodes = self
        for node in nodes {
            if let equalNodeIdx = tempNodes.firstIndex(where: {$0.isEqualTo(node: node)}) {
                tempNodes.remove(at: equalNodeIdx)
            } else {return false}
        }
        if tempNodes.isEmpty {return true} else {return false}
    }
    func isEqualAndSameOrderTo(nodes: [StepNode]) -> Bool {
        if nodes.count != self.count {return false}
        for i in 0..<nodes.count {
            guard nodes[i].isEqualTo(node: self[i]) else {return false}
        }
        return true
    }
    func isEqualToEitherNodes(_ nodess: [[StepNode]]) -> Bool {
        nodess.contains(where: {nodes in nodes.isEqualTo(nodes: self)})
    }
    var dropFractions: [StepNode] {
        filter({!$0.isFraction})
    }
    var dropPoweredBySymb: [StepNode] {
        filter({!$0.isPoweredBySymb})
    }
    func dropNumbers(mayBePowered: Bool) -> [StepNode] {
        filter({!$0.isNumber(mayBePowered: mayBePowered)})
    }
    func dropNode(node: StepNode) -> [StepNode] {
        filter({$0.id != node.id})
    }
    func dropNodes(nodes: [StepNode]) -> [StepNode] {
        filter({ selfNode in !nodes.contains(where: {node in selfNode.id == node.id})})
    }
    func hasBrackets(_ bracketsCase: StepNode.BracketsCase) -> Bool {
        contains(where: {$0.isBrackets(bracketsCase)})
    }
    func hasBrackets(_ conditions: ([StepNode]) -> Bool) -> Bool {
        contains(where: {$0.isBrackets(conditions)})
    }
    var hasBrackets: Bool {
        contains(where: {$0.isBrackets})
    }
    var hasBracketsNotHidden: Bool {
        contains(where: {$0.isBracketsNotHidden})
    }
    func hasFraction(_ fractionCase: StepNode.FractionCase) -> Bool {
        contains(where: {$0.isFraction(fractionCase)})
    }
    func hasFraction(part: StepNode.FractionPart, _ conditions: ([StepNode]) -> Bool) -> Bool {
        contains(where: {$0.isFraction(part: part, conditions)})
    }
    func isEqualHighOpChain(nodes: [StepNode]) -> Bool {
        if !self.first!.hasEqualOp(with: nodes.first!) {return false}
        if self.first!.highOpChain != self {fatalError()}
        var tmpMainChain = self.clone(changeID: false, withParent: false).children
        if tmpMainChain.isPlusOrMinus {
            tmpMainChain.op = .times
        }
        if nodes.first!.highOpChain != nodes {fatalError()}
        var tmpOtherChain = nodes.clone(changeID: false, withParent: false).children
        if tmpOtherChain.isPlusOrMinus {
            tmpOtherChain.op = .times
        }
        return tmpMainChain.isEqualTo(nodes: tmpOtherChain)
    }
    var isMultChain: Bool {
        if isDivide {fatalError()}
        return !dropFirst().contains(where: {!$0.isTimes})
    }
    var isMultChainOrSimplestForm: Bool {
        isMultChain || isSimplestForm
    }
    var isHighOpChainOrSimplestForm: Bool {
        isHighOpChain || isSimplestForm
    }
    var isHighOpChain: Bool {
        !dropFirst().contains(where: {!$0.isHighOp})
    }
    var isPosHighOpChain: Bool {
        isPlus && !dropFirst().contains(where: {!$0.isHighOp})
    }
    var allTerms: [StepNode] {
        map({$0.allTerms}).filter({!$0.isEmpty}).flatMap({$0})
    }
    var allRadicals: [StepNode] {
        map({$0.allRadicals}).filter({!$0.isEmpty}).flatMap({$0})
    }
    var allSqrts: [StepNode] {
        filter({$0.isSqrt})
    }
    var allSymbs: [StepNode] {
        map({$0.allSymbs}).filter({!$0.isEmpty}).flatMap({$0})
    }
    var allSymbsFlat: [StepNode] {
        map({$0.allSymbsFlat}).filter({!$0.isEmpty}).flatMap({$0})
    }
    var allVars: [StepNode] {
        allSymbs.onlyVars
    }
    var allVarsFlat: [StepNode] {
        allSymbsFlat.onlyVars
    }
    var hasTerm: Bool {
        contains(where: {$0.hasTerm})
    }
    var hasSymb: Bool {
        contains(where: {!$0.allSymbs.isEmpty})
    }
    var containsVar: Bool {
        contains(where: {$0.containsVar})
    }
    func isVar(firstDeg: Bool) -> Bool {
        count == 1 && first!.valueIsOne && first!.symbIsVar(firstDeg: firstDeg)
    }
    func isOneSingleVar(mayBeInSqrt: Bool) -> Bool {
        count == 1 && first!.isOneSingleVar(mayBeInSqrt: mayBeInSqrt)
    }
    var isOneSymb: Bool {
        count == 1 && first!.isOneSymb
    }
    var isOneTerm: Bool {
        count == 1 && first!.isOneTerm
    }
    var isOneSingleTerm: Bool {
        count == 1 && first!.isOneSingleTerm
    }
    var isOneSingleRadical: Bool {
        count == 1 && first!.isOneSingleRadical
    }
    var shouldSetBrktIfPowered: Bool {
        count != 1 || first!.shouldSetBrktIfPowered
    }
    var dropFirst: [StepNode] {
        [StepNode](self.dropFirst())
    }
    var dropLast: [StepNode] {
        [StepNode](self.dropLast())
    }
    func isFirst(node: StepNode) -> Bool {
        first!.id == node.id
    }
    var numeratorChain: [StepNode] {
        var numChain = [StepNode]()
        for node in self {
            if node.isFraction {
                let numContent = node.numerator
                if numContent.isSimplestForm && numContent.count > 1 {
                    let newBrkt = numContent.parent!
                    numChain.append(newBrkt)
                } else {
                    numChain.append(contentsOf: numContent)
                }
            } else {
                numChain.append(node)
            }
        }
        return numChain
    }
    
    var denominatorChain: [StepNode] {
        var denChain = [StepNode]()
        for node in self {
            if node.isFraction {
                let denContent = node.denominator
                if denContent.isSimplestForm && denContent.count > 1 {
                    let newBrkt = denContent.parent!
                    denChain.append(newBrkt)
                } else {
                    denChain.append(contentsOf: denContent)
                }
            }
        }
        return denChain
    }
    var dropPoweredNegatives: [StepNode] {
        filter({!($0.isPowered && $0.isBrackets(.singleNeg(mayBePowered: true)))})
    }
    var dropMultOnes: [StepNode] {
        filter({!($0.valueIsOne && !$0.isCoeff && ($0.isMultiplied || $0.isInNumerator && $0.isAlone))})
    }
    var dropMultZeros: [StepNode] {
        filter({!($0.valueIsZero && ($0.isMultiplied || $0.isInNumerator && $0.isAlone))})
    }
    var dropZeros: [StepNode] {
        filter({!$0.isZero})
    }
    var dropOnes: [StepNode] {
        filter({!$0.isOne})
    }
    var dropOneTerms: [StepNode] {
        filter({!$0.isOneTerm})
    }
    var dropEmpties: [StepNode] {
        filter({!$0.isEmptyOrSemiEmpty})
    }
    var isSemiEmpty: Bool {
        count == 1 && first!.valueSK.isEmpty && isPlus
    }
    var isEmptyOrSemiEmpty: Bool {
        isEmpty || isSemiEmpty
    }
    var isFilledWithEmpties: Bool {
        allSatisfy({$0.isFilledWithEmpties})
    }
    var chain1stLevelFlatNodes: [StepNode] {
        numeratorChain + denominatorChain
    }
    var onlySingles: [StepNode] {
        filter({!$0.isBrackets(.notSingle(mayBeFraction: false))})
    }
    var onlyHasRadicals: [StepNode] {
        filter({$0.hasDirectRadical})
    }
    var onlyOnes: [StepNode] {
        filter({$0.isOne})
    }
    var onlyVars: [StepNode] {
        filter({$0.isVar})
    }
    var onlyConsts: [StepNode] {
        filter({$0.isConst})
    }
    var hasNegative: Bool {
        contains(where: {$0.isNegative})
    }
    var hasNegativeDropFirst: Bool {
        let chainNodes = chain1stLevelFlatNodes
        return chainNodes.hasNegative && !(chainNodes.filter({$0.isNegative}).count == 1 && first!.isNegative)
    }
    var simplestNotSingle: Bool {
        isSimplestForm && count > 1
    }
    var hasDecimal: Bool {
        contains(where: {$0.isNumber(mayBePowered: false) && $0.isDecimal})
    }
    var hasDirectRadical: Bool {
        contains(where: {$0.hasDirectRadical})
    }
    func hasDirectRadical(_ conditions: (StepNode) -> Bool) -> Bool {
        contains(where: {$0.hasDirectRadical(conditions)})
    }
    var hasDirectDoubleRadicalFlat: Bool {
        flatTree.contains(where: {$0.hasDirectDoubleRadical})
    }
    var hasRadicalFlat: Bool {
        contains(where: {$0.hasRadicalFlat})
    }
    var allRadicalsFlat: [StepNode] {
        map({$0.allRadicalsFlat}).flatMap({$0})
    }
    var hasPoweredRadWithFraction: Bool {
        allRadicalsFlat.contains(where: {$0.isPowered && $0.children.hasFraction(flat: true)})
    }
    var hasRadicalMayBeUndefinable: Bool {
        for radical in allRadicalsFlat {
            if radical.children.mayBeUndefinable {return true}
        }
        return false
    }
    var nestedFractionsAndPowCount: Double {
        var fractionCounts = [Double]()
        for node in self {
            if node.isFraction {
                let numBase = !node.numerator.hasFraction(flat: true) && node.numerator.hasPowered ? 1.3 : 1
                let denBase = !node.denominator.hasFraction(flat: true) && node.denominator.hasPowered ? 1.3 : 1
                fractionCounts.append(Swift.max(node.numerator.nestedFractionsAndPowCount, numBase) + Swift.max(node.denominator.nestedFractionsAndPowCount, denBase))
            } else if node.isBrackets {
                fractionCounts.append(node.children.nestedFractionsAndPowCount)
            } else if let radicalParent = node.radicalParent {
                fractionCounts.append(radicalParent.children.nestedFractionsAndPowCount)
            }
        }
        return fractionCounts.max() ?? 0
    }
    var nestedFractionsCount: Double {
        var fractionCounts = [Double]()
        for node in self {
            if node.isFraction {
                fractionCounts.append(Swift.max(node.numerator.nestedFractionsAndPowCount, 1) + Swift.max(node.denominator.nestedFractionsAndPowCount, 1))
            } else if node.isBrackets {
                fractionCounts.append(node.children.nestedFractionsAndPowCount)
            } else if let radicalParent = node.radicalParent {
                fractionCounts.append(radicalParent.children.nestedFractionsAndPowCount)
            }
        }
        return fractionCounts.max() ?? 0
    }
    
    var hasPowered: Bool {
        contains(where: {$0.isPowered})
    }
    var hasOnlyPowereds: Bool {
        !contains(where: {!$0.isPowered})
    }
    var hasPoweredByFraction: Bool {
        contains(where: {$0.power.isFraction})
    }
    var hasPoweredByNotPosConst: Bool {
        contains(where: {$0.isPowered && ($0.power.isMinus || $0.power.isZero || !($0.power.count == 1 && $0.power.first!.isNumber(mayBePowered: false) && $0.power.first!.isConst && $0.power.isSimplestForm))})
    }
    var hasPoweredByNotWholeNumber: Bool {
        contains(where: {!$0.isPoweredByWholeNumberOrNotPowered})
    }
    var hasPoweredByNotSimplestForm: Bool {
        contains(where: {!$0.power.isSimplestForm})
    }
    var hasFractionPowWithDDDFlat: Bool {
        flatTree.contains(where: {$0.power.isFraction && $0.power.first!.denominator.valueDouble > 99})
    }
    var hasPoweredFlat: Bool {
        flatTreeNoPow.contains(where: {$0.isPowered})
    }
    var allPowers: [[StepNode]] {
        flatTreeNoPow.filter({$0.isPowered}).map({$0.power})
    }
    var hasNotTermNorBrktPoweredFlat: Bool {
        flatTreeNoPow.contains(where: {!($0.isTerm || $0.isBrackets) && $0.isPowered})
    }
    func isWholeNumber(mayBeCoeff: Bool) -> Bool {
        count == 1 && first!.isWholeNumber(mayBeCoeff: mayBeCoeff)
    }
    func isWholeNumber(mayBePowered: Bool, mayBeCoeff: Bool) -> Bool {
        count == 1 && first!.isWholeNumber(mayBePowered: mayBePowered, mayBeCoeff: mayBeCoeff)
    }
    func containsEqualDirectTerms(nodes: [StepNode]) -> Bool {
        for node in nodes {
            if contains(where: {node.hasEqualTerms(with: $0)}) {
                return true
            }
        }
        return false
    }
    var allpowersFlattened: [StepNode] {
        map({$0.power + $0.children.allpowersFlattened + ($0.radicalParent?.power ?? [])}).filter({!$0.isEmpty}).flatMap({$0})
    }
    var onlyFractions: [StepNode] {
        filter({$0.isFraction})
    }
    var onlyNumbers: [StepNode] {
        filter({$0.isNumber(mayBePowered: true)})
    }
    var onlyNumbersAndFractions: [StepNode] {
        filter({$0.isNumber(mayBePowered: true) || $0.isFraction})
    }
    func setBrackets() {
        let brktsNode = StepNode.newBracketsNode
        self.first!.insertBefore(brktsNode)
        self.removeNodesFromParent()
        brktsNode.children = self
    }
    func setBrackets(extrctOp: Bool) {
        let brktsNode = StepNode.newBracketsNode
        self.first!.insertBefore(brktsNode)
        self.removeNodesFromParent()
        brktsNode.children = self
        if extrctOp && !(isMinus && isSimplestFormMulti) {
            brktsNode.op = self.op
            self.first!.op = .plus
        }
    }
    var termMix: [StepNode] {
        map({$0.termMix}).flatMap({$0})
    }
    var symbMix: [StepNode] {
        map({$0.symbMix}).flatMap({$0})
    }
    var symbMixCoeffsFirst: [StepNode] {
        self + map({$0.directSymbs}).flatMap({$0})
    }
    var getCommonRadical: StepNode? {
        if contains(where: {!$0.hasDirectRadical}) {return nil}
        let radicalNodes = directRadicals
        return radicalNodes.nodesHaveEqualBase ? radicalNodes.first(where: {$0.powerValue == radicalNodes.map({$0.powerValue}).min()!})!.clone(changeID: true, withParent: false) : nil
    }
    var getCommonSymbs: [StepNode] {
        if contains(where: {!$0.hasDirectSymbs}) {return []}
        let arrayOfSymbs = map{$0.directSymbs}
        var commonSymbs = [StepNode]()
        for symbType in Key.allSymbTypes {
            if arrayOfSymbs.filter({$0.contains(where: {$0.type?.key == symbType})}).count == arrayOfSymbs.count {
                let sameSymbs = arrayOfSymbs.map({$0.first(where: {$0.type?.key == symbType}) ?? StepNode.commaNode})
                if sameSymbs.contains(where: {$0.isCommaNode}) {return []}
                let commonSymb = sameSymbs.first!.clone(changeID: false, withParent: false)
                if sameSymbs.contains(where: {$0.isPowered && !$0.isPoweredByWholeNumber}) {return []}
                let minPowValue = sameSymbs.min(by: {$0.powerValue < $1.powerValue})!.powerValue
                if commonSymb.powerValue != minPowValue {
                    if minPowValue == 1 {
                        commonSymb.removePower()
                    } else {
                        commonSymb.power = [minPowValue.newNode]
                    }
                    commonSymb.changeIDs()
                }
                commonSymbs.append(commonSymb)
            }
        }
        commonSymbs.reorderSymbs()
        return commonSymbs
    }
    var getCommonVars: [StepNode] {
        getCommonSymbs.onlyVars
    }
    mutating func reorderSymbs() {
        while let varOrISymb = first(where: {$0.type?.key.isVarOrI ?? false}), !(last(where: {$0.type != nil && !$0.type!.key.isVarOrI && firstIndex(of: $0)! > firstIndex(of: varOrISymb)!})?.hasEqualID(with: varOrISymb) ?? true) {
            removeAll(where: {varOrISymb.hasEqualID(with: $0)})
            append(varOrISymb)
        }
    }
    func hasSymbType(type: Key) -> Bool {
        allSymbs.contains(where: {$0.type?.key == type})
    }
    func hasSymbTypeFlat(type: Key?) -> Bool {
        allSymbsFlat.contains(where: {$0.type?.key == type})
    }
    func uniqueSymbs(flat: Bool) -> [Key] {
        var tmpSymbs = [Key]()
        for symbType in Key.allSymbTypes {
            if flat ? hasSymbTypeFlat(type: symbType) : hasSymbType(type: symbType) {
                tmpSymbs.append(symbType)
            }
        }
        if contains(where: {$0.isWholeNumber(mayBeCoeff: false)}) {
            tmpSymbs.append(.comma)
        }
        return tmpSymbs
    }
    var uniqueRadicals: [StepNode] {
        if contains(where: {!$0.isSqrt || $0.isPowered}) {fatalError()}
        var uniqueRads = [StepNode]()
        for radicalNode in self {
            if uniqueRads.contains(where: {$0.isEqualTo(node: radicalNode)}) {continue}
            uniqueRads.append(radicalNode)
        }
        return uniqueRads
    }
    func isNumberWithX(mayBeDecimal: Bool, mayBeOneVar: Bool) -> Bool {
        count == 1 && (mayBeOneVar || !first!.isOneSingleTerm) && (mayBeDecimal && first!.isNumber(mayBePowered: false) || first!.isWholeNumber(mayBeCoeff: true)) && first!.hasVar
    }
    var symbsLCM: [StepNode] {
        var lcm = [StepNode]()
        for symbType in Key.allSymbTypes {
            if let symbNode = allSymbs.filter({$0.isSymbType(type: symbType)}).max(by: {$0.powerValue < $1.powerValue}) {
                lcm.append(symbNode)
            }
        }
        lcm.reorderSymbs()
        return lcm.clone(changeID: true, withParent: false).children
    }
    var radicalsLCM: [StepNode] {
        let densNumberNodes = filter({$0.denominator.hasNumber(mayBePowered: false)}).map({$0.denominator.first(where: {$0.isNumber(mayBePowered: false)})!})
        let radicals = densNumberNodes.directRadicals
        if radicals.hasPowered {fatalError()}
        return radicals.uniqueRadicals.clone(changeID: true, withParent: false).children
    }
    func getParenthesizedCloneOrFirst() -> StepNode {
        if count == 1 || count == 2 && self[1].isTimes {
            return self.first!.clone(changeID: false, withParent: false)
        } else {
            let brktsNode = StepNode.newBracketsNode
            brktsNode.children = self.clone(changeID: false, withParent: false).children
            return brktsNode
        }
    }
    var hasNonBrackets: Bool {
        contains(where: {!$0.isBrackets})
    }
    var hasNonFraction: Bool {
        contains(where: {!$0.isFraction})
    }
    func matchIDsOfSameStaticID(with nodes: [StepNode], inStepsView: Bool) {
        var tmpMarkedKeys = [StepKey]()
        self.matchIDsOfSameStaticID(with: nodes, markedKeys: &tmpMarkedKeys, inStepsView: inStepsView)
    }
    func matchIDsOfSameStaticID(with nodes: [StepNode], markedKeys: inout [StepKey], inStepsView: Bool) {
        let flatTree = flatTree
        var capturedNodes = [StepNode]()
        for tmpNode in nodes.flatTree {
            if let tmpOtherNode = flatTree.first(where: {$0.staticID == tmpNode.staticID && $0.valueSKpow.keys == tmpNode.valueSKpow.keys}) {
                if !tmpOtherNode.isTerm {
                    capturedNodes.append(tmpOtherNode)
                }
                if tmpNode.op.key == tmpOtherNode.op.key && !tmpNode.op.idIsZero {
                    tmpOtherNode.op = tmpNode.op
                } else if inStepsView && tmpNode.exist && tmpNode.op.key != tmpOtherNode.op.key && tmpNode.isPlus && tmpNode.isFirst {
                    tmpOtherNode.op.id = 1
                }
                markedKeys.append(tmpOtherNode.op)
                tmpOtherNode.valueSK = tmpNode.valueSK
                if tmpOtherNode.isPowered {
                    tmpOtherNode.power.first!.valueSK = tmpNode.power.first!.valueSK
                }
                if let tmpOtherRadicalParent = tmpOtherNode.radicalParent {
                    if let tmpRadicalParent = tmpNode.radicalParent {
                        tmpOtherRadicalParent.op = tmpRadicalParent.op
                        tmpOtherRadicalParent.valueSK = tmpRadicalParent.valueSK
                        tmpOtherRadicalParent.children.replaceSimilarKeys(with: tmpRadicalParent.children.flatSKs, withPow: true)
                    }
                }
            }
        }
        if nodes.isBrackets && nodes.first!.children.isEqualTo(nodes: capturedNodes) && capturedNodes.first!.parent!.isBrackets && !capturedNodes.first!.parent!.valueSK.first!.isHiddenBracket {
            capturedNodes.parent!.valueSK = nodes.first!.valueSK
        }
    }
    func matchNodesIDOfSameStaticID(with nodes: [StepNode]) {
        let flatTree = flatTree
        for tmpNode in nodes.flatTree {
            if let tmpOtherNode = flatTree.first(where: {$0.staticID == tmpNode.staticID && $0.valueSKpow.keys == tmpNode.valueSKpow.keys}) {
                tmpOtherNode.id = tmpNode.id
                if tmpOtherNode.isPowered {
                    tmpOtherNode.power.matchNodesIDOfSameStaticID(with: tmpNode.power)
                }
                if let tmpOtherRadicalParent = tmpOtherNode.radicalParent {
                    if let tmpRadicalParent = tmpNode.radicalParent {
                        tmpOtherRadicalParent.id = tmpRadicalParent.id
                        tmpOtherRadicalParent.children.matchNodesIDOfSameStaticID(with: tmpRadicalParent.children)
                    }
                }
            }
        }
    }
    func matchStaticIDOfFirstEquaSymbs(symbNodes: [StepNode]) {
        for selfSymbNode in self {
            if let firstSameSymbOtherNode = symbNodes.first(where: {$0.isSymbType(type: selfSymbNode.type?.key)}), !hasStaticIDsOverlap(staticIDs: [firstSameSymbOtherNode.staticID])  {
                selfSymbNode.staticID = firstSameSymbOtherNode.staticID
            }
        }
    }
    func replaceSimilarKeys(with flatSKs: [StepKey], withPow: Bool) {
        var flatSKs = flatSKs
        privateReplaceSimilarKeys(with: &flatSKs, withPow: withPow, shouldDropDens: false)
    }
    func replaceSimilarKeys(with flatSKs: [StepKey], denStepExpr: [StepKey], withPow: Bool) {
        var numStepExpr = flatSKs.dropSKs(denStepExpr)
        privateReplaceSimilarKeys(with: &numStepExpr, withPow: withPow, shouldDropDens: true)
        var denStepExpr = denStepExpr
        denominatorChain.privateReplaceSimilarKeys(with: &denStepExpr, withPow: withPow, shouldDropDens: false)
    }
    private func privateReplaceSimilarKeys(with flatSKs: inout [StepKey], withPow: Bool, shouldDropDens: Bool) {
        let overlappingSKs = flatSKs.filter({self.flatSKs.contains($0)})
        flatSKs = flatSKs.dropSKs(overlappingSKs)
        for node in (withPow ? flatTree : flatTreeNoPow) {
            if shouldDropDens && node.baseNode.isInDenominator {continue}
            if !node.isSymb && !overlappingSKs.contains(node.op) {
                node.op.matchToFirstEqualKey(In: &flatSKs)
            }
            if !node.isSqrt && !node.isOneTerm {
                for i in 0..<node.valueSK.count {
                    if !overlappingSKs.contains(node.valueSK[i]) {
                        node.valueSK[i].matchToFirstEqualKey(In: &flatSKs)
                    }
                }
            }
        }
    }
    var directSymbs: [StepNode] {
        map({$0.directSymbs}).flatMap({$0})
    }
    var directTerms: [StepNode] {
        map({$0.directTerms}).flatMap({$0})
    }
    func dropNonTargets(fnCtrl: [FnCtrl]) -> [StepNode] {
        filter({!fnCtrl.targetOnly || $0.isTarget})
    }
    var dropTargets: [StepNode] {
        filter({!$0.isTarget})
    }
    var numeratorsParents: [StepNode] {
        map({$0.numerator.parent!})
    }
    var denominatorsParents: [StepNode] {
        map({$0.denominator.parent!})
    }
    var denominatorsFlat: [StepNode] {
        map({$0.denominator}).flatMap({$0})
    }
    var allWholeOrAllDecimal: Bool {
        !(contains(where: {$0.isWholeNumber(mayBeCoeff: true)}) && contains(where: {$0.isDecimal}))
    }
    var hasOnlyWholeNumbers: Bool {
        !(contains(where: {!$0.isWholeNumber(mayBeCoeff: false)}))
    }
    var hasOnlyWholeNumbersOrVars: Bool {
        allSatisfy({$0.isWholeNumber(mayBeCoeff: false) || $0.hasVarFlat})
    }
    mutating func insertOrAppend(node: StepNode, shouldAppend: Bool) {
        if shouldAppend {
            self.append(node)
        } else {
            self.insert(node, at: 0)
        }
    }
    var hasNegPower: Bool {
        contains(where: {$0.isPowered && $0.power.isMinus})
    }
    func willBeSingle() -> Bool {
        let calcBrain = CalcBrain()
        let nodeClone = clone(changeID: false, withParent: false)
        var fakeSteps = [StepModel()]
        calcBrain.surfAndEvaluateAndApplyFnTillEnd(parent: nodeClone, fnCtrl: [.skipAppendStep, .skipPrintStep], &fakeSteps)
        return nodeClone.children.count == 1
    }
    var highOpChains: [[StepNode]] {
        var tmpNodes = self
        var chians = [[StepNode]]()
        while true {
            chians.append(tmpNodes.first!.highOpChain)
            if chians.last!.last!.isLast {break}
            tmpNodes = [StepNode](tmpNodes.split(separator: chians.last!.last!).last!)
        }
        return chians
    }
    var likelyToBeSingle: Bool {
        if isMulti && contains(where: {$0.hasChild && $0.children.hasTerm}) {return false}
        if contains(where: {$0.isOneTerm && $0.isDivide}) {return false}
        let highOpChains = highOpChains.map({$0.dropMultipliedBrackets.dropFractions})
        let chainsTerms = highOpChains.map({$0.allTerms})
        return !chainsTerms.contains(where: {terms in chainsTerms.contains(where: {!$0.isEqualTo(nodes: terms)})})
    }
    func getResultNodeGeneralRounded(precision: Int) -> StepNode {
        let resultDouble = flatSKs(.dropPlus).keys.getResultValue()
        var roundedResult = resultDouble.operationResultRounded(precision: precision, isError: false)
        let resultStr = String(roundedResult)
        if resultStr.contains(".") {
            let decimalCount = resultStr.split(separator: ".").last!.count
            if decimalCount > (precision-2) {
                roundedResult = roundedResult * pow(10, Double(decimalCount-1))
                roundedResult.round()
                roundedResult = roundedResult/pow(10, Double(decimalCount-1))
            }
        }
        return roundedResult.newNode
    }
    func convertNodesToExpr(flatSKs: inout [StepKey], alwaysShowTimes: Bool, noRoots: Bool, withPows: Bool) {
        if self.isEmpty {return}
        var node: StepNode {self.first!}
        var valueSK: [StepKey] {
            return node.valueSK
        }
        if !((flatSKs.isEmpty || flatSKs.last!.key.isOpenBracket) && node.op.key == .plus) && !(node.hasParent && node.parent!.isSqrt && node.exist && node.op.key != .pow  && node.isFirst && node.op.key == .plus) && (alwaysShowTimes || node.showTimesBeforeBrackets) {
            flatSKs.append(node.op)
        }
        if node.isFraction {
            flatSKs.append(node.numBrackets.first!)
            node.numerator.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
            flatSKs.append(node.numBrackets.last!)
            if node.valueSK.first!.key != .fraction {fatalError()}
            flatSKs.append(node.valueSK.first!)
            flatSKs.append(node.denBrackets.first!)
            node.denominator.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
            flatSKs.append(node.denBrackets.last!)
        } else {
            if node.isBrackets(.any) {
                flatSKs.append(valueSK.first!)
                if node.hasChild {
                    node.children.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
                }
                if node.isBrackets(.complete) {
                    flatSKs.append(valueSK.last!)
                }
            } else if !node.isOneTerm || node.showOneTerm {
                if node.valueSK.keys == [.minus, .one] && node.hasDirectSymbs {
                    flatSKs.append(valueSK.first!)
                } else {
                    flatSKs.append(contentsOf: valueSK)
                }
            }
            if withPows && node.hasPowerParent {
                flatSKs.append(node.powerParent!.op)
                flatSKs.append(node.powerParent!.valueSK.first!)
                node.power.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
                flatSKs.append(node.powerParent!.valueSK.last!)
            }
            
            //
            let showRadBeforeSymbs = node.hasBeforeSymbsRadical
            
            //
            if showRadBeforeSymbs {
                appendRadicalToStepExpr(node: node, flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows, showRadBeforeSymbs: showRadBeforeSymbs)
            }
            if node.hasDirectSymbs {
                for symb in node.directSymbs {
                    if alwaysShowTimes && (!symb.isFirstTerm || !symb.coeffNode.isOneTerm) {
                        flatSKs.append(.times)
                    }
                    flatSKs.append(symb.type ?? symb.valueSK.last!)
                    if withPows && symb.hasPowerParent {
                        flatSKs.append(symb.powerParent!.op)
                        flatSKs.append(symb.powerParent!.valueSK.first!)
                        symb.power.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
                        flatSKs.append(symb.powerParent!.valueSK.last!)
                    }
                }
            }
            if !showRadBeforeSymbs {
                appendRadicalToStepExpr(node: node, flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows, showRadBeforeSymbs: showRadBeforeSymbs)
            }
        }
        [StepNode](self.dropFirst()).convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
    }
    private func appendRadicalToStepExpr(node: StepNode, flatSKs: inout [StepKey], alwaysShowTimes: Bool, noRoots: Bool, withPows: Bool, showRadBeforeSymbs: Bool) {
        if let radicalParent = node.radicalParent {
            if noRoots {
                if !showRadBeforeSymbs || !radicalParent.coeffNode.isOneTerm {
                    flatSKs.append(.times)
                }
                flatSKs.append(.openBracket)
                radicalParent.children.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
                flatSKs.append(.closeBracket)
                flatSKs.append(.pow)
                flatSKs.append(.openBracket)
                flatSKs.append(contentsOf: [.one, .divide] + radicalParent.indexSK)
                flatSKs.append(.closeBracket)
            } else {
                flatSKs.append(radicalParent.op)
                flatSKs.append(contentsOf: radicalParent.indexSK)
                flatSKs.append(radicalParent.radicalBrkts.first!)
                radicalParent.children.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
                flatSKs.append(radicalParent.radicalBrkts.last!)
            }
            if withPows && radicalParent.hasPowerParent {
                flatSKs.append(radicalParent.powerParent!.op)
                flatSKs.append(radicalParent.powerParent!.valueSK.first!)
                radicalParent.power.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
                flatSKs.append(radicalParent.powerParent!.valueSK.last!)
            }
        }
    }
    var staticIDs: [Int32] {
        map({$0.staticIDs}).flatMap({$0})
    }
    var levelStaticIDs: [Int32] {
        map({$0.staticID})
    }
    func hasStaticIDsOverlap(staticIDs: [Int32]) -> Bool {
        contains(where: {$0.hasStaticIDsOverlap(staticIDs: staticIDs)})
    }
    mutating func removeAllSymbs() {
        for node in self.filter({$0.hasDirectSymbs}) {
            node.removeSymbs()
        }
    }
    mutating func removeRadicalParents() {
        for node in self.filter({$0.hasDirectRadical}) {
            node.removeRadical()
        }
    }
    var hasOnlyEmptyFraction: Bool {
        count == 1 && first!.isFraction(.empty(for: .all))
    }
    var isEmptyFractionPart: Bool {
        isEmptyOrSemiEmpty || hasOnlyEmptyFraction
    }
    var hasOnlyWholeNumbersWithOneDivide: Bool {
        count == 2 && last!.isDivide && hasOnlyWholeNumbers
    }
    var symbsAreInSimplestForm: Bool {
        if contains(where: {!$0.isSymb}) {fatalError()}
        for symbNode in self {
            if !symbNode.power.isSimplestForm || self.dropNode(node: symbNode).contains(where: {symbNode.hasEqualBase(with: $0)}) {
                return false
            }
        }
        return true
    }
    var radicalMix: [StepNode] {
        map({[$0] + ($0.hasDirectRadical ? [$0.radicalParent!] : [])}).flatMap({$0})
    }
    var withEachTermExtracted: [StepNode] {
        let newParent = self.clone(changeID: false, withParent: self.count == parent?.children.count)
        for node in newParent.children.filter({$0.isCoeff}) {
            node.extractEachTerm()
        }
        return newParent.children.first!.level!
    }
    func extractEachTerm() {
        for node in self {
            node.extractEachTerm()
        }
    }
    func extractTermsFromEachCoeff() {
        for node in self {
            node.extractTerms()
        }
    }
    var directRadicals: [StepNode] {
        map({($0.hasDirectRadical ? [$0.radicalParent!] : [])}).flatMap({$0})
    }
    var parenthesized: StepNode {
        let newBrkts = StepNode.newBracketsNode
        newBrkts.children = self
        return newBrkts
    }
    var hasConstSymb: Bool {
        first!.isSymb ? contains(where: {$0.isConstSymb}) : contains(where: {$0.hasConstSymb})
    }
    func removeRadicals() {
        for node in self {
            node.removeRadical()
        }
    }
    func removeTimesFromTerms() {
        for node in self.flatTree {
            if node.shouldMergeTermWithPrev {} else {continue}
            node.prev.directSymbs.append(contentsOf: node.directSymbs)
            if let radicalParent = node.radicalParent {
                node.prev.radicalParent = radicalParent
            }
            node.remove()
        }
    }
    func hasRootableOrSimplifiable(indexValue: Double, isNotRootableIfMultiplied: Bool) -> Bool {
        termMix.contains(where: {$0.isRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: isNotRootableIfMultiplied)})
    }
    func hasRootable(indexValue: Double) -> Bool {
        termMix.contains(where: {$0.isRootable(indexValue: indexValue)})
    }
    func hasSimplifiable(indexValue: Double, isNotRootableIfMultiplied: Bool) -> Bool {
        termMix.contains(where: {$0.isSimplifiableRadicand(indexValue: indexValue, isNotRootableIfMultiplied: isNotRootableIfMultiplied)})
    }
    //    func areAllRootablesOrSimplifiables(indexValue: Double) -> Bool {
    //        !contains(where: {!$0.isRootableOrSimplifiable(indexValue: indexValue) || !$0.directTerms.areAllRootablesOrSimplifiables(indexValue: indexValue)})
    //    }
    func areAllRootables(indexValue: Double) -> Bool {
        !contains(where: {!($0.valueIsOne || $0.isRootable(indexValue: indexValue)) || !$0.directTerms.areAllRootables(indexValue: indexValue)})
    }
    var hasSimplifiableWillBeRootableForParentSqrt: Bool {
        if let radicalParent = parent {
            if !radicalParent.isSqrt {fatalError()}
            if hasSimplifiable(indexValue: radicalParent.indexValue, isNotRootableIfMultiplied: true) {
                if let radicalParentParent = radicalParent.coeffNode.parent {
                    if !radicalParentParent.isSqrt {fatalError()}
                    return radicalParentParent.dontHaveRootableAndWillHaveRootableOrSimplifiable
                }
            }
        }
        return false
    }
    var hasDirectRadVar: Bool {
        contains(where: {$0.hasDirectRadVar})
    }
    var hasDirectRadVarOrNotVarX: Bool {
        contains(where: {$0.hasDirectRadVarOrNotVarX})
    }
    var hasDirectRadVarNoPow: Bool {
        contains(where: {$0.hasDirectRadVarNoPow})
    }
    var hasRadVarOrNotVarXFlat: Bool {
        flatTree.hasDirectRadVarOrNotVarX
    }
    var negtaiveCount: Int {
        filter({$0.isNegative}).count
    }
    var minusCount: Int {
        filter({$0.isMinus}).count
    }
    var flatMinusCount: Int {
        flatTreeNoPow.filter({$0.isMinus}).count
    }
    var baseOrTermNode: [StepNode] {
        map({$0.baseOrTermNode})
    }
    var baseNodes: [StepNode] {
        map({$0.baseNode})
    }
    func splitAtEachRadical() {
        for node in self {
            if let radicalParent = node.radicalParent {
                node.splitTermsAt(radicalParent)
            }
        }
    }
    var isSingleNode: Bool {
        count == 1 && first!.isSingleNode
    }
    var isSinglePoweredNode: Bool {
        count == 1 && first!.isSingleNode && first!.baseOrTermNode.isPowered
    }
    func isSingleRootablePowered(indexValue: Double) -> Bool {
        isSingleNode && first!.baseOrTermNode.isPowered && first!.baseOrTermNode.isRootable(indexValue: indexValue)
    }
    //    func areAllRootables(indexValue: Double) -> Bool {
    //        for node in termMix {
    //            if node.isRootable(indexValue: indexValue) {} else {return false}
    //        }
    //        return true
    //    }
    var nodesProducts: [StepNode] {
        map({$0.nodeProduct}).filter({$0 != nil}).map({$0!})
    }
    var nodesProductsOrSelf: [StepNode] {
        map({$0.nodeProduct ?? $0})
    }
    func removeNodesProducts() {
        for node in self {
            node.nodeProduct = nil
        }
    }
    func setTargetToTrue() {
        for node in self {
            node.isTarget = true
        }
    }
    var dropDuplicates: [StepNode] {
        var uniqueNodes = [StepNode]()
        for node in self {
            if !uniqueNodes.containsNode(node) {
                uniqueNodes.append(node)
            }
        }
        return uniqueNodes
    }
    var hasMultiTypesVars: Bool {
        let allSymbsFlat = allSymbsFlat
        if let varType1 = allSymbsFlat.first(where: {$0.isVar})?.type?.key {
            return allSymbsFlat.contains(where: {$0.isVar && $0.type?.key != varType1})
        }
        return false
    }
    var hasRadicalNotSimplestFlat: Bool {
        flatTree.contains(where: {$0.hasDirectRadical && !$0.radicalParent!.isSimplestRadical})
    }
    var dropMinus: [StepNode] {
        [first!.withOp(.plus)] + self.dropFirst
    }
    var cloneWithChangedStaticIDs: [StepNode] {
        let newRoot = StepNode()
        newRoot.children = map({$0.cloneWithChangedStaticIDs})
        return newRoot.children
    }
    var conjugate: [StepNode] {
        if count == 2 && isSimplestForm {} else {fatalError()}
        let clones = cloneWithChangedStaticIDs
        clones.last!.op.flipSign()
        return clones
    }
    var onlyTwoToThreeSimplestBrkts: [StepNode] {
        filter({$0.op.key != .sqrt && $0.isBrackets(.simplest) && 2...3 ~= $0.children.count && (!$0.isPowered || $0.power.isWholeNumber(mayBeCoeff: false) && $0.powerValue < 3)})
    }
    var firstEqualBases: [StepNode]? {
        for node in self {
            if node.hasEqualBase(in: self) {
                return filter({$0.hasEqualBase(with: node)})
            }
        }
        return nil
    }
    var powerSum: Double {
        map({$0.powerValue}).reduce(0, +)
    }
    var dropTerms: [StepNode] {
        map({$0.dropTerms})
    }
    var dropSqrtOpValue: [StepNode] {
        let clone = clone(changeID: false, withParent: false)
        for node in clone.children {
            if let radicalParent = node.radicalParent {
                var fakeMarkedKeys = [StepKey]()
                radicalParent.extractRadicalContent(markedKeys: &fakeMarkedKeys)
            }
        }
        return clone.children
    }
    var isPosSimplestFraction: Bool {
        isFraction && !first!.isReducibleFraction && isPlus && first!.denominator.isWholeNumber(mayBeCoeff: false) && first!.denominator.first!.valueSK.count <= 2
    }
    func removePowers() {
        for node in self {
            node.removePower()
            directTerms.removePowers()
        }
    }
    var firstOrSelftAfterSetBrackets: StepNode {
        if count == 1 {
           return first!
        } else {
            setBrackets()
            return first!.parent!
        }
    }
    var reoderedWithDecimalsFirst: [StepNode] {
        filter({$0.isDecimal}) + filter({!$0.isDecimal})
    }
    func dropFirst(_ condition: Bool) -> [StepNode] {
        condition ? self.dropFirst : self
    }
    var hasNestedFraction: Bool {
        contains(where: {$0.isFraction(.hasFraction)})
    }
    func getMarkedNodes(markedKeys: [StepKey]) -> [StepNode] {
        let cloneNodes = self.clone(changeID: false, withParent: true).children
        cloneNodes.setFirstTermsNodeProductsToComma()
        let withEachTermExtracted = markedKeys.first!.key == .dot && !self.dropTerms.flatSKs.overlaps(with: markedKeys.dropOps) && self.directTerms.opValuesSK(.any).overlaps(with: markedKeys) ? cloneNodes : withEachTermExtracted
        let filteredEachExtractedParent = withEachTermExtracted.filter({$0.flatSKs.overlaps(with: markedKeys)}).clone(changeID: false, withParent: false)
        for node in filteredEachExtractedParent.children {
            if filteredEachExtractedParent.children.count == 1 {
                if !node.baseOrTermNode.power.flatSKs.overlaps(with: markedKeys) {
                    node.baseOrTermNode.removePower()
                }
            }
            if node.isNumber(mayBePowered: true) && !node.isOneTerm && !node.valueSK.overlaps(with: markedKeys) {
                node.valueSK = [.one]
                node.staticID = Int32.random
            }
            if node.isFirst && (node.isMinus || node.op.key == .plusMinus) && !markedKeys.contains(node.op) {
                node.op = .plus
            }
            if node.hasDirectSymbs {
                node.directTerms.filter({!$0.flatSKs.overlaps(with: markedKeys)}).removeNodesFromParent()
            }
        }
        filteredEachExtractedParent.children.setFirstTermsNodeProductsToCommaFrom(nodes: cloneNodes)
        filteredEachExtractedParent.children.removeTimesFromTerms()
        filteredEachExtractedParent.children.matchNodesIDOfSameStaticID(with: self)
        return filteredEachExtractedParent.children
    }
    func setFirstTermsNodeProductsToComma() {
        for termNode in allTerms {
            if !termNode.isFirstTerm {
                termNode.nodeProduct = .commaNode
            }
        }
    }
    func setFirstTermsNodeProductsToCommaFrom(nodes: [StepNode]) {
        for termNode in allTerms {
            if nodes.allTerms.filter({$0.nodeProduct?.isCommaNode ?? false}).map({$0.staticID}).contains(termNode.staticID) {
                termNode.nodeProduct = .commaNode
            }
        }
    }
    var nodesHaveEqualValues: Bool {
        let values = map({$0.valueDouble})
        return values.dropFirst().allSatisfy({$0 == values.first!})
    }
    var valuesHaveCommonFactor: Bool {
        map({$0.valueDouble}).gcd != 1
    }
    var isMultiNoHighOpChain: Bool {
        count > 1 && !getOps.contains(where: {$0.key.isHighOp})
    }
    var isMultiNotHighOpChain: Bool {
        count > 1 && getOps.dropFirstIfPlus.contains(where: {$0.key.isPlusOrMinus})
    }
    var hasRepeatedSymbType: Bool {
        let allSymbsTypes = allSymbs.map({$0.type?.key})
        return Set(allSymbsTypes).count != allSymbsTypes.count
    }
    var mayBeUndefinable: Bool {
        if isHighOpChainOrSimplestForm {} else {return true}
        if contains(where: {$0.valueIsZero && $0.isDivide}) || hasFraction(part: .denominator, {$0.contains(where: {$0.valueIsZero})}) {return true}
        if hasFraction(part: .any, {$0.mayBeUndefinable}) || contains(where: {$0.isBrackets && $0.children.mayBeUndefinable}) || hasRadicalMayBeUndefinable {return true}
        if hasPoweredByNotPosConst || allTerms.hasPoweredByNotPosConst {return true}
        return false
    }
    var exprCharsWidth: Double {
        map({$0.exprCharsWidth}).reduce(0, +)
    }
    func dropRedundants(ignoreOp: Bool) -> [StepNode] {
        var existingNodes = [StepNode]()
        for node in self {
            if existingNodes.contains(where: {ignoreOp ? $0.flatSKs(.dropOp).keys == node.flatSKs(.dropOp).keys : $0.flatKeys == node.flatKeys}) {continue}
            existingNodes.append(node)
        }
        return existingNodes
    }
    func dropRedundantNodes() -> [StepNode] {
        var existingNodes = [StepNode]()
        for node in self {
            if existingNodes.containsNode(node) {continue}
            existingNodes.append(node)
        }
        return existingNodes
    }
    mutating func removeRedundants(ignoreOp: Bool) {
        self = dropRedundants(ignoreOp: ignoreOp)
    }
    mutating func removeSameBaseWithLowerExp() {
        var existingNodes = [StepNode]()
        for node in self {
            if existingNodes.contains(where: {$0.hasEqualBase(with: node) && node.powerValue > $0.powerValue}) {
                existingNodes.removeAll(where: {$0.hasEqualBase(with: node)})
            } else if existingNodes.contains(where: {$0.hasEqualBase(with: node) && node.powerValue < $0.powerValue}) {continue}
            existingNodes.append(node)
        }
        self = existingNodes
    }
    var degreeReordered: [StepNode] {
        
        //
        if isSimplestForm {} else {fatalError()}
        if getCommonVars.isEmpty && hasMultiTypesVars {return self}
        if count < 2 || !hasVarFlat {return self}
        
        //
        let calcBrain = CalcBrain()
        let newParent = parent!.clone(changeID: false, withParent: false)
        calcBrain.bubbleSortDegrees(parent: newParent)
        return newParent.children
    }
    var areDegreeOrdered: Bool {
        flatKeys == degreeReordered.flatKeys
    }
    func firstNodes(_ nodesCount: Int) -> [StepNode] {
        [StepNode](self[0...nodesCount-1])
    }
    func lastNodes(_ nodesCount: Int) -> [StepNode] {
        [StepNode](self[count-nodesCount...count-1])
    }
    var withCommonFactorExtracted: [StepNode]? {
        let calcBrain = CalcBrain()
        let nodesClones = clone(changeID: false, withParent: false).children
        let brktNode = StepNode.newBracketsNode.withChildren(children: nodesClones)
        let newRoot = StepNode()
        newRoot.children = [brktNode]
        var fakeSteps = [StepModel()]
        brktNode.pinRootExpr()
        calcBrain.extractCommonFactor(brktNode: brktNode, fnCtrl: [.skipPrintStep], &fakeSteps)
        return brktNode.pinnedRootDidChange ? brktNode.children : nil
    }
    func getResult(subtitutes: [[Key]], allowNegEvenRoot: Bool) -> Double? {
        flatSKs(.dropPlus).keys.getResult(subtitutes: subtitutes, allowNegEvenRoot: allowNegEvenRoot)
    }
    func replace(with nodes: [StepNode]) {
        last!.insertAfter(contentsOf: nodes)
        self.removeNodesFromParent()
    }
    var typesKeys: [Key] {
        if contains(where: {$0.type == nil}) {return []}
        return map{$0.type!}.keys
    }
    var types: [StepKey] {
        if contains(where: {$0.type == nil}) {return []}
        return map{$0.type!}
    }
    var powerValues: [Double] {
        map({$0.powerValue})
    }
    var expoFormsOrSelf: [StepNode] {
        map({$0.expoFormOrSelf})
    }
    func firstHasSameStaticID(with node: StepNode) -> StepNode? {
        first(where: {$0.staticID == node.staticID})
    }
    var hasRootableRadicand: Bool {
        contains(where: {$0.children.hasRootable(indexValue: $0.indexValue)})
    }
    var shouldMoveAllToSide: Bool {
        if let firstVarNode = first(where: {$0.isVar}) {
            return firstVarNode.powerResult > 2 || dropNode(node: firstVarNode).onlyVars.contains(where: {!$0.isEqualTo(node: firstVarNode)})
        }
        return false
    }
    func setInRoot(ofIndex: Double) {
        let oneRadicalNode = StepNode.newOneNodeWithSqrt(indexSK: ofIndex.newSKs)
        last!.insertAfter(oneRadicalNode)
        self.removeNodesFromParent()
        oneRadicalNode.radicalParent!.children = self
    }
    var withRepCount: [StepNode] {
        var repKeys = [Key]()
        for node in self {
            node.setRepCount(repKeys: &repKeys)
        }
        return self
    }
    var undefinedNodesStrWithAnd: String {
        if count == 1 {
            return first!.children.flatSKs(.dropPlus).dropHiddens.strForExpl
        } else {
            return String(dropLast.map({$0.children.flatSKs(.dropPlus).dropHiddens.strForExpl + ", "}).flatMap({$0}).dropLast(2)) + " and " + last!.children.flatSKs(.dropPlus).dropHiddens.strForExpl
        }
    }
    var undefinedNodesStrWithOr: String {
        if isEmpty {
            return ""
        } else if count == 1 {
            return first!.children.flatSKs(.dropPlus).dropHiddens.strForExpl
        } else {
            return String(dropLast.map({$0.children.flatSKs(.dropPlus).dropHiddens.strForExpl + ", "}).flatMap({$0}).dropLast(2)) + " or " + last!.children.flatSKs(.dropPlus).dropHiddens.strForExpl
        }
    }
    var undefinedNodesAsSetStr: String {
        String(map({$0.children.flatSKs(.dropPlus).dropHiddens.strForExpl + ", "}).flatMap({$0}).dropLast(2))
    }
    var hasMultiVarFlat: Bool {
        let allSymbsFlat = allSymbsFlat
        var existingVarTypes = [Key]()
        for varType in Key.allSymbTypes.filter({$0.isVar}) {
            if allSymbsFlat.contains(where: {$0.type?.key == varType}) {
                existingVarTypes.append(varType)
                continue
            }
        }
        return existingVarTypes.count > 1
    }
    var getDegree: Int {
        Int(allSymbsFlat.onlyVars.powerValues.max()!)
    }
    var areAllMultiplied: Bool {
        !contains(where: {!$0.isMultiplied})
    }
    func dropNodesWith(staticIDs: [Int32]) -> [StepNode] {
        filter({!staticIDs.contains($0.staticID)})
    }
    var extractLCMvalue: Double {
        let densValue = filter({$0.denominator.isMultChain && $0.denominator.hasNumber(mayBePowered: false)}).map({Int($0.denominator.first(where: {$0.isNumber(mayBePowered: false)})!.valueDouble)})
        return Double(densValue.lcm)
    }
    var getLCMNodes: [StepNode] {
        if hasNonFraction || isEmpty {return []}
        var lcmNodes = [StepNode]()
        var firstNode = StepNode()
        if contains(where: {$0.denominator.isMultChain && $0.denominator.hasNumber(mayBePowered: false)}) {
            let valueLCM = extractLCMvalue
            let symbsLCM = denominatorChain.onlyNumbers.symbsLCM
            let radicalsLCM = radicalsLCM
            firstNode = valueLCM.newNode
            firstNode.directSymbs = symbsLCM
            firstNode.radicalParent = radicalsLCM.first ?? nil
            lcmNodes = [firstNode]
            if radicalsLCM.count > 1 {
                lcmNodes.append(contentsOf: radicalsLCM.dropFirst.map({.newOneNode.withRadical(radical: $0).withOp(.times)}))
            }
        }
        if contains(where: {$0.denominator.count > 1 || $0.denominator.isBrackets}) {
            //
            let fractionsClones = cloneWithChangedStaticIDs
            // Set LCM Content Array
            lcmNodes.append(contentsOf: fractionsClones.denominatorChain.dropNumbers(mayBePowered: false).map({$0.withOp(.times)}))
            lcmNodes.replaceHiddenBrktsWithRegBrkts()
            // Remove Redundancy
            lcmNodes.removeRedundants(ignoreOp: true)
            lcmNodes.removeSameBaseWithLowerExp()
            let lcmNodesRoot = StepNode()
            lcmNodesRoot.children = lcmNodes
            lcmNodesRoot.children.op = .plus
            //
            lcmNodes = lcmNodesRoot.children
        }
        return lcmNodes
    }
    func replaceHiddenBrktsWithRegBrkts() {
        for hiddenBrktNode in self.filter({$0.valueSK.first!.isHiddenBracket}) {
            hiddenBrktNode.valueSK[0] = .openBracket
            hiddenBrktNode.valueSK[1] = .closeBracket
        }
    }
    func reorderChildrensToBeTheSame() {
        if count < 2 || hasNonBrackets || contains(where: {$0.children.count < 2}) {fatalError()}
        let orderedNodes = first!.children
        for parent in dropFirst {
            parent.children.reorderToMatch(orderedNodes: orderedNodes)
        }
    }
    mutating func reorderToMatch(orderedNodes: [StepNode]) { 
        var toReorderNodes = [StepNode]()
        for node in orderedNodes {
            while let firstEqualBase = first(where: {$0.hasEqualBase(with: node) && !toReorderNodes.contains($0)}) {
                toReorderNodes.append(firstEqualBase)
            }
        }
        self = self.dropNodes(nodes: toReorderNodes) + toReorderNodes
    }
    func setAllOpsToTimesAndFirstToPlus() {
        for node in self {
            node.op.key = .times
        }
        first!.op.key = .plus
    }
    var isSmplstFormOrMultChainOrIs4TermsFactorable: Bool {
        isSimplestFormMulti || isMultChain || is4TermsFactorable
    }
    var is4TermsFactorable: Bool {
        let highOpChains = highOpChains
        if highOpChains.count > 1 && !highOpChains.contains(where: {!($0.onlyBrackets.count == 1 && $0.dropBrackets.count <= 1 && $0.hasOnlyTimes)}) {} else {return false}
        guard let firstBrackets = first(where: {$0.isBrackets({$0.isSimplestFormMulti})}) else {return false}
        if onlyBrackets.dropNode(node: firstBrackets).contains(where: {!$0.children.isEqualTo(nodes: firstBrackets.children) || !$0.power.isEqualTo(nodes: firstBrackets.power)}) {return false}
        return true
    }
    var hasDuplicateStaticIDs: Bool {
        contains(where: {node in dropNode(node: node).staticIDs.contains(node.staticID)})
    }
    func changeStaticIDsForStepIncrement() {
        for node in self {
            node.changeStaticIDForStepIncrement()
        }
    }
    func changeStaticIDs() {
        for node in self {
            node.changeStaticIDWithChildren()
        }
    }
    var hasLongDecimal: Bool {
        contains(where: {
            guard $0.isDecimal else {return false}
            let splittedValueKeys = $0.valueKeys.split(separator: .dot)
            guard splittedValueKeys.count == 2 else {return false}
            return splittedValueKeys.last!.count > 12
        })
    }
    func orderedToMatch(nodes: [StepNode]) -> [StepNode] {
        var orderedNodes = [StepNode]()
        for node in nodes {
            orderedNodes.append(self.first(where: {$0.isEqualTo(node: node)})!)
        }
        return orderedNodes
    }
    func hideOneTerms() {
        for node in flatTree {
            node.showOneTerm = false
        }
    }
    var allNotVarXReplacedWithX: [StepNode] {
        let newNodes = clones(changeID: false, withParent: false)
        for node in newNodes.allSymbsFlat {
            if node.isSymbType(type: .notVarX) {
                if let valueKeyNotVarXIdx = node.valueSK.firstIndex(where: {$0.key == .notVarX}) {
                    node.valueSK[valueKeyNotVarXIdx].key = .x
                }
            }
        }
        return newNodes
    }
    var assymptotesValues: [Double] {
        assymptotesFromRadVarsValues
    }
    private var assymptotesFromRadVarsValues: [Double] {
        var tmpFlatTree = flatTree
        var values = [Double]()
        while let radVarNode = tmpFlatTree.first(where: {$0.hasDirectRadVarOrNotVarX})?.radicalParent {
            tmpFlatTree.removeAll(where: {$0.isEqualWithID(to: radVarNode.coeffNode)})
            let radVarAssymptoteValues = radVarNode.radVarAssymptoteValues
            if radVarAssymptoteValues.isEmpty {return []}
            values.append(contentsOf: radVarAssymptoteValues)
        }
        return values
    }
    func getY(from x: Double) -> Double? {
        guard let xKeys = x.keys else {return nil}
        return getResult(subtitutes: [xKeys], allowNegEvenRoot: false)
    }
    var hasNegPoweredByVar: Bool {
        contains(where: {$0.isPowered && $0.power.hasVarOrNotVarXFlat && $0.isBrackets({!$0.hasVarOrNotVarXFlat && $0.resultValue()<0})})
    }
    var dropHasVar: [StepNode] {
        filter({!$0.hasVarFlat})
    }
    var onlyHasVar: [StepNode] {
        filter({$0.hasVarFlat})
    }
    var clonesInBrackets: StepNode {
        let newBrktNode = StepNode.newBracketsNode
        newBrktNode.children = clones(changeID: false, withParent: false)
        return newBrktNode
    }
    mutating func appendSymb(newSK: StepKey) -> Bool {
        if isEmpty {
            append(StepNode(op: .plus))
        } else if last!.isBrackets || last!.isFraction {
            append(StepNode(op: .times.withID(0)))
        }
        let lastNode = last!
        if lastNode.directSymbs.contains(where: {!$0.isSymb}) {return false}
        if lastNode.valueSK.isEmpty || lastNode.valueKeys == [.minus] {
            lastNode.valueSK.append(.one)
            lastNode.directSymbs.append(.newSymbNode(type: newSK))
        } else if !lastNode.hasBeforeSymbsRadical && lastNode.valueIsOne && !lastNode.hasDirectSymbs {
            lastNode.directSymbs.append(.newSymbNode(type: newSK))
            lastNode.showOneTerm = true
        } else if lastNode.isNumber(mayBePowered: true) || lastNode.isBrackets(.singleNeg(mayBePowered: true)) {
            lastNode.directSymbs.append(.newSymbNode(type: newSK))
        } else {
            return false
        }
        return true
    }
}
