//
//  StepNode.swift
//  Hulul
//
//  Created by Ahmad on 21/02/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

final class StepNode: Equatable {
    
    static func == (lhs: StepNode, rhs: StepNode) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id = Int32.random
    var valueSK: [StepKey]
    var valueKeys: [Key] {
        get {valueSK.keys}
        set {
            valueSK = newValue.newSKs
        }
    }
    var op: StepKey
    
    var allTerms: [StepNode] {
        allRadicals + allSymbs
    }
    var allRadicals: [StepNode] {
        if let radicalParent = radicalParent {
            return [radicalParent]
        } else if hasChild {
            return children.allRadicals
        }
        return []
    }
    var allRadicalsFlat: [StepNode] {
        flatTree.filter({$0.isSqrt})
    }
    var allSymbs: [StepNode] {
        if isRoot {return children.allSymbs}
        if isNumber(mayBePowered: true) {return children} else {
            if isFraction {
                return numerator.map({$0.allSymbs}).flatMap({$0})
            } else {
                return children.map({$0.allSymbs}).flatMap({$0})
            }
        }
    }
    var allSymbsFlat: [StepNode] {
        if isNumber(mayBePowered: true) {return children + (radicalParent?.allSymbsFlat ?? [])} else {return children.map({$0.allSymbsFlat}).flatMap({$0})}
    }
    var directSymbs: [StepNode] {
        get {
            if isNumber(mayBePowered: true) || isBrackets(.singleNeg(mayBePowered: true)) {
                return dynamicNode.children
            } else {
                return []
            }
        }
        set {
            if isNumber(mayBePowered: true) || isBrackets(.singleNeg(mayBePowered: true)) {
                return dynamicNode.children = newValue
            } else {fatalError()}
        }
    }
    var allVars: [StepNode] {
        allSymbs.onlyVars
    }
    var directVars: [StepNode] {
        if !isNumber(mayBePowered: true) {return []}
        return directSymbs.filter({$0.isVar})
    }
    var directVar: StepNode? {
        if !isNumber(mayBePowered: true) {fatalError()}
        let directVars = directSymbs.filter({$0.isVar})
        if directVars.count > 1 {fatalError()}
        return directVars.first
    }
    var directI: StepNode? {
        if !isNumber(mayBePowered: true) {fatalError()}
        let directIs = directSymbs.filter({$0.type?.key == .imaginary})
        if directIs.count > 1 {fatalError()}
        return directIs.first
    }
    var directTerms: [StepNode] {
        if let radicalParent = radicalParent {
            return radicalParent.isBeforeSymbs ? [radicalParent] + directSymbs : directSymbs + [radicalParent]
        }
        return directSymbs
    }
    var coeffNode: StepNode {
        if !isTerm {fatalError()}
        return parent!
    }
    var baseNode: StepNode {
        if isTerm {
            return coeffNode
        } else if op.key == .pow {
            return parent!.baseNode
        } else {
            return self
        }
    }
    var baseNodeIfTerm: StepNode {
        if isTerm {
            return coeffNode
        } else {
            return self
        }
    }
    var baseOrTermNode: StepNode {
        if isTerm {fatalError()}
        if isOneTerm {return firstTerm!}
        return self
    }
    var baseOrTermNodeOrSelfTerm: StepNode {
        if isTerm {return self}
        if isOneTerm {return firstTerm!}
        return self
    }
    var dynamicNode: StepNode {
        if isBrackets(.single(mayBePowered: true)) {
            return children.first!
        } else {
            return self
        }
    }
    
    // Power
    var powerParent: StepNode? {
        didSet {
            if let powerParent = powerParent {
                powerParent.parent = self
            }
        }
    }
    var power: [StepNode] {
        get {
            if let parent = powerParent {
                return parent.children
            } else {
                return []
            }
        }
        set {
            if let parent = powerParent {
                parent.children = newValue
            } else {
                powerParent = StepNode(op: .pow, valueSK: [.openSquareBrkt, .closeSquareBrkt])
                powerParent!.parent = self
                powerParent!.children = newValue
            }
        }
    }
    var powerOrOne: [StepNode] {
        power.isEmpty ? [.newOneNode] : power
    }
    
    // Sqrt
    var radicalParent: StepNode? {
        didSet {
            if let radicalParent = radicalParent {
                radicalParent.parent = self
            }
        }
    }
    var radicalBrkts: [StepKey] {
        if !isSqrt {fatalError()}
        return [StepKey](valueSK.filter({$0.key.isSquareBrkt}))
    }
    var indexSK: [StepKey] {
        get {
            if !isSqrt {fatalError()}
            return valueSK.onlyNumbersOrOpenCurlyBrkt
        }
        set {
            if !isSqrt {fatalError()}
            valueSK.removeAll(where: {$0.key.isNumber || $0.key == .openCurlyBrkt})
            valueSK.insert(contentsOf: newValue, at: valueSK.firstIndex(where: {!$0.key.isCommaOrDot})!)
        }
    }
    var opIndex: [StepKey] {
        [op] + indexSK
    }
    var indexValue: Double {
        indexSK.getDouble
    }
    var indexInt: Int {
        indexSK.getInt
    }
    var indexIsEven: Bool {
        indexInt.isEven
    }
    var indexIsTwo: Bool {
        indexInt == 2
    }
    var isBeforeSymbs: Bool {
        if !isSqrt {fatalError()}
        return !valueSK.keys.contains(.dot) || !coeffNode.hasDirectSymbs
    }
    var isAfterSymbs: Bool {
        get {
            if !isSqrt {fatalError()}
            return valueSK.keys.contains(.dot)
        }
        set {
            if newValue {
                if !valueSK.keys.contains(.dot) {
                    valueSK.insert(.dot, at: 0)
                }
            } else {
                valueSK.removeAll(where: {$0.key == .dot})
            }
        }
    }
    var parent: StepNode?
    private var privateOtherSide: StepNode?
    var otherSide: StepNode {
        get {
            if root.privateOtherSide == nil {
                return StepNode()
            } else {
                return root.privateOtherSide!
            }
        }
        set {root.privateOtherSide = newValue}
    }
    private var privateIsLeft = true
    var isLeft: Bool {
        get {root.privateIsLeft}
        set {root.privateIsLeft = newValue}
    }
    
    /// Is static throughout node clones
    var staticID: Int32
    func changeStaticIDWithChildren() {
        self.staticID = Int32.random
        for child in children {
            child.changeStaticIDWithChildren()
        }
        for powNode in power {
            powNode.changeStaticIDWithChildren()
        }
        if let radicalParent = radicalParent {
            radicalParent.changeStaticIDWithChildren()
        }
    }
    
    var staticIDForStepIncrement: Int32
    
    private var privateIsSurfed = false
    var isSurfed: Bool {
        get {return forceStop || !exist || privateIsSurfed}
        set {privateIsSurfed = newValue}
    }
    var isReduced = false
    private var privateIsTarget = false
    var isTarget: Bool {
        get {return privateIsTarget}
        set {
            privateIsTarget = newValue
            if hasChild {
                for node in children {
                    node.isTarget = newValue
                }
            }
        }
    }
    var children = [StepNode]() {
        didSet {
            for child in children {
                if (child.parent == nil || child.parent! != self) && !oldValue.contains(child) {
                    child.parent = self
                }
            }
        }
    }
    var nodeProduct: StepNode?

    private var privateResultCase = ResultCase.none
    var resultCase: ResultCase {
        get {root.privateResultCase}
        set {root.privateResultCase = newValue}
    }
    
    var isUndefined: Bool {
        get {resultCase == .undefined}
        set {resultCase = newValue ? .undefined : .none}
    }
    
    var isIncomplete: Bool {
        get {resultCase == .incomplete}
        set {resultCase = newValue ? .incomplete : .none}
    }
    
    var shouldBeUnableToSolve: Bool {
        !isUndefined && (resultCase == .none && isEquation && (children.hasMultiVarFlat || otherSide.hasVarFlat) || allNodes.hasFractionPowWithDDDFlat || allNodes.hasDirectDoubleRadicalFlat || allNodes.hasNestedFraction || allNodes.hasPoweredRadWithFraction)
    }
    
    var showOneTerm: Bool {
        get {
            firstTerm?.valueKeys.first!.isComma ?? false
        }
        set {
            if let firstTerm = firstTerm {
                if newValue {
                    firstTerm.valueSK.insert(.comma, at: 0)
                } else if firstTerm.valueKeys.first!.isComma {
                    firstTerm.valueSK.removeFirst()
                }
            } else {}
        }
    }
    
    init() {
        valueSK = [StepKey]()
        op = .plus
        staticID = id
        staticIDForStepIncrement = id
    }
    init(valueSK: [StepKey]) {
        op = .plus
        self.valueSK = valueSK
        staticID = id
        staticIDForStepIncrement = id
    }
    init(valueKeys: [Key]) {
        op = .plus
        self.valueSK = valueKeys.newSKs
        staticID = id
        staticIDForStepIncrement = id
    }
    init(op: StepKey) {
        self.op = op
        valueSK = [StepKey]()
        staticID = id
        staticIDForStepIncrement = id
    }
    init(opKey: Key) {
        self.op = .stepKey(opKey)
        valueSK = [StepKey]()
        staticID = id
        staticIDForStepIncrement = id
    }
    init(op: StepKey, valueSK: [StepKey]) {
        self.op = op
        self.valueSK = valueSK
        staticID = id
        staticIDForStepIncrement = id
    }
    init(opKey: Key, valueKeys: [Key]) {
        self.op = .stepKey(opKey)
        self.valueSK = valueKeys.newSKs
        staticID = id
        staticIDForStepIncrement = id
    }
    
    var content: (op: StepKey, valueSK: [StepKey], powerParent: StepNode?, radicalParent: StepNode?, children: [StepNode]) {
        get {return (op, valueSK, powerParent, radicalParent, children)}
        set {
            op = newValue.op
            valueSK = newValue.valueSK
            powerParent = newValue.powerParent?.clone(changeID: false, withParent: false)
            radicalParent = newValue.radicalParent?.clone(changeID: false, withParent: false)
            if let powerParent = powerParent {
                powerParent.parent = self
            }
            if let radicalParent = radicalParent {
                radicalParent.parent = self
            }
            children.removeAll()
            if !newValue.children.isEmpty {
                for child in newValue.children {
                    let newNode = StepNode()
                    newNode.staticID = child.staticID
                    newNode.content = child.content
                    children.append(newNode)
                }
            }
        }
    }
    var contentForStepInc: (op: StepKey, valueSK: [StepKey], powerParent: StepNode?, radicalParent: StepNode?, children: [StepNode]) {
        get {return (op, valueSK, powerParent, radicalParent, children)}
        set {
            op = newValue.op
            valueSK = newValue.valueSK
            powerParent = newValue.powerParent?.cloneForStepIncrement
            radicalParent = newValue.radicalParent?.cloneForStepIncrement
            if let powerParent = powerParent {
                powerParent.parent = self
            }
            if let radicalParent = radicalParent {
                radicalParent.parent = self
            }
            children.removeAll()
            if !newValue.children.isEmpty {
                for child in newValue.children {
                    let newNode = StepNode()
                    newNode.staticIDForStepIncrement = child.staticIDForStepIncrement
                    newNode.staticID = child.staticID
                    newNode.content = child.content
                    children.append(newNode)
                }
            }
        }
    }
    private var pinnedExprs = [[Key]]()
}

// MARK: Pin Expr
extension StepNode {
    func pinRootExpr() {
        root.pinnedExprs.append(rootFlatKeys)
    }
    var pinnedRootDidChange: Bool {
        let lastPinnedExpr = root.pinnedExprs.last!
        root.pinnedExprs.removeLast()
        return lastPinnedExpr != rootFlatKeys
    }
}

// MARK: Clone
extension StepNode {
    var cloneForStepIncrement: StepNode {
        clone(changeID: false, withParent: false, preserveStaticIDForStepInc: true)
    }
    func clone(changeID: Bool, withParent: Bool) -> StepNode {
        clone(changeID: changeID, withParent: withParent, preserveStaticIDForStepInc: false)
    }
    private func clone(changeID: Bool, withParent: Bool, preserveStaticIDForStepInc: Bool) -> StepNode {
        let cloneNode = StepNode()
        cloneNode.staticID = staticID
        cloneNode.isLeft = isLeft
        cloneNode.otherSide = otherSide
        if preserveStaticIDForStepInc {
            cloneNode.staticIDForStepIncrement = staticIDForStepIncrement
        }
        clonePrivate(newNode: cloneNode, node: changeID ? self.withChangedIDs(withParent: withParent) : self, changeID: changeID, preserveStaticIDForStepInc: preserveStaticIDForStepInc)
        if let parent = parent, withParent {
            if cloneNode.op.key == .pow {
                let newParent = parent.clone(changeID: changeID, withParent: withParent, preserveStaticIDForStepInc: preserveStaticIDForStepInc)
                newParent.powerParent = cloneNode
                cloneNode.parent = newParent
            } else if cloneNode.op.key == .sqrt {
                let newParent = parent.clone(changeID: changeID, withParent: withParent, preserveStaticIDForStepInc: preserveStaticIDForStepInc)
                newParent.radicalParent = cloneNode
                cloneNode.parent = newParent
            } else {
                let nodeIdx = parent.children.firstIndex(where: {$0.id == self.id})!
                let newParent = parent.clone(changeID: changeID, withParent: withParent, preserveStaticIDForStepInc: preserveStaticIDForStepInc)
                newParent.children[nodeIdx] = cloneNode
                cloneNode.parent = newParent
            }
        }
        return cloneNode
    }
    private func clonePrivate(newNode: StepNode, node: StepNode, changeID: Bool, preserveStaticIDForStepInc: Bool) {
        if preserveStaticIDForStepInc {
            newNode.contentForStepInc = node.contentForStepInc
        } else {
            newNode.content = node.content
        }
        var newChildren = [StepNode]()
        for childNode in node.children {
            let newChild = StepNode()
            newChild.staticID = childNode.staticID
            if preserveStaticIDForStepInc {
                newChild.staticIDForStepIncrement = childNode.staticIDForStepIncrement
            }
            if childNode.hasChild {
                clonePrivate(newNode: newChild, node: childNode, changeID: changeID, preserveStaticIDForStepInc: preserveStaticIDForStepInc)
            } else {
                if preserveStaticIDForStepInc {
                    newChild.contentForStepInc = childNode.contentForStepInc
                } else {
                    newChild.content = childNode.content
                }
                if changeID {
                    newChild.changeIDs()
                }
            }
            newChild.parent = newNode
            newChildren.append(newChild)
        }
        newNode.children = newChildren
        if changeID {
            newNode.changeIDs()
        }
    }
}

// MARK: Get Expr
extension StepNode {
    enum OpPrintCase {
        case any, dropPlus, dropPlusNotPlusMinus, onlyMinus, onlyTimes, onlyPlusOrMinus, dropOp
    }
    
    var opValueSK: [StepKey] {
        get {
            [op] + valueSK
        }
        set {
            if !newValue.first!.key.isOp {fatalError()}
            op = newValue.first!
            valueSK = newValue.dropFirst
        }
    }
    
    func opValueSK(_ opCase: OpPrintCase) -> [StepKey] {
        switch opCase {
        case .any:
            return [op] + valueSK
        case .dropPlus:
            return (isPlus ? [] : [op]) + valueSK
        case .dropPlusNotPlusMinus:
            return (isPlusNotPlusMinus ? [] : [op]) + valueSK
        case .onlyMinus:
            return (!isMinus ? [] : [op]) + valueSK
        case .onlyTimes:
            return (!isTimes ? [] : [op]) + valueSK
        case .onlyPlusOrMinus:
            return (isPlus || isMinus ? [op] : []) + valueSK
        case .dropOp:
            return (!isSqrt ? [] : [op]) + valueSK
        }
    }
    
    var valueSKpow: [StepKey] {
        valueSK + [.pow] + power.flatSKs(.dropPlus)
    }
    
    func valueSKpow(_ opCase: OpPrintCase) -> [StepKey] {
        var tmpOp: [StepKey] {
            switch opCase {
            case .any:
                return [op]
            case .dropPlus:
                return isPlus ? [] : [op]
            case .dropPlusNotPlusMinus:
                return isPlusNotPlusMinus ? [] : [op]
            case .onlyMinus:
                return !isMinus ? [] : [op]
            case .onlyTimes:
                return !isTimes ? [] : [op]
            case .onlyPlusOrMinus:
                return isPlus || isMinus ? [op] : []
            case .dropOp:
                return !isSqrt ? [] : [op]
            }
        }
        return tmpOp + valueSK + [.pow] + power.flatSKs(.dropPlus)
    }
    
    var valueSKPow1st: [StepKey] {
        valueSK + (power.first?.valueSK ?? [])
    }
    
    private func flatSKs(_ opCase: OpPrintCase, alwaysShowTimes: Bool, noRoots: Bool) -> [StepKey] {
        if isSqrt {
            let newOneNode = StepNode.newOneNode
            newOneNode.radicalParent = self.clone(changeID: false, withParent: false)
            return newOneNode.flatSKs(opCase)
        }
        var tempFlatSKs = getFlatSKsFromNode(forCursor: false, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: true).dropFirstIfOp
        let op = isRoot ? children.op : op
        switch opCase {
        case .any:
            tempFlatSKs.insert(op, at: 0)
        case .dropPlus:
            if !op.key.isPlus {
                tempFlatSKs.insert(op, at: 0)
            }
        case .dropPlusNotPlusMinus:
            if !op.key.isPlusNotPlusMinus {
                tempFlatSKs.insert(op, at: 0)
            }
        case .onlyMinus:
            if op.key.isMinus {
                tempFlatSKs.insert(op, at: 0)
            }
        case .onlyTimes:
            if op.key.isTimes {
                tempFlatSKs.insert(op, at: 0)
            }
        case .onlyPlusOrMinus:
            if op.key.isPlus || op.key.isMinus {
                tempFlatSKs.insert(op, at: 0)
            }
        case .dropOp:
            break
        }
        return tempFlatSKs
    }
    func flatSKs(_ opCase: OpPrintCase) -> [StepKey] {
        flatSKs(opCase, alwaysShowTimes: false, noRoots: false)
    }
    
    var flatSKs: [StepKey] {
        flatSKs(.any)
    }
    
    var flatSKsWithEqualityOp: [StepKey] {
        root.valueSK + flatSKs(.any)
    }

    
    func flatSKsNoTerms(_ opCase: OpPrintCase) -> [StepKey] {
        let newParent = StepNode()
        let cloneNode = self.dropTerms
        newParent.children = [cloneNode]
        return cloneNode.flatSKs(opCase)
    }

    func flatSKsNoRadicals(_ opCase: OpPrintCase) -> [StepKey] {
        let newParent = StepNode()
        let cloneNode = self.dropRadicals
        newParent.children = [cloneNode]
        return cloneNode.flatSKs(opCase)
    }

    func flatSKsForStrike(dropOp: Bool) -> [StepKey] {
        if isFraction {
            return opValueSK(dropOp ? .dropOp : .any)
        } else if isBrackets {
            let sqrtIndicesSKs = allRadicalsFlat.map({$0.indexSK}).flatMap({$0})
            let brktsSKs = isBrktsNotSqrt ? ([valueSK.first!],[valueSK.last!]) : ([],[])
            return brktsSKs.0 + children.map({$0.isFraction ? $0.valueSK : $0.flatSKsNoPow.dropHiddens}).flatMap({$0}).dropFirstIfOp(dropOp).dropSKs(sqrtIndicesSKs) + brktsSKs.1
        }
        let sqrtIndicesSKs = allRadicalsFlat.map({$0.indexSK}).flatMap({$0})
        return getFlatSKsFromNode(forCursor: false, alwaysShowTimes: false, noRoots: false, withPows: false).dropHiddens.dropFirstIfOp(dropOp).dropSKs(sqrtIndicesSKs)
    }
    
    var flatSKsNoPow: [StepKey] {
        [isRoot ? children.op : op] + getFlatSKsFromNode(forCursor: false, alwaysShowTimes: false, noRoots: false, withPows: false).dropFirstIfOp
    }
    
    var flatSKsOnlyPow: [StepKey] {
        (isFraction ? numeratorAndDenominator.flatSKsOnlyPow : []) + power.flatSKs + (radicalParent?.power.flatSKs ?? []) + directSymbs.flatMap({$0.power.flatSKs})
    }
    
    var valueSKOrStepExprIfBrkts: [StepKey] {
        isBrackets ? flatSKs(.dropOp) : valueSK
    }
    
    func flatSKsForSympy(_ opCase: OpPrintCase) -> [Key] {
        flatSKs(opCase, alwaysShowTimes: true, noRoots: true).keys
    }
    
    func flatSKsForAISteps(_ opCase: OpPrintCase) -> [Key] {
        flatSKs(opCase, alwaysShowTimes: true, noRoots: false).keys
    }
}

// MARK: Get Expr
extension StepNode {
    var flatKeys: [Key] {
        flatSKs(.any).keys
    }
    var rootStepExpr: [StepKey] {
        root.children.flatSKs(.any)
    }
    var rootFlatKeys: [Key] {
        return rootStepExpr.keys
    }
    func printExpr() {
        let calcBrain = CalcBrain()
        calcBrain.printExprLB(keys: flatKeys)
    }
}

// MARK: Idx and Nodes
extension StepNode {
    var level: [StepNode]? {
        get {parent?.children}
        set {parent!.children = newValue!}
    }
    var idx: Int? {
        level?.firstIndex(where: {$0.id == id})
    }
    var idxIfDropTimesBrackets: Int? {
        level?.dropMultipliedBrackets.firstIndex(where: {$0.id == id})
    }
    var prev: StepNode {
        guard let idx = idx, let level = level else {return StepNode.commaNode}
        if isCommaNode || op.key.isPowOrSqrt || idx==0 {
            return StepNode.commaNode
        } else {
            return level[idx-1]
        }
    }
    var next: StepNode {
        guard let idx = idx, let level = level else {return StepNode.commaNode}
        if isCommaNode || op.key.isPowOrSqrt || idx == level.count-1 {
            return StepNode.commaNode
        } else {
            return level[idx+1]
        }
    }
    var nextNonMultBrkt: StepNode? {
        if next.isTimes {} else {return nil}
        if next.isBrackets {
            return next.nextNonMultBrkt
        } else {
            return next
        }
    }
    var prevMultipliedNumberNode: StepNode? {
        if isTimes {} else {return nil}
        if prev.isNumber(mayBePowered: true) {
            return prev
        } else {
            return prev.prevMultipliedNumberNode
        }
    }
    var levelPrev: [StepNode] {
        if let idx = idx, let level = level, !isCommaNode && idx>0 {
            return [StepNode](level[0...idx])
        } else {
            return [StepNode.commaNode]
        }
    }
    var levelNext: [StepNode] {
        if let idx = idx, let level = level, !isCommaNode && idx < level.count-1 {
            return [StepNode](level[idx...level.count-1])
        } else {
            return [StepNode.commaNode]
        }
    }
    
    var isLast: Bool {
        if isSqrt {
           return coeffNode.hasDirectSymbs ? false : true
        } else if let idx = idx, let level = level {
            return idx == level.count-1
        }
        return false
    }
    var isFirst: Bool {
        idx == 0
    }
    var isFirstTerm: Bool {
        if !isTerm {fatalError()}
        return isSqrt && isBeforeSymbs || !isSqrt && !coeffNode.hasBeforeSymbsRadical && isFirst
    }
    var isLastTerm: Bool {
        if !isTerm {fatalError()}
        return isSqrt && (!coeffNode.hasDirectSymbs || isAfterSymbs) || isSymb && isLast && !coeffNode.hasAfterSymbsRadical
    }
    var exist: Bool {
        !forceStop && hasParent && ((level?.containsNode(self) ?? false) && (!parent!.hasParent || parent!.isPowOrSqrt && parent!.exist || (parent!.level?.containsNode(parent!) ?? false)) || parent!.isPowered && parent!.powerParent!.hasEqualID(with: self) && parent!.exist || parent!.hasDirectRadical && parent!.exist && parent!.radicalParent!.hasEqualID(with: self))
    }
    var root: StepNode {
        rootFn(node: self)
    }
    private func rootFn(node: StepNode) -> StepNode {
        if node.parent == nil {return node}
        return rootFn(node: node.parent!)
    }
    var hasParent: Bool {
        parent != nil
    }
    var isSemiEmpty: Bool {
        valueSK.isEmpty && (children.isEmpty || children.count == 1 && children.first!.valueSK.isEmpty && children.isPlus)
    }
    var isEmpty: Bool {
        valueSK.isEmpty && children.isEmpty && !isPowered
    }
    var isEmptyOrSemiEmpty: Bool {
        isEmpty || isSemiEmpty
    }
    var isFilledWithEmpties: Bool {
        if isRoot {
            return children.isFilledWithEmpties
        } else {
            return valueSK.isEmpty || (valueSK.first!.key.isOpenBracket || valueKeys == [.fraction]) && children.isFilledWithEmpties || valueIsOne && (radicalParent?.children.isFilledWithEmpties ?? false)
        }
    }
    var allNodes: [StepNode] {
        root.children+otherSide.children
    }
    var allNodesWithEqualStepExpr: [StepKey] {
        let typedEqualSKs: [StepKey] = {
            if otherSide.valueKeys.contains(.typedEqual) {
                return otherSide.valueSK
            } else if root.valueKeys.contains(.typedEqual) {
                return root.valueSK
            }
            return []
        }()
        return root.children.flatSKs+typedEqualSKs+otherSide.children.flatSKs
    }
    func flatSKs(dropEqual: Bool) -> [StepKey] {
        guard isRoot && isLeft else {return []}
        return children.flatSKs(.dropPlus)+(isEquation ? ((dropEqual ? [] : otherSide.valueSK) + (otherSide.children.flatSKs(.dropPlus))) : [])
    }

    func remove() {
        if op.key == .sqrt {
            parent!.radicalParent = nil
        } else if let idx = idx {
            parent?.children.remove(at: idx)
        }
    }
    func removeInFraction(isTerm: Bool, markedKeys: inout [StepKey]) {
        if isInFraction && next.isDivide {fatalError()}
        let originalValueSK = valueSK
        let removeCoeff = isTerm && !self.isTerm
        if (!isCoeff || removeCoeff) && (isPlusOrMinus || isTimes && next.isBrackets) && next.isTimes {
            next.op = op
        }
        if !isInFraction && isCoeff && !removeCoeff {
            valueSK = [.one]
            valueSK.replaceSimilarKeys(similarKeys: originalValueSK)
            removePower()
        } else {
            let nodeClone = clone(changeID: false, withParent: false)
            nodeClone.valueSK = [.one]
            nodeClone.valueSK.replaceSimilarKeys(similarKeys: originalValueSK)
            nodeClone.removePower()
            if removeCoeff {
                nodeClone.removeTerms()
            }
            if level!.count == 1 && (isInNumerator || isBrackets && isMinus) {
                insertBefore(nodeClone)
                if !removeCoeff {
                    nodeClone.directSymbs = directSymbs
                    nodeClone.radicalParent = radicalParent
                }
                markedKeys.append(nodeClone.valueSK.first!)
            } else if isInFraction && level!.count == 1 {
                if isCoeff && !removeCoeff {
                    insertBefore(nodeClone)
                } else {
                    parentFraction!.removeDenominator()
                }
            } else if isCoeff && !removeCoeff {
                insertBefore(nodeClone)
                nodeClone.directSymbs = directSymbs
                nodeClone.radicalParent = radicalParent
            }
            remove()
        }
    }
    func removeBracketsGeneral() {
        let inNodes = children
        if inNodes.isPlus {
            if inNodes.count > 1 && inNodes.dropFirst().contains(where: {!$0.isTimesOrDivide && !$0.isPowered}) && !self.isPlus {fatalError()}
            inNodes[0].op = op
        }
        let childrenIsPosBrktNotPowered = inNodes.isBracketsNotHidden && inNodes.first!.isPlus && !inNodes.first!.isPowered
        if self.isPowered {
            if inNodes.first!.isOneSingleTerm {
                inNodes.first!.directTerms.first!.power = self.power
            } else {
                if valueKeys == [.minus, .one] {fatalError()}
                inNodes.first!.power = self.power
            }
        }
        if !childrenIsPosBrktNotPowered {
            self.insertAfter(contentsOf: inNodes.dropFirst)
            self.content = inNodes.first!.content
            self.staticID = inNodes.first!.staticID
            self.staticIDForStepIncrement = inNodes.first!.staticIDForStepIncrement
        }
        self.children = inNodes.first!.children
    }
    func justRemoveBrackets() {
        guard hasChild else {return}
        if !isPlus && !children.isPlus {fatalError()}
        if children.isPlus {
            children.op = op
        }
        insertBefore(contentsOf: children)
        remove()
    }
    func removeBracketsIfAppropriate() {
        //
        guard isBracketsNotHidden else {fatalError()}
        if !isPowered || children.isSingleNode && !children.hasFraction(flat: true) && !children.hasPoweredFlat && power.isWholeNumber(mayBeCoeff: false) && power.resultValue().isOdd {} else {return}
        if next.isTimes && !children.isHighOpChain {return}
        if isPlus {} else {
            if children.isMinus {return}
            if isDivide && !children.isSingleNode {return}
            if (isMinus || isTimes) && !children.isHighOpChain {return}
        }
        //
        if isPowered {
            children.first!.baseOrTermNode.power = power
        }
        if children.isPlus {
            children.op = op
        }
        let children = children
        insertBefore(contentsOf: children)
        remove()
        self.nodeProduct = children.first!
    }
    var flatTree: [StepNode] {
        var nodes = [StepNode]()
        if !isRoot {
            nodes.append(self)
        }
        if isBrackets(.any) || hasDirectSymbs || isRoot {
            for node in children {
                nodes.append(contentsOf: node.flatTree)
            }
        } else if isFraction {
            nodes.append(children.first!)
            nodes.append(children.last!)
            for node in numerator {
                nodes.append(contentsOf: node.flatTree)
            }
            for node in denominator {
                nodes.append(contentsOf: node.flatTree)
            }
        }
        if let powerParent = powerParent {
            nodes.append(contentsOf: powerParent.flatTree)
        }
        if let radicalParent = radicalParent {
            nodes.append(contentsOf: radicalParent.flatTree)
        }
        return nodes
    }
    var flatTreeNoPow: [StepNode] {
        var nodes = [StepNode]()
        if !isRoot {
            nodes.append(self)
        }
        if isBrackets(.any) || hasDirectSymbs || op.key == .sqrt || isRoot {
            for node in children {
                nodes.append(contentsOf: node.flatTreeNoPow)
            }
        } else if isFraction {
            nodes.append(children.first!)
            nodes.append(children.last!)
            for node in numerator {
                nodes.append(contentsOf: node.flatTreeNoPow)
            }
            for node in denominator {
                nodes.append(contentsOf: node.flatTreeNoPow)
            }
        }
        if let radicalParent = radicalParent {
            nodes.append(contentsOf: radicalParent.flatTreeNoPow)
        }
        return nodes
    }
    var isRoot: Bool {
        valueSK.isEmpty && root.id == id
    }
    func hasEqualTerms(with node: StepNode) -> Bool {
        node.directTerms.isEqualTo(nodes: directTerms)
    }
    func hasEqualSymbs(with node: StepNode) -> Bool {
        node.allSymbs.isEqualTo(nodes: allSymbs)
    }
    func hasEqualSymbs(in nodes: [StepNode]) -> Bool {
        nodes.dropNode(node: self).contains(where: {hasEqualSymbs(with: $0)})
    }
    func hasEqualTerms(in nodes: [StepNode]) -> Bool {
        nodes.dropNode(node: self).contains(where: {hasEqualTerms(with: $0)})
    }
    func hasCommonTerm(in nodes: [StepNode]) -> Bool {
        return nodes.dropNode(node: self).contains(where: {hasCommonTerm(with: $0)})
    }
    func hasEqualRadical(with node: StepNode) -> Bool {
        if !node.hasDirectRadical && !hasDirectRadical {return true}
        if !(node.hasDirectRadical && hasDirectRadical) {return false}
        return radicalParent!.isEqualTo(node: node.radicalParent!)
    }
    func hasEqualRadical(in nodes: [StepNode]) -> Bool {
        return nodes.dropNode(node: self).onlyHasRadicals.contains(where: {$0.radicalParent!.isEqualTo(node: self.radicalParent!)})
    }
    func hasCommonTerm(with node: StepNode) -> Bool {
        if isBrackets || node.isBrackets {return false}
        if [self,node].numeratorChain.allPowers.flatMap({$0}).hasTerm {return false}
        if isNumber(mayBePowered: true) && node.isNumber(mayBePowered: true) {
            return hasEqualSymbs(with: node) && hasEqualRadical(with: node)
        } else if isFraction && node.isFraction {
            if denominator.count != 1 || node.denominator.count != 1 {return false}
            return numerator.containsEqualDirectTerms(nodes: node.numerator) && denominator.first!.hasEqualTerms(with: node.denominator.first!)
        } else {
            let numberNode = [self, node].first(where: {$0.isNumber(mayBePowered: true)})!
            let fractionNode = [self, node].first(where: {$0.isFraction})!
            if fractionNode.denominator.hasTerm {return false}
            return numberNode.hasEqualTerms(in: fractionNode.numerator)
        }
    }
    func isFirstOfSameSymbs(in nodes: [StepNode]) -> Bool {
        nodes.filter({$0.allSymbs.isEqualTo(nodes: self.allSymbs)}).first!.id == self.id
    }
    func isFirstOfSameTerms(in nodes: [StepNode]) -> Bool {
        nodes.filter({$0.directTerms.isEqualTo(nodes: self.directTerms)}).first!.id == self.id
    }
    func isFirstIn(in nodes: [StepNode]) -> Bool {
        nodes.first!.id == self.id
    }
    func isFirstOfCommonTerms(in fractionNodes: [StepNode]) -> Bool {
        fractionNodesCommonTerm(in: fractionNodes).first!.id == self.id
    }
    func hasEqualVarAndPower(in nodes: [StepNode]) -> Bool {
        nodes.dropNode(node: self).contains(where: {$0.hasSingleEqualVar(with: self) && self.directSymbs.first(where: {$0.isVar})!.powerValue == $0.directSymbs.first(where: {$0.isVar})!.powerValue})
    }
    var valueDouble: Double {
        valueSK.getDouble
    }
    var opValueDouble: Double {
        if isPlusOrMinus {} else {fatalError()}
        let valueDouble = valueDouble
        return isMinus ? -valueDouble : valueDouble
    }
}

// MARK: Operation Check
extension StepNode {
    var isPlus: Bool {
        op.key == .plus || op.key == .plusMinus
    }
    var isPlusNotPlusMinus: Bool {
        op.key == .plus
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
}

// MARK: Key Checks
extension StepNode {
    enum OpCase {
        case plus, minus, plusOrMinus, timesOrDivide, times, divide, any
    }
    func isZero(opCase: OpCase) -> Bool {
        if isZero {
            switch opCase {
            case .plus:
                return isPlus
            case .minus:
                return isMinus
            case .plusOrMinus:
                return isPlusOrMinus
            case .divide:
                return isDivide
            default:
                return false // Used to be fatalError()
            }
        }
        return false
    }
    var isZero: Bool {
        valueSK.keys == [.zero] && !isCoeff && !isPowered
    }
    var isZeroMayHaveSymb: Bool {
        valueSK.keys == [.zero] && !isPowered
    }
    
    func isOne(opCase: OpCase) -> Bool {
        if isCoeff || isPowered {return false}
        if valueSK.keys == [.one] {
            switch opCase {
            case .plus:
                return isPlus
            case .minus:
                return isMinus
            case .plusOrMinus:
                return isPlusOrMinus
            case .timesOrDivide:
                return isTimesOrDivide
            case .times:
                return isTimes
            case .divide:
                return isDivide
            case .any:
                return true
            }
        }
        return false
    }
    
    var isOne: Bool {
        isOne(opCase: .any)
    }
    
    func isVarFromRoot(opCase: OpCase) -> Bool {
        let root = root
        if root.children.count == 1 && !root.children.first!.hasDirectRadical && root.children.first!.isNumber(mayBePowered: false) && root.children.first!.valueIsOne && root.children.first!.symbIsVar(firstDeg: true) {
            switch opCase {
            case .plus:
                return root.children.isPlus
            case .minus:
                return root.children.isMinus
            case .plusOrMinus:
                return root.children.isPlusOrMinus
            default:
                return false // Used to be fatalError()
            }
        }
        return false
    }
    var isVarWithCoeff: Bool {
        isNumber(mayBePowered: false) && !hasDirectRadical && symbIsVar(firstDeg: true) && valueSK.keys != [.one]
    }
    var isOneTimesBracket: Bool {
        isOne(opCase: .plus) && next.isBrackets(.complete) && next.isTimes
    }
}

// MARK: General
extension StepNode {
    var hasChild: Bool {
        !children.isEmpty
    }
    func isNumber(mayBePowered: Bool) -> Bool {
        if !isFraction && !isBrackets(.any) && op.key != .sqrt && valueKeys != [.comma] {
            return mayBePowered ? true : !isPowered
        }
        return false
    }
    var isSqrt: Bool {
        op.key == .sqrt && valueSK.last!.key.isSquareBrkt
    }
    var isBrackets: Bool {
        valueSK.count >= 2 && valueSK[valueSK.count-2].key.isOpenBracket && valueSK[valueSK.count-1].key.isCloseBracket || !valueSK.isEmpty && valueSK.last!.key.isOpenBracket
    }
    var isBrktsNotSqrt: Bool {
        op.key != .sqrt && isBrackets
    }
    var isBracketsNotHidden: Bool {
        isBrackets && op.key != .sqrt && valueSK.first!.key == .openBracket
    }
    var isHiddenBrkts: Bool {
        isBrackets && valueSK.first!.key.isHiddenOpenBrkt
    }
    func isBrackets(_ conditions: ([StepNode]) -> Bool) -> Bool {
        isBrackets && conditions(children)
    }
    indirect enum BracketsCase {
        case singleNeg(mayBePowered: Bool), singlePos(mayBeFraction: Bool, fractionCase: FractionCase, mayBePowered: Bool), single(mayBePowered: Bool), notSingle(mayBeFraction: Bool), simplest, notSimplest, multipliedByNonBracket, notMultiplied, powered, notPowered, singleFraction(fractionCase: FractionCase), hasFraction(fractionCase: FractionCase), complete, openEmpty, openNotEmpty, any, poweredSingleNegative, singleNegGeneral, distributeReady
    }
    func isBrackets(_ bracketCase: BracketsCase) -> Bool {
        if !isBrackets {return false}
        switch bracketCase {
        case .any:
            return true
        case .complete:
            return valueSK.count >= 2 && valueSK[valueSK.count-2].key.isOpenBracket && valueSK[valueSK.count-1].key.isCloseBracket && !children.isEmptyOrSemiEmpty
        case .openEmpty:
            return valueSK.last!.key.isOpenBracket && children.isEmpty
        case .openNotEmpty:
            return valueSK.last!.key.isOpenBracket && !children.isEmpty
        case .singleNeg(let mayBePowered):
            return children.isSingle(mayBeFraction: false, mayBePowered: mayBePowered) && children.isMinus
        case .singleNegGeneral:
            return children.count == 1 && children.isMinus
        case .singlePos(let mayBeFraction, let fractionCase , let mayBePowered):
            return children.isSingle(mayBeFraction: mayBeFraction, fractionCase: fractionCase, mayBePowered: mayBePowered) && children.isPlus
        case .single(let mayBePowered):
            return children.isSingle(mayBeFraction: false, mayBePowered: mayBePowered)
        case .notSingle(let mayBeFraction):
            return !children.isSingle(mayBeFraction: mayBeFraction, mayBePowered: false)
        case .simplest:
            return children.isSimplestForm
        case .notSimplest:
            return !children.isSimplestForm
        case .multipliedByNonBracket:
            return multChain(forward: false).dropNode(node: self).hasNonBrackets
        case .notMultiplied:
            return !isTimes && !next.isTimes
        case .singleFraction(let fractionCase):
            return children.count == 1 && children.first!.isFraction(fractionCase)
        case .hasFraction(let fractionCase):
            return children.hasFraction(fractionCase)
        case .powered:
            return isPowered
        case .notPowered:
            return !isPowered
        case .poweredSingleNegative:
            return isBrackets(.singleNeg(mayBePowered: false)) && isPowered
        case .distributeReady:
            return children.isSimplestForm && children.isMulti && !isPowered
        }
    }
    var hasOpenNotEmptyParentBracket: Bool {
        if let tmpParent = baseNode.parent, tmpParent.isBrackets && !tmpParent.valueSK.last!.isHiddenBracket {
            if tmpParent.isBrackets(.openNotEmpty) {return true}
            return tmpParent.hasOpenNotEmptyParentBracket
        }
        return false
    }
    var mayRemoveBrackets: Bool {
        !(children.shouldSetBrktIfPowered && isPowered) && (children.hasOnlyTimes || !(isMultipliedOrDivideOrDivided || isMinus))
    }
    var isNotChild: Bool {
        parent == nil || parent!.parent == nil
    }
    var isChild: Bool {
        !isNotChild
    }
    var noHighOpAfter: Bool {
        !isPowered && !next.isTimesOrDivide
    }
}

extension StepNode {
    func flipSign() {
        if op.key.isMinus {
            op.key = .plus
        } else if op.key.isPlus {
            op.key = .minus
        }
    }
    func flipSignsAndChangeIDs() {
        if op.key.isMinus {
            op = .plus
        } else if op.key.isPlus {
            op = .minus
        }
    }
    func setTimesAndParenIfNeg() {
        if isMinus {
            let tmpChild = clone(changeID: false, withParent: false)
            removeRadical()
            valueSK = StepNode.newBracketsNode.valueSK
            op = .times
            children = [tmpChild]
        } else {
            op = .times
        }
    }
    func changeIDs() {
        op.changeID()
        valueSK.changeIDs()
        if isBrackets(.complete) {
            for node in children {
                node.changeIDs()
            }
        } else if isFraction {
            children.first!.changeIDs()
            children.last!.changeIDs()
        }
        powerParent?.changeIDs()
        radicalParent?.changeIDs()
        if hasDirectSymbs {
            for symbNode in directSymbs {
                symbNode.changeIDs()
            }
        }
    }
    func withChangedIDs(withParent: Bool) -> StepNode {
        let tempNode = self.clone(changeID: false, withParent: withParent)
        tempNode.changeIDs()
        return tempNode
    }
    func isDividableBy(node: StepNode, mayEqual: Bool) -> Bool {
        //
        if self.isPowered || node.isPowered {return false}
        let multiplyer = self.dynamicValue.getDouble
        if multiplyer == 0 {return false}
        let divider = node.dynamicValue.getDouble
        if divider == 0 || divider == 1 || divider.isDecimal {return false}
        if !mayEqual && multiplyer == divider {return false}
        //
        let origTranc = multiplyer.truncatingRemainder(dividingBy: divider)
        let truncatingRemainder = origTranc.rounded
        let divisionResult = (multiplyer/divider).rounded
        return truncatingRemainder == 0 || isDecimal && divisionResult.newNode.afterDotCount <= max(afterDotCount, node.afterDotCount) && (!node.isDecimal || multiplyer>divider)
    }
    func exactResultIfDividedBy(node: StepNode) -> Bool {
        let multiplyer = self.dynamicValue.getDouble
        let divider = node.dynamicValue.getDouble
        return (multiplyer/divider).count < 14
    }
    var showTimesBeforeBrackets: Bool {
        if op.idIsZero {
            return false
        } else if !(isBrackets(.complete) && isTimes) {
            return true
        } else if exist && (prev.isFraction || prev.isDivide) {
            return true
        } else if exist && prev.isBrackets(.complete) {
            return prev.children.likelyToBeSingle || children.likelyToBeSingle
        } else {
            return children.likelyToBeSingle
        }
    }
    func hasEqualBase(with node: StepNode) -> Bool {
        if isBrackets(.complete) {
            if !node.isBrackets(.complete) || node.valueKeys.filter({$0 != .dot}).replaceHiddenBrkts != valueKeys.filter({$0 != .dot}).replaceHiddenBrkts {return false}
            return self.children.isEqualTo(nodes: node.children)
        } else if isNumber(mayBePowered: true) || isBrackets(.singleNeg(mayBePowered: false)) {
            if !node.isNumber(mayBePowered: true) {return false}
            return dynamicValue.keys == node.dynamicValue.keys
        } else if isFraction {return false} else {fatalError()}
    }
    var illegibleForHasEqualBase: Bool {
        isBrackets(.complete) || isNumber(mayBePowered: true) || isBrackets(.singleNeg(mayBePowered: false)) || isFraction
    }
    func isEqualTo(node: StepNode) -> Bool {
        if isBrackets(.any) {
            if !node.isBrackets(.any) {return false}
            if opValueSK.keys.filter({$0 != .dot}).replaceHiddenBrkts != node.opValueSK.keys.filter({$0 != .dot}).replaceHiddenBrkts || !power.isEqualTo(nodes: node.power) {return false}
            return self.children.isEqualTo(nodes: node.children)
        } else if isFraction {
            if !node.isFraction {return false}
            if self.op.key != node.op.key {return false}
            return self.numerator.isEqualTo(nodes: node.numerator) && self.denominator.isEqualTo(nodes: node.denominator)
        } else if isNumber(mayBePowered: true) {
            if !node.isNumber(mayBePowered: true) {return false}
            if let radicalParent = radicalParent {
                if let nodeRadicalParent = node.radicalParent {
                    if !radicalParent.isEqualTo(node: nodeRadicalParent) {return false}
                } else {return false}
            } else if node.hasDirectRadical {return false}
            return opValueSK.keys == node.opValueSK.keys && power.isEqualTo(nodes: node.power) && directSymbs.isEqualTo(nodes: node.directSymbs)
        } else {fatalError()}
    }
    func isEqualWithID(to otherNode: StepNode) -> Bool {
        id == otherNode.id && isEqualTo(node: otherNode)
    }
    func hasEqualBaseIfExpo(with node: StepNode) -> Bool {
        if isTerm || !isNumber(mayBePowered: true) {
            return hasEqualBase(with: node)
        }
        if node.isTerm || !node.isNumber(mayBePowered: true) {return false}
        let selfClone = self.clone(changeID: false, withParent: false)
        let otherClone = node.clone(changeID: false, withParent: false)
        return (selfClone.getExponentialForm ?? selfClone).hasEqualBase(with: (otherClone.getExponentialForm ?? otherClone))
    }
    func isEqualToDropOp(node: StepNode) -> Bool {
        let cloneNode = StepNode()
        cloneNode.content = node.content
        cloneNode.op = self.op
        return isEqualTo(node: cloneNode)
    }
    func hasEqualOp(with node: StepNode) -> Bool {
        op.key == node.op.key
    }
    func insertAfter(_ node: StepNode) {
        level!.insert(node, at: idx!+1)
    }
    func insertAfter(contentsOf nodes: [StepNode]) {
        level!.insert(contentsOf: nodes, at: idx!+1)
    }
    func insertBefore(_ node: StepNode) {
        level!.insert(node, at: idx!)
    }
    func insertBefore(contentsOf nodes: [StepNode]) {
        level!.insert(contentsOf: nodes, at: idx!)
    }
    func replace(with node: StepNode, withOp: Bool) {
        if node.op.key == op.key || withOp {
            node.op = op
        }
        insertAfter(node)
        remove()
    }
    func replace(with nodes: [StepNode], withOp: Bool) {
        if nodes.op.key == op.key || withOp {
            nodes.first!.op = op
        }
        insertAfter(contentsOf: nodes)
        remove()
    }
}

// MARK: Symbs
extension StepNode {
    var containsVar: Bool {
        return allSymbs.contains(where: {$0.isVar})
    }
    var hasDirectSymbs: Bool {
        if !isNumber(mayBePowered: true) {return false}
        return !directSymbs.isEmpty
    }
    func nodesSameSymb(in nodes: [StepNode]) -> [StepNode] {
        nodes.filter({self.directSymbs.isEqualTo(nodes: $0.directSymbs)})
    }
    func nodesSameTerm(in nodes: [StepNode]) -> [StepNode] {
        nodes.filter({self.directTerms.isEqualTo(nodes: $0.directTerms)})
    }
    func fractionNodesCommonTerm(in nodes: [StepNode]) -> [StepNode] {
        nodes.onlyFractions.filter({hasCommonTerm(with: $0)})
    }
    func removeSymbs() {
        directSymbs.removeAll()
    }
    func removeVar() {
        directSymbs.removeAll(where: {$0.isVar})
        if let radicalParent = radicalParent, radicalParent.children.hasVarFlat {
            radicalParent.remove()
        }
    }
    var isCoeff: Bool {
        hasDirectSymbs || hasDirectRadical
    }
    var hasTerm: Bool {
        !allTerms.isEmpty
    }
}

// MARK: Fractions
extension StepNode {
    var numerator: [StepNode] {
        get {
            if !isFraction {fatalError()}
            return children.first!.children
        }
        set {
            if !isFraction {fatalError()}
            children.first!.children = newValue
        }
    }
    var denominator: [StepNode] {
        get {
            if !isFraction {fatalError()}
            return children.last!.children
        }
        set {
            if !isFraction {fatalError()}
            children.last!.children = newValue
        }
    }
    var numBrackets: [StepKey] {
        if !isFraction {fatalError()}
        return children.first!.valueSK
    }
    var denBrackets: [StepKey] {
        if !isFraction {fatalError()}
        return children.last!.valueSK
    }
    var isFraction: Bool {
        valueSK.keys == [.fraction]
    }
    var isInFractionGeneral: Bool {
        if isInFraction {
            return true
        }
        if let tmpParent = parent {
            if tmpParent.isInFraction {
                return true
            } else {
                return tmpParent.isInFractionGeneral
            }
        }
        return false
    }
    var isInDenominatorGeneral: Bool {
        if isInDenominator {
            return true
        }
        if let tmpParent = parent {
            if tmpParent.isInDenominator {
                return true
            } else {
                return tmpParent.isInDenominatorGeneral
            }
        }
        return false
    }
    var isInSqrtGeneral: Bool {
        if hasParent && parent!.isSqrt {
            return true
        } else if let tmpParent = parent {
            if tmpParent.hasParent && tmpParent.parent!.isSqrt {
                return true
            } else {
                return tmpParent.isInSqrtGeneral
            }
        }
        return false
    }
    var generalRadicalParent: StepNode? {
        if let parent = parent {
            if parent.isSqrt {
                return parent
            } else {
                return parent.generalRadicalParent
            }
        }
        return nil
    }
    var parentIsRadical: Bool {
        if let parent = parent {
            return parent.isSqrt
        }
        return false
    }
    var generalParentBrktWithNegExp: StepNode? {
        if let parent = parent {
            if parent.isPoweredByNegative && parent.isPoweredByWholeNumber {
                return parent
            } else {
                return parent.generalParentBrktWithNegExp
            }
        }
        return nil
    }
    var selfOrInFraction: StepNode? {
        if isFraction {
            return numerator.first
        } else {return self}
    }
    var isInFraction: Bool {
        hasParent && parent!.hasParent && parent!.parent!.isFraction
    }
    var isInNumerator: Bool {
        isInFraction && parent!.parent!.numerator.contains(self)
    }
    var isInNumeratorOrNotInFraction: Bool {
        !isInFraction || isInNumerator
    }
    var isInDenominator: Bool {
        isInFraction && parent!.parent!.denominator.contains(self)
    }
    var parentFractionGeneral: StepNode? {
        if !isInFractionGeneral {return nil}
        if isInFraction {
            return parentFraction
        } else {
            return parent!.parentFractionGeneral
        }
    }
    var parentFraction: StepNode? {
        if parent!.isFraction {
            return parent
        }
        return !isInFraction ? nil : parent!.parent
    }
    var selfOrParentFraction: StepNode {
        isInFraction ? parentFraction! : self
    }
    enum FractionPart {
        case numerator, denominator, all, any
    }
    enum FractionCase {
        case simplest(for: FractionPart), simplestNotSingle(for: FractionPart), notSimplest(for: FractionPart), hasVar(for: FractionPart), hasBrackets(_ bracketsCase: BracketsCase, for: FractionPart), simplestReduced, simplestReducedNegletPowered, notSimplestReduced, multiplied, single(simplest: Bool, for: FractionPart), notSingle(for: FractionPart), simplestNegletTimesBrackets(for: FractionPart), notSimplestNegletTimesBrackets(for: FractionPart), onlyTimes, notOnlyTimes(andNotSimplestNotSingle: Bool), hasFraction, any, notSinglePositive, hasSingleNegative, singleWholeNumber(mustBeReduced: Bool), singleWholeNumberReducible, empty(for: FractionPart), singlePositiveNumber(mayBePowered: Bool, mayHaveCoeff: Bool, for: FractionPart), toMergeRadicals
    }
    func isFraction(_ fractionCase: FractionCase) -> Bool {
        if !isFraction {return false}
        switch fractionCase {
        case .any:
            return true
        case .empty(for: let part):
            switch part {
            case .numerator:
                return numerator.isEmptyFractionPart
            case .denominator:
                return denominator.isEmptyFractionPart
            case .all:
                return numerator.isEmptyFractionPart && denominator.isEmptyFractionPart
            case .any:
                return numerator.isEmptyFractionPart || denominator.isEmptyFractionPart
            }
        case .simplest(for: let part):
            switch part {
            case .numerator:
                return numerator.isSimplestForm
            case .denominator:
                return denominator.isSimplestForm
            case .all:
                return numerator.isSimplestForm && denominator.isSimplestForm
            case .any:
                return numerator.isSimplestForm || denominator.isSimplestForm
            }
        case .simplestNotSingle(for: let part):
            switch part {
            case .numerator:
                return numerator.isSimplestForm && numerator.count > 1
            case .denominator:
                return denominator.isSimplestForm && denominator.count > 1
            case .all:
                return numerator.isSimplestForm && numerator.count > 1 && denominator.isSimplestForm && denominator.count > 1
            case .any:
                return numerator.isSimplestForm && numerator.count > 1 || denominator.isSimplestForm && denominator.count > 1
            }
        case .notSimplest(for: let part):
            switch part {
            case .numerator:
                return !numerator.isSimplestForm
            case .denominator:
                return !denominator.isSimplestForm
            case .all:
                return !numerator.isSimplestForm && !denominator.isSimplestForm
            case .any:
                return !numerator.isSimplestForm || !denominator.isSimplestForm
            }
        case .hasVar(for: let part):
            switch part {
            case .numerator:
                return numerator.hasVar
            case .denominator:
                return denominator.hasVar
            case .all:
                return numerator.hasVar && denominator.hasVar
            case .any:
                return numerator.hasVar || denominator.hasVar
            }
        case .hasBrackets(let bracketsCase, for: let part):
            switch part {
            case .numerator:
                return numerator.hasBrackets(bracketsCase)
            case .denominator:
                return denominator.hasBrackets(bracketsCase)
            case .all:
                return numerator.hasBrackets(bracketsCase) && denominator.hasBrackets(bracketsCase)
            case .any:
                return numerator.hasBrackets(bracketsCase) || denominator.hasBrackets(bracketsCase)
            }
        case .simplestReduced:
            return numerator.isSimplestForm && denominator.isSimplestForm && !isReduceToSimplifyForFraction
        case .simplestReducedNegletPowered:
            return numerator.isSimplestFormNegletPowered && denominator.isSimplestFormNegletPowered && !isReduceToSimplifyForFraction
        case .notSimplestReduced:
            return !numerator.isSimplestForm || !denominator.isSimplestForm || isReduceToSimplifyForFraction
        case .multiplied:
            return isTimes || next.isTimes
        case .single(let simplest, for: let part):
            switch part {
            case .numerator:
                return numerator.isSingle(mayBeFraction: true, fractionCase: simplest ? .simplestReduced : .any, mayBePowered: true)
            case .denominator:
                return denominator.isSingle(mayBeFraction: true, fractionCase: simplest ? .simplestReduced : .any, mayBePowered: true)
            case .all:
                return numerator.isSingle(mayBeFraction: true, fractionCase: simplest ? .simplestReduced : .any, mayBePowered: true) && denominator.isSingle(mayBeFraction: true, fractionCase: simplest ? .simplestReduced : .any, mayBePowered: true)
            case .any:
                return numerator.isSingle(mayBeFraction: true, fractionCase: simplest ? .simplestReduced : .any, mayBePowered: true) || denominator.isSingle(mayBeFraction: true, fractionCase: simplest ? .simplestReduced : .any, mayBePowered: true)
            }
        case .notSingle(for: let part):
            switch part {
            case .numerator:
                return !numerator.isSingle(mayBeFraction: false, mayBePowered: true)
            case .denominator:
                return !denominator.isSingle(mayBeFraction: false, mayBePowered: true)
            case .all:
                return !numerator.isSingle(mayBeFraction: false, mayBePowered: true) && !denominator.isSingle(mayBeFraction: false, mayBePowered: true)
            case .any:
                return !numerator.isSingle(mayBeFraction: false, mayBePowered: true) || !denominator.isSingle(mayBeFraction: false, mayBePowered: true)
            }
            
        case .simplestNegletTimesBrackets(for: let part):
            switch part {
            case .numerator:
                return numerator.isSimplestFormNegletTimesBracket
            case .denominator:
                return denominator.isSimplestFormNegletTimesBracket
            case .all:
                return numerator.isSimplestFormNegletTimesBracket && denominator.isSimplestFormNegletTimesBracket
            case .any:
                return numerator.isSimplestFormNegletTimesBracket || denominator.isSimplestFormNegletTimesBracket
            }
            
        case .notSimplestNegletTimesBrackets(for: let part):
            switch part {
            case .numerator:
                return !numerator.isSimplestFormNegletTimesBracket
            case .denominator:
                return !denominator.isSimplestFormNegletTimesBracket
            case .all:
                return !numerator.isSimplestFormNegletTimesBracket && !denominator.isSimplestFormNegletTimesBracket
            case .any:
                return !numerator.isSimplestFormNegletTimesBracket || !denominator.isSimplestFormNegletTimesBracket
            }
        case .onlyTimes:
            return numerator.hasOnlyTimes && denominator.hasOnlyTimes
            
        case .notOnlyTimes(let andNotSimplestNotSingle):
            if andNotSimplestNotSingle {
                return !numerator.hasOnlyTimes && !numerator.simplestNotSingle || !denominator.hasOnlyTimes && !denominator.simplestNotSingle
            } else {
                return !numerator.hasOnlyTimes || !denominator.hasOnlyTimes
            }
            
        case .hasFraction:
            return numerator.hasFraction(flat: true) || denominator.hasFraction(flat: true)
        case .notSinglePositive:
            return !(numerator.isSingle(mayBeFraction: false, mayBePowered: false) && numerator.isPlus && denominator.isSingle(mayBeFraction: false, mayBePowered: false) && denominator.isPlus)
        case .hasSingleNegative:
            return numerator.count == 1 && numerator.isMinus || denominator.count == 1 && denominator.isMinus
        case .singleWholeNumber(mustBeReduced: let mustBeReduced):
            return numerator.isWholeNumber(mayBeCoeff: true) && denominator.isWholeNumber(mayBeCoeff: true) && (!mustBeReduced || !isReduceToSimplifyForFraction)
        case .singleWholeNumberReducible:
            return numerator.isWholeNumber(mayBeCoeff: true) && denominator.isWholeNumber(mayBeCoeff: true) && isReduceToSimplifyForFraction
        case .singlePositiveNumber(let mayBePowered, let mayHaveCoeff, for: let part):
            switch part {
            case .numerator:
                return numerator.count == 1 && numerator.first!.isNumber(mayBePowered: mayBePowered) && (mayHaveCoeff || !numerator.first!.isCoeff) && numerator.isPlus
            case .denominator:
                return denominator.count == 1 && denominator.first!.isNumber(mayBePowered: mayBePowered) && (mayHaveCoeff || !denominator.first!.isCoeff) && denominator.isPlus
            case .all:
                return numerator.count == 1 && numerator.first!.isNumber(mayBePowered: mayBePowered) && (mayHaveCoeff || !numerator.first!.isCoeff) && numerator.isPlus && denominator.count == 1 && denominator.first!.isNumber(mayBePowered: mayBePowered) && (mayHaveCoeff || !denominator.first!.isCoeff) && denominator.isPlus
            case .any:
                return numerator.count == 1 && numerator.first!.isNumber(mayBePowered: mayBePowered) && (mayHaveCoeff || !numerator.first!.isCoeff) && numerator.isPlus || denominator.count == 1 && denominator.first!.isNumber(mayBePowered: mayBePowered) && (mayHaveCoeff || !denominator.first!.isCoeff) && denominator.isPlus
            }
        case .toMergeRadicals:
            if numerator.isOneSingleRadical && denominator.isOneSingleRadical {} else {return false}
            if numerator.first!.radicalParent!.indexValue == denominator.first!.radicalParent!.indexValue {} else {return false}
            let newFraction = clone(changeID: false, withParent: false)
            newFraction.numerator.first!.radicalParent!.extractPosAloneRadicalContent()
            newFraction.denominator.first!.radicalParent!.extractPosAloneRadicalContent()
            return newFraction.isReducibleIsolatedFraction
        }
    }
    func isFraction(part: FractionPart, _ conditions: ([StepNode]) -> Bool) -> Bool {
        if !isFraction {return false}
        switch part {
        case .numerator:
            return conditions(numerator)
        case .denominator:
            return conditions(denominator)
        case .all:
            return conditions(numerator) && conditions(denominator)
        case .any:
            return conditions(numerator) || conditions(denominator)
        }
    }
    func setOneIfNumIsEmpty(steps: inout [StepModel]) {
        if numerator.isEmpty {
            numerator = [StepNode.newOneNode]
            steps.lastMarked.append(contentsOf: numerator.opValuesSK(.any))
        }
    }
    
    func removeDenominator() {
        removeDenominator(mayMayRemoveBrackets: true)
    }
    func removeDenominatorWithoutMayRemoveBrkts() {
        removeDenominator(mayMayRemoveBrackets: false)
    }
    private func removeDenominator(mayMayRemoveBrackets: Bool) {
        let fractionOp = op
        content = children.first!.content
        staticIDForStepIncrement = Int32.random
        valueSK[0].key = .openBracket
        valueSK[1].key = .closeBracket
        op = fractionOp
        if children.isBrackets(.complete) {
            removeBracketsGeneral()
        }
        if mayMayRemoveBrackets && mayRemoveBrackets {
            removeBracketsGeneral()
        }
    }
    func setValueToOne() {
        valueSK = [.one]
    }
}

// MARK: Chains
extension StepNode {
    var divideDefaultChain: [StepNode] {
        if isFraction {return []}
        if !next.isTimesOrDivide || op.priority > next.op.priority || (next.isPowered && !next.isBrackets(.notSingle(mayBeFraction: false))) || (isPowered && !isBrackets(.notSingle(mayBeFraction: false))) || isDivide {return (isBrackets(.notSingle(mayBeFraction: false)) ? [] : [self])}
        return (isBrackets(.notSingle(mayBeFraction: false)) ? [] : [self]) + next.divideDefaultChain
    }
    var timesDefaultChain: [StepNode] {
        if isFraction || isDivide || isPowered && !isBrackets(.notSingle(mayBeFraction: false)) || isBrackets(.notSimplest) {return []}
        if !next.isTimes || op.priority > next.op.priority || (next.isPowered && !next.isBrackets(.notSingle(mayBeFraction: false))) || (isPowered && !isBrackets(.notSingle(mayBeFraction: false))) {return (isBrackets(.notSingle(mayBeFraction: false)) ? [] : [self])}
        return (isBrackets(.notSingle(mayBeFraction: false)) ? [] : [self]) + next.timesDefaultChain
    }
    var timesDefaultChainWithPow: [StepNode] {
        if isFraction || isDivide || isBrackets(.notSimplest) {return []}
        if !next.isTimes || op.priority > next.op.priority {return (isBrackets(.notSingle(mayBeFraction: false)) ? [] : [self])}
        return (isBrackets(.notSingle(mayBeFraction: false)) ? [] : [self]) + next.timesDefaultChainWithPow
    }
    var highOpChain: [StepNode] {
        if !next.isTimesOrDivide {return [self]}
        return [self] + next.highOpChain
    }
}

extension StepNode {
    func multChain(forward: Bool) -> [StepNode] {
        if forward || !isTimes {
            return multChain
        } else if let level = level {
            return level.first(where: {$0.multChain.contains(self)})!.multChain
        }
        return []
    }
    private var multChain: [StepNode] {
        if isDivide {return []}
        if !next.isTimes {return [self]}
        return [self] + next.multChain
    }
    var isInDividedMultChain: Bool {
        if let lastNode = multChain.last {
            return lastNode.next.isDivide
        }
        return false
    }
    var isInMultChain: Bool {
        multChain(forward: false).count > 1
    }
    var isFirstInDividedMultChain: Bool {
        isInDividedMultChain && (!isTimes || prev.isFraction || !prev.isTimes)
    }
    var isFirstInMultChain: Bool {
        isInMultChain && multChain(forward: false).first!.id == id
    }
    var isFirstInHighOpChain: Bool {
        !op.key.isHighOp
    }
    var multChainDivider: StepNode {
        if isInDividedMultChain {
            return multChain.next
        } else if isDivide {
            return self
        } else {fatalError()}
    }
    func multChainNoBrackets(forward: Bool, _ bracketCase: BracketsCase) -> [StepNode] {
        multChain(forward: forward).filter({!$0.isBrackets(bracketCase)})
    }
    func multChainNoBracketsNoOneTerms(forward: Bool) -> [StepNode] {
        multChain(forward: forward).filter({!($0.isBrackets(.any) || $0.isOneTerm)})
    }
    func isInMultChainNoBrackets(_ bracketCase: BracketsCase) -> Bool {
        multChainNoBrackets(forward: false, bracketCase).count > 1
    }
    var isFirstInMultChainNoBracketsNoOneTerms: Bool {
        let multChainNoBracketsNoOneTerms = multChainNoBracketsNoOneTerms(forward: false)
        return multChainNoBracketsNoOneTerms.count > 1 && multChainNoBracketsNoOneTerms.first!.id == id
    }
}

extension StepNode {
    func numeratorMultChain(termMix: Bool) -> [StepNode] {
        if !exist {return []}
        var numChain = [StepNode]()
        for node in multChain.dropPoweredNegatives {
            if node.isFraction(part: .numerator, {$0.isSmplstFormOrMultChainOrIs4TermsFactorable}) {
                let numContent = node.numerator
                if numContent.isMultiNotHighOpChain {
                    let newBrkt = numContent.parent!
                    numChain.append(newBrkt)
                } else {
                    numChain.append(contentsOf: (termMix ? numContent.dropFractions.dropPoweredNegatives.termMix : numContent.dropFractions.dropPoweredNegatives).dropMultOnes.dropMultZeros)
                }
            } else if !node.isFraction {
                if !node.valueIsOne && !node.valueIsZero {
                    numChain.append(node)
                }
                if termMix {
                    let showRadBeforeSymbs = node.hasBeforeSymbsRadical
                    if showRadBeforeSymbs {
                        if let radicalParent = node.radicalParent {
                            numChain.append(radicalParent)
                        }
                    }
                    if node.hasDirectSymbs {
                        numChain.append(contentsOf: node.directSymbs)
                    }
                    if !showRadBeforeSymbs {
                        if let radicalParent = node.radicalParent {
                            numChain.append(radicalParent)
                        }
                    }
                }
            }
        }
        return numChain.dropReduced
    }
    
    func denominatorMultChain(termMix: Bool) -> [StepNode] {
        if !exist {return []}
        var denChain = [StepNode]()
        for node in multChain.dropPoweredNegatives {
            if node.isFraction(part: .denominator, {$0.isSmplstFormOrMultChainOrIs4TermsFactorable}) {
                let denContent = node.denominator.dropFractions.dropPoweredNegatives
                if denContent.isEmpty {return []}
                if node.denominator.isMultiNotHighOpChain {
                    let newBrkt = denContent.parent!
                    denChain.append(newBrkt)
                } else {
                    denChain.append(contentsOf: (termMix ? denContent.termMix : denContent).dropMultOnes.dropMultZeros)
                }
            }
        }
        return denChain.dropReduced
    }
}

// MARK: Static
extension StepNode {
    static var newBracketsNode: StepNode {
        StepNode(valueSK: [.openBracket,.closeBracket])
    }
    static var newFractionBracketsNode: StepNode {
        StepNode(valueSK: [.openCurlyBrkt,.closeCurlyBrkt])
    }
    static var newFractionNode: StepNode {
        let fractionNode = StepNode(valueSK: [.fraction])
        let numParent = newFractionBracketsNode
        let denParent = newFractionBracketsNode
        fractionNode.children = [numParent,denParent]
        fractionNode.numerator = [.newOneNode]
        fractionNode.denominator = [.newOneNode]
        return fractionNode
    }
    static func newSqrtNode(indexSK: [StepKey]) -> StepNode {
        StepNode(op: .sqrt, valueSK: indexSK + [.openSquareBrkt, .closeSquareBrkt])
    }
    static func newOneNodeWithSqrt(indexSK: [StepKey]) -> StepNode {
        let newOneNode = StepNode.newOneNode
        newOneNode.radicalParent = StepNode.newSqrtNode(indexSK: indexSK)
        return newOneNode
    }
    static func newOneNodeWithVar(type: StepKey) -> StepNode {
        let newOneNode = StepNode.newOneNode
        newOneNode.directSymbs = [.newSymbNode(type: type)]
        return newOneNode
    }
    static var newZeroNode: StepNode {
        let parentNode = StepNode()
        let zeroNode = StepNode(valueSK: [.zero])
        parentNode.children = [zeroNode]
        return zeroNode
    }
    static var newOneNode: StepNode {
        let parentNode = StepNode()
        let oneNode = StepNode(valueSK: [.one])
        parentNode.children = [oneNode]
        return oneNode
    }
    static var commaNode: StepNode {
        let parentNode = StepNode()
        let commaNode = StepNode(op: .comma, valueSK: [.comma])
        parentNode.children = [commaNode]
        return commaNode
    }
    var isCommaNode: Bool {
        if isRoot {
            return children.first!.isCommaNode
        } else {
            return valueSK.count == 1 && valueSK.first!.key == .comma
        }
    }
    static var typedEqualNode: StepNode {
        let parentNode = StepNode()
        let teNode = StepNode(op: .typedEqual)
        parentNode.children = [teNode]
        return teNode
    }
    static func newSymbNode(type: StepKey) -> StepNode {
        StepNode(op: .times, valueSK: [type])
    }
}

// MARK: New
extension StepNode {
    func decrementPower(by decrementAmount: Double) {
        if !isPoweredByWholeNumber {fatalError()}
        var valueDouble = powerValue
        valueDouble -= decrementAmount
        power = [StepNode(valueSK: valueDouble.newSKs)]
        if isPoweredByOne {
            removePower()
        }
    }
    var isPowered: Bool {
        !power.isEmpty
    }
    var hasPowerParent: Bool {
        powerParent != nil && powerParent!.valueKeys == [.openSquareBrkt, .closeSquareBrkt] && powerParent!.op.key == .pow
    }
    var poweredParentGeneral: StepNode? {
        if let parent = parent {
            if parent.hasPowerParent {
                return parent
            }
            return parent.poweredParentGeneral
        }
        return nil
    }
    var isPoweredByNegative: Bool {
        isPowered && power.isMinus && !power.isZero
    }
    var powerResultIsNegative: Bool {
        isPowered && power.resultValue() < 0
    }
    var powerResultIsZero: Bool {
        isPowered && power.resultValue() == 0
    }
    var isPoweredByPosOrNotPowered: Bool {
        !isPowered || power.isPlus && power.isSimplestForm
    }
    var isPoweredByWholeNumberOrNotPowered: Bool {
        !isPowered || isPoweredByWholeNumber
    }
    var isPoweredByWholeNumber: Bool {
        power.count == 1 && power.first!.isWholeNumber(mayBePowered: false, mayBeCoeff: false)
    }
    var isPoweredByPosWholeNumber: Bool {
        power.count == 1 && power.first!.isWholeNumber(mayBePowered: false, mayBeCoeff: false) && powerValue > 0
    }
    var isPoweredByMultiple: Bool{
        power.count > 1
    }
    var isPoweredBySymb: Bool {
        power.hasSymbFlat
    }
    var powerValue: Double {
        if !isPowered {
            return 1
        } else {
            if !isPoweredByWholeNumber {fatalError()}
            return power.first!.valueSK.getDouble * (power.isMinus ? -1 : 1)
        }
    }
    var powerResult: Double {
        if !isPowered {
            return 1
        } else {
            return power.resultValue()
        }
    }
    func hasEqualPow(with node: StepNode) -> Bool {
        power.isEqualTo(nodes: node.power)
    }
    var isPoweredByOne: Bool {
        isPoweredByWholeNumber && powerValue == 1 && power.isPlus
    }
    var isPoweredByZero: Bool {
        isPoweredByWholeNumber && powerValue == 0 && power.isPlus
    }
    var strikeKey: (key: StepKey, count: Int) {
        if isOneSingleSymb {
            return (directSymbs.first!.type ?? .comma, 1)
        } else if isSqrt {
            let tmpStepExpr = [op] + children.flatSKsForStrike
            return (tmpStepExpr[Int(floor(Double(tmpStepExpr.count/2)))], tmpStepExpr.count)
        } else if isBrackets {
            let tmpStepExpr = flatSKsForStrike(dropOp: true).filter({!$0.key.isCurlyBrkt}) // Filtering because of: {{1}/{5}}/{{2}/{5}}
            return (tmpStepExpr[Int(floor(Double(tmpStepExpr.count/2)))], tmpStepExpr.count)
        } else if isFraction {
            return (valueSK.first!, 3)
        } else {
            return (valueSK[Int(floor(Double(valueSK.count)/2))], valueSK.count)
        }
    }
    var strikeKeyWithSymb: (key: StepKey, count: Int) {
        if isOneSingleSymb {
            return (directSymbs.first!.type ?? .comma, 1)
        } else if isBrackets {
            let isSqrt = isSqrt
            let tmpStepExpr = flatSKsForStrike(dropOp: true).filter({!($0.isHiddenBracket || isSqrt && $0.key == .two && [$0] == indexSK)})
            return (tmpStepExpr[tmpStepExpr.count/2], tmpStepExpr.count)
        } else if isFraction {
            return (valueSK.first!, 3)
        } else {
            let hasDirectRadical = hasDirectRadical
            let tmpStepExpr = flatSKsForStrike(dropOp: true).filter({!($0.isHiddenBracket || hasDirectRadical && $0.key == .two && [$0] == radicalParent!.indexSK)})
            return (tmpStepExpr[tmpStepExpr.count/2], tmpStepExpr.count)
        }
    }
    
    func withOp(_ op: StepKey) -> StepNode {
        let tmp = clone(changeID: false, withParent: false)
        tmp.op = op
        return tmp
    }
    func withOp(_ op: StepKey, clone: Bool) -> StepNode {
        if clone {
            return withOp(op)
        } else {
            self.op = op
            return self
        }
    }
    func withSymb(symbs: [StepNode]) -> StepNode {
        let tmp = clone(changeID: false, withParent: true)
        tmp.directSymbs = symbs
        return tmp
    }
    func withRadical(radical: StepNode) -> StepNode {
        let tmp = clone(changeID: false, withParent: true)
        tmp.radicalParent = radical
        return tmp
    }
    func withOpChangeID(op: Key) -> StepNode {
        if !op.isOp {fatalError()}
        let tmp = clone(changeID: true, withParent: true)
        tmp.op = .stepKey(op)
        return tmp
    }
    func withChildren(children: [StepNode]) -> StepNode {
        let tmp = clone(changeID: false, withParent: true)
        tmp.children = children
        return tmp
    }
    
    func setSurfedToFalse(keepTargets: Bool) {
        for node in flatTree {
            node.isSurfed = false
            node.isReduced = false
            if !keepTargets {
                node.isTarget = false
            }
        }
    }
    func setTargetedToFalse() {
        for node in flatTree {
            node.isTarget = false
        }
    }
    var valueIsOne: Bool {
        valueSK.keys == [.one]
    }
    var valueIsZero: Bool {
        valueSK.keys == [.zero]
    }
    var isMultiplied: Bool {
        isTimes || next.isTimes
    }
    var isMultipliedByBracketsOnly: Bool {
        if next.isTimes {
            if isTimes {return false}
            return next.isBrackets
        }
        return isTimes && prev.isBrackets
    }
    var multiplierBrkt: StepNode? {
        if next.isTimes && next.isBrackets {
            return next
        } else if isTimes && prev.isBrackets {
            return prev
        }
        return nil
    }
    var isMultipliedFromBothSides: Bool {
        isTimes && next.isTimes
    }
    var isMultipliedByNonBrackets: Bool {
        isTimes && !prev.isBrackets || next.isTimes && !next.isBrackets
    }
    var isDivided: Bool {
        next.isDivide
    }
    var isMultipliedOrDivided: Bool {
        isMultiplied || isDivided
    }
    var isMultipliedOrDivideOrDivided: Bool {
        isMultiplied || isDivide || isDivided
    }
    var forceStop: Bool {
        resultCase != .none
    }
    var isOneSymb: Bool {
        valueIsOne && !hasBeforeSymbsRadical && hasDirectSymbs
    }
    var isOneRadical: Bool {
        valueIsOne && hasBeforeSymbsRadical
    }
    var isOneTerm: Bool {
        valueIsOne && (hasDirectSymbs || hasDirectRadical)
    }
    func isOneSingleVar(mayBeInSqrt: Bool) -> Bool {
        isOneSingleSymb && symbIsVar || mayBeInSqrt && isOneSingleRadical && radicalParent!.children.hasVarFlat
    }
    func removePower() {
        powerParent = nil
    }
    var dynamicValue: [StepKey] {
        get {
            if isBrackets(.singleNeg(mayBePowered: true)) {
                return children.first!.valueSK
            } else if isBrackets {
                if isPowered {
                    return flatSKs(.dropOp)
                } else {
                    return children.flatSKs(.dropOp)
                }
            } else {
                return valueSK
            }
        }
        set {
            if isBrackets(.singleNeg(mayBePowered: true)) {
                children[0].valueSK = newValue
            } else if isBrackets {
                fatalError()
            } else {
                valueSK = newValue
            }
        }
    }
    func setBrackets() {
        let brktsNode = StepNode.newBracketsNode
        self.insertAfter(brktsNode)
        self.remove()
        brktsNode.children = [self]
    }
    func setBracketsAndExtractOp() {
        let brktsNode = StepNode.newBracketsNode
        self.insertAfter(brktsNode)
        self.remove()
        brktsNode.children = [self]
        brktsNode.op = self.op
        self.op = .plus
    }
    func setBracketsAndExtractPower() {
        if !isSingleNode {return}
        setBrackets()
        parent!.power = baseOrTermNode.power
        baseOrTermNode.removePower()
        parent!.op = op
        op = .plus
    }
    func setSelfToBrackets() {
        setSelfToBrackets(extractOp: false)
    }
    func setSelfToBrackets(extractOp: Bool) {
        let brktsNode = StepNode.newBracketsNode
        brktsNode.children = [self.clone(changeID: false, withParent: false)]
        if extractOp {
            brktsNode.op = brktsNode.children.op
            brktsNode.children.first!.op = .plus
        }
        self.content = brktsNode.content
    }
    var isNegativeBrackets: Bool {
        !valueKeys.isEmpty && valueKeys.first!.isMinus
    }
    var isAttachedMinus: Bool {
        isNegativeBrackets || isMinus && isFirst
    }
    func appendSymb(_ symbKey: StepKey) {
        directSymbs.append(.newSymbNode(type: symbKey))
    }
    var withRepCount: StepNode {
        var repKeys = [Key]()
        setRepCount(repKeys: &repKeys)
        return self
    }
    func withRepCount(increment: Int) -> StepNode {
        var repKeys = [Key]()
        setRepCount(repKeys: &repKeys)
        if increment != 0 {
            incRepCount(by: increment)
        }
        return self
    }
    func setRepCount(repKeys: inout [Key]) {
        op.setRepCount(repKeys: &repKeys)
        if isNumber(mayBePowered: true) {
            valueSK.setRepCounts(repKeys: &repKeys)
            if isPowered {
                powerParent!.setRepCount(repKeys: &repKeys)
            }
            if let radicalParent = radicalParent {
                radicalParent.setRepCount(repKeys: &repKeys)
                if radicalParent.hasPowerParent {
                    radicalParent.powerParent!.setRepCount(repKeys: &repKeys)
                }
            }
            for symbNode in children {
                symbNode.setRepCount(repKeys: &repKeys)
            }
        } else if isFraction {
            children.first!.setRepCount(repKeys: &repKeys)
            valueSK.setRepCounts(repKeys: &repKeys)
            children.last!.setRepCount(repKeys: &repKeys)
        } else if isBrackets {
            valueSK[0].setRepCount(repKeys: &repKeys)
            for childNode in children {
                childNode.setRepCount(repKeys: &repKeys)
            }
            if isBrackets(.complete) {
                valueSK[1].setRepCount(repKeys: &repKeys)
            }
            if isPowered {
                powerParent!.setRepCount(repKeys: &repKeys)
            }
        }
    }
    func incRepCount(by increment: Int) {
        op.repCount += increment
        if isNumber(mayBePowered: true) {
            valueSK.incRepCount(by: increment)
            if isPowered {
                powerParent!.incRepCount(by: increment)
            }
            if let radicalParent = radicalParent {
                radicalParent.incRepCount(by: increment)
                if radicalParent.hasPowerParent {
                    radicalParent.powerParent!.incRepCount(by: increment)
                }
            }
            for symbNode in children {
                symbNode.incRepCount(by: increment)
            }
        } else if isFraction {
            children.first!.incRepCount(by: increment)
            valueSK.incRepCount(by: increment)
            children.last!.incRepCount(by: increment)
        } else if isBrackets {
            valueSK[0].repCount += increment
            for childNode in children {
                childNode.incRepCount(by: increment)
            }
            if isBrackets(.complete) {
                valueSK[1].repCount += increment
            }
            if isPowered {
                powerParent!.incRepCount(by: increment)
            }
        }
    }
    func dropVarAndRadVar(dropNotVarX: Bool) -> StepNode {
        let nodeClone = clone(changeID: false, withParent: false)
        if !nodeClone.isNumber(mayBePowered: true) || nodeClone.isRoot {
            for tmpChild in nodeClone.children {
                tmpChild.content = tmpChild.dropVarAndRadVar(dropNotVarX: dropNotVarX).content
            }
        } else {
            nodeClone.directSymbs.removeAll(where: {dropNotVarX ? $0.type?.key.isVarOrNotVarX ?? false : $0.type?.key.isVar ?? false})
            if let radicalParent = nodeClone.radicalParent, (dropNotVarX ? radicalParent.children.hasVarOrNotVarXFlat : radicalParent.children.hasVarFlat) {
                nodeClone.removeRadical()
            }
        }
        return nodeClone
    }
    var dropTerms: StepNode {
        let nodeClone = clone(changeID: false, withParent: false)
        if nodeClone.isNumber(mayBePowered: true) {
            nodeClone.removeRadical()
            nodeClone.directSymbs.removeAll()
        }
        return nodeClone
    }
    var dropRadicals: StepNode {
        let nodeClone = clone(changeID: false, withParent: false)
        if nodeClone.isNumber(mayBePowered: true) {
            nodeClone.removeRadical()
        }
        return nodeClone
    }
    var dynamicInnerMinus: StepKey {
        get {
            let op = isBrackets(.singleNegGeneral) ? children.op : op
            if !op.key.isMinus {fatalError()}
            return op
        }
        set {
            if isBrackets(.singleNegGeneral) {
                children.op = newValue
            } else {
                if !op.key.isMinus {fatalError()}
                op = newValue
            }
        }
    }
    var isNegative: Bool {
        isMinus || isBrackets(.singleNegGeneral) && !(isBrackets(.singleFraction(fractionCase: .any)) && isPowered)
    }
    func isInSameFraction(with otherNode: StepNode, shouldBeSingle: Bool) -> Bool {
        if !baseNode.isInFraction || !otherNode.baseNode.isInFraction {return false}
        if shouldBeSingle && baseNode.parentFraction!.isFraction(.notSingle(for: .any)) {return false}
        return baseNode.isInNumerator && baseNode.parentFraction!.denominator.contains(otherNode.baseNode) || baseNode.isInDenominator && baseNode.parentFraction!.numerator.contains(otherNode.baseNode)
    }
    func isInFraction(node: StepNode) -> Bool {
        parentFraction?.hasEqualID(with: node) ?? false
    }
    var isHighOp: Bool {
        op.key.isHighOp
    }
    var flippedFraction: StepNode {
        let flipped = clone(changeID: false, withParent: true)
        if !flipped.isFraction {
            let newFraction = StepNode.newFractionNode
            newFraction.denominator = [flipped]
            if flipped.isMinus {
                newFraction.op = flipped.op
                flipped.op = .plus
            }
        } else {
            let holder = flipped.numerator
            flipped.children[0].children = flipped.denominator
            flipped.children[1].children = holder
        }
        return flipped.isFraction ? flipped : flipped.parentFraction!
    }
    func flipFraction(fnCtrl: [FnCtrl]) {
        
        //
        if !isFraction {fatalError()}
        
        //
        let holder = numerator
        children[0].children = denominator
        children[1].children = holder
        
        //
        if !fnCtrl.contains(.skipRemoveDenIfOne) && denominator.isOne(opCase: .plus) {
            removeDenominator()
        }
    }
    var dynamicNumeratorFirst: StepNode {
        isFraction ? numerator.first! : self
    }
    var isDecimal: Bool {
        !valueSK.isEmpty && isNumber(mayBePowered: true) && !isSymb && valueSK.getDouble.isDecimal
    }
    func isWholeNumber(mayBePowered: Bool, mayBeCoeff: Bool) -> Bool {
        isNumber(mayBePowered: mayBePowered) && !(!mayBeCoeff && isCoeff) && !isDecimal
    }
    func isWholeNumber(mayBeCoeff: Bool) -> Bool {
        isNumber(mayBePowered: false) && !(!mayBeCoeff && isCoeff) && !isDecimal
    }
    var isPowerer: Bool {
        if op.key == .pow {return true}
        if let tmpParent = parent {
            if tmpParent.op.key == .pow {
                return true
            } else {
                return tmpParent.isPowerer
            }
        }
        return false
    }
    var poweredNode: StepNode {
        if op.key == .pow {
            return parent!
        }
        if let tmpParent = parent {
            if tmpParent.op.key == .pow {
                return tmpParent.parent!
            } else {
                return tmpParent.poweredNode
            }
        }
        fatalError()
    }
    var isSecondLevelPower: Bool {
        isPowerer && poweredNode.isPowerer
    }
    var isDoublePowered: Bool {
        return isPowered && power.flatTree.contains(where: {$0.isPowered})
    }
    var nestedFractionCount: Double {
        if !isFraction {return 0}
        return max(numerator.nestedFractionsCount, 1) + max(denominator.nestedFractionsCount, 1)
    }
    var isSymb: Bool {
        if valueSK.contains(where: {$0.key.isSymb}) {
            return true
        }
        return false
    }
    func symbIsVar(firstDeg: Bool) -> Bool {
        if !symbIsVar {return false}
        if allSymbs.count == 1 {
            if firstDeg {
                return !allSymbs.first!.isPowered || allSymbs.first!.power.isOne(opCase: .plus)
            } else {
                return allSymbs.first!.isPowered && !allSymbs.first!.power.isOne(opCase: .plus)
            }
        }
        return false
    }
    func isVar(firstDeg: Bool) -> Bool {
        guard type?.key.isVar ?? false else {return false}
        if firstDeg {
            return !isPowered || power.isOne(opCase: .plus)
        } else {
            return isPowered && !power.isOne(opCase: .plus)
        }
    }
    var isVar: Bool {
       isSymb && type?.key.isVar ?? false
    }
    var isVarOrI: Bool {
       isSymb && type?.key.isVarOrI ?? false
    }
    var isTerm: Bool {
        isSymb || isSqrt
    }
    var isConstSymb: Bool {
        guard let type = type else {return false}
        return !type.key.isVarOrI
    }
    var isConst: Bool {
        !hasVarOrIFlat
    }
    var symbIsVar: Bool {
        allSymbs.count == 1 && allSymbs.first!.valueKeys.first!.isVar
    }
    var hasVar: Bool {
        allSymbs.contains(where: {$0.type?.key.isVar ?? false}) || allRadicals.contains(where: {$0.children.hasVarFlat})
    }
    var hasVarOrNotVarX: Bool {
        allSymbs.contains(where: {$0.type?.key.isVarOrNotVarX ?? false}) || allRadicals.contains(where: {$0.children.hasVarOrNotVarXFlat})
    }
    var hasI: Bool {
        allSymbs.contains(where: {$0.type?.key == .imaginary}) || allRadicals.contains(where: {$0.children.hasIFlat})
    }
    var hasVarOrI: Bool {
        allSymbs.contains(where: {$0.type?.key.isVar ?? false || $0.type?.key == .imaginary}) || allRadicals.contains(where: {$0.children.hasVarOrIFlat})
    }
    var hasVarOrNotVarXOrI: Bool {
        allSymbs.contains(where: {$0.type?.key.isVarOrNotVarX ?? false || $0.type?.key == .imaginary}) || allRadicals.contains(where: {$0.children.hasVarOrNotVarXOrIFlat})
    }
    var hasConstSymb: Bool {
        allSymbs.contains(where: {$0.type != nil && !$0.type!.key.isVarOrI})
    }
    var hasConstSymbOrRad: Bool {
        hasConstSymb || radicalParent != nil
    }
    var hasVarFlat: Bool {
        if isRoot {return children.hasVarFlat}
        return allSymbsFlat.contains(where: {$0.type?.key.isVar ?? false})
    }
    var hasVarOrNotVarXFlat: Bool {
        if isRoot {return children.hasVarOrNotVarXFlat}
        return allSymbsFlat.contains(where: {$0.type?.key.isVarOrNotVarX ?? false})
    }
    var hasIFlat: Bool {
        if isRoot {return children.hasIFlat}
        return allSymbsFlat.contains(where: {$0.type?.key == .imaginary})
    }
    var hasVarOrIFlat: Bool {
        if isRoot {return children.hasVarFlat}
        return allSymbsFlat.contains(where: {$0.type?.key.isVarOrI ?? false})
    }
    var deg: Int? {
        if isFraction {
            if numerator.count > 1 {return nil}
            return numerator.first!.deg
        } else if let xSymb = directSymbs.first(where: {$0.isVar}) {
            if xSymb.power.count > 1 {return nil}
            if xSymb.power.isEmpty {
                return 1
            }
            return xSymb.power.first!.valueSK.getInt
        } else {return 0}
    }
    var firstTerm: StepNode? {
        if let radicalParent = radicalParent, radicalParent.isBeforeSymbs {
            return radicalParent
        } else if hasDirectSymbs {
            return directSymbs.first!
        } else if let radicalParent = radicalParent, radicalParent.isAfterSymbs {
            return radicalParent
        }
        return nil
    }
    var firstValueSK: StepKey {
        get {valueSK.first!}
        set {valueSK[0] = newValue}
    }
    var type: StepKey? {
        get {
            if !isSymb {return nil}
            return valueSK.last
        }
        set {
            if !isSymb {return}
            if let newValue = newValue {
                valueSK[valueSK.count-1] = newValue
            }
        }
    }
    var symbChar: String {
        type?.title ?? ""
    }
    var isWholeNumberMaybeVarOrNotVarXOrI: Bool {
        isWholeNumber(mayBePowered: false, mayBeCoeff: true) && !directSymbs.contains(where: {$0.type != nil && !$0.type!.key.isVarOrNotVarXOrI}) && !hasDirectRadical
    }
    var shouldSetBrktIfPowered: Bool {
        isMinus || isPowered || isFraction || isCoeff && !(isOneSingleTerm && !firstTerm!.isPowered)
    }
    var hasMultiSymbs: Bool {
        allSymbs.count > 1
    }
    var hasMultiTerms: Bool {
        directTerms.count > 1
    }
    var hasSingleSymb: Bool {
        allSymbs.count == 1
    }
    var hasSingleTerm: Bool {
        (allSymbs.count+(hasDirectRadical ? 1 : 0)) == 1
    }
    var isOneSingleSymb: Bool {
        !hasDirectRadical && isOneSymb && hasSingleSymb
    }
    var isOneSingleTerm: Bool {
        isOneTerm && hasSingleTerm
    }
    var isOneSingleRadical: Bool {
        isOneSingleTerm && hasDirectRadical
    }
    var symbsAreInSimplestForm: Bool {
        if !(isNumber(mayBePowered: true) || isBrackets(.singleNeg(mayBePowered: true))) {fatalError()}
        for symbNode in dynamicNode.allSymbs {
            if !symbNode.power.isSimplestForm || dynamicNode.allSymbs.dropNode(node: symbNode).contains(where: {symbNode.hasEqualBase(with: $0)}) {
                return false
            }
        }
        return true
    }
    var radicalIsInSimplestForm: Bool {
        if let radicalParent = radicalParent {
            return radicalParent.children.isSimplestForm && radicalParent.power.isSimplestForm && radicalParent.isSimplestRadical
        } else {return true}
    }
    var termsAreInSimplestForm: Bool {
        symbsAreInSimplestForm && radicalIsInSimplestForm
    }
    var hasDuplicate: Bool {
        level?.dropNode(node: self).contains(where: {$0.hasEqualBase(with: self)}) ?? false
    }
    func changeContent() {
        if isRoot {
            children.first!.valueSK = [.comma]
        } else {
            valueSK = [.comma]
        }
    }
    func extractSymbs() {
        if !hasDirectSymbs {return}
        let newOneNode = StepNode.newOneNode.withOp(.times)
        newOneNode.directSymbs = directSymbs
        insertAfter(newOneNode)
        removeSymbs()
    }
    func extractTerms() {
        if !isCoeff {return}
        let newOneNode = StepNode.newOneNode.withOp(.times)
        newOneNode.radicalParent = radicalParent
        newOneNode.directSymbs = directSymbs
        insertAfter(newOneNode)
        removeTerms()
    }
    func extractTermsAfter(termNode: StepNode) {
        if !isCoeff {return}
        let newOneNode = StepNode.newOneNode.withOp(.times)
        if termNode.isSqrt {
            if termNode.isBeforeSymbs {
                let tmpSymbs = directSymbs
                removeSymbs()
                newOneNode.directSymbs = tmpSymbs
            }
            insertAfter(newOneNode)
        } else {
            let splittedSymbs = directSymbs.split(separator: termNode)
            if hasAfterSymbsRadical || !(splittedSymbs.isEmpty || splittedSymbs.count == 1 && termNode.isLast) {
                if !termNode.isLast {
                    newOneNode.directSymbs = [StepNode](splittedSymbs.last ?? [])
                }
                if splittedSymbs.count == 1 {
                    if !termNode.isLast {
                        directSymbs = [termNode]
                    }
                } else if !splittedSymbs.isEmpty {
                    directSymbs = [StepNode](splittedSymbs.first! + [termNode])
                }
                if let radicalParent = radicalParent, radicalParent.isAfterSymbs {
                    radicalParent.remove()
                    newOneNode.radicalParent = radicalParent
                }
                insertAfter(newOneNode)
            }
        }
    }
    func extractTerm(_ termNode: StepNode) {
        if !isCoeff {return}
        let newOneNode = StepNode.newOneNode.withOp(.times)
        termNode.remove()
        if termNode.isSqrt {
            termNode.isAfterSymbs = false
            newOneNode.radicalParent = termNode
        } else {
            newOneNode.directSymbs = [termNode]
            if hasAfterSymbsRadical && !hasDirectSymbs {
                radicalParent!.isAfterSymbs = false
            }
        }
        insertAfter(newOneNode)
    }
    func splitTermsAt(_ termNode: StepNode) {
        if !termNode.isTerm {fatalError()}
        var coeffNode: StepNode {termNode.coeffNode}
        if coeffNode.isOneSingleTerm {return}
        if termNode.isSqrt {
            if termNode.isBeforeSymbs {
                if !coeffNode.isOneTerm {
                    coeffNode.extractTerms()
                }
                if !coeffNode.isOneSingleTerm {
                    coeffNode.extractSymbs()
                }
            } else {
                coeffNode.extractTerm(termNode)
                termNode.isAfterSymbs = false
            }
        } else {
            if termNode.isFirstTerm {
                if coeffNode.valueIsOne {} else {
                    coeffNode.extractTerms()
                }
                if coeffNode.isOneSingleTerm {} else {
                    coeffNode.extractTermsAfter(termNode: termNode)
                }
            } else {
                coeffNode.extractTermsAfter(termNode: termNode.isFirst ? coeffNode.radicalParent! : termNode.prev)
                if !coeffNode.isOneSingleTerm {
                    coeffNode.extractTermsAfter(termNode: termNode)
                }
            }
        }
    }
    func extractRadicalAndAfter() {
        guard let radicalParent = radicalParent else {fatalError()}
        if radicalParent.isBeforeSymbs {
            extractTerms()
        } else {
            extractTerm(radicalParent)
        }
    }
    func extractRadical() {
        if let radicalParent = radicalParent {
            let shouldInsertBefore = radicalParent.isBeforeSymbs && valueIsOne
            removeRadical()
            let newOneNode = StepNode.newOneNode
            newOneNode.radicalParent = radicalParent
            if shouldInsertBefore {
                newOneNode.op = op
                op = .times
                insertBefore(newOneNode)
            } else {
                insertAfter(newOneNode.withOp(.times))
            }
        } else {fatalError()}
    }
    var baseNodeIfOneSingleTerm: StepNode {
        if isTerm && coeffNode.isOneSingleTerm {
            return coeffNode
        }
        return self
    }
    var baseNodeIfOneTerm: StepNode {
        if isTerm && coeffNode.isOneTerm {
            return coeffNode
        }
        return self
    }
    var dotRemoved: StepNode {
        if !isDecimal {fatalError()}
        let nodeClone = clone(changeID: false, withParent: true)
        nodeClone.valueSK.removeAll(where: {$0.key == .dot})
        return nodeClone
    }
    func hasEqualID(with node: StepNode) -> Bool {
        node.id == id
    }
    var isInBrackets: Bool {
        hasParent && parent!.isBrackets && !parent!.valueSK.last!.isHiddenBracket
    }
    func isInBrackets(_ bracketCase: BracketsCase) -> Bool {
        hasParent && parent!.isBrackets(bracketCase)
    }
    func isInBrackets(_ conditions: ([StepNode]) -> Bool) -> Bool {
        hasParent && parent!.isBrackets && conditions(level!)
    }
    func isSymbType(type: Key?) -> Bool {
        self.type?.key == type
    }
    func isSameSymb(with symbNode: StepNode) -> Bool {
        self.type?.key == symbNode.type?.key
    }

    var getExponentialForm: StepNode? {
        var powCount = 1
        var newPow = 1
        var newBase = valueSK.getDouble
        while true {
            powCount += 1
            let nthRootResultNotRounded = pow(valueSK.getDouble, 1/Double(powCount))
            let nthRootResult: Double = nthRootResultNotRounded.rounded
            if nthRootResult < 2 {break}
            if nthRootResult.isWholeNumber {
                newPow = powCount
                newBase = nthRootResult
            }
        }
        if newPow == 1 {return nil}
        let nodeClone = clone(changeID: false, withParent: false)
        nodeClone.power = [newPow.newNode]
        nodeClone.valueSK = newBase.newSKs
        return nodeClone
    }
    var expoFormOrSelf: StepNode {
        if isNumber(mayBePowered: true) && !isTerm, let exponentialForm = getExponentialForm {
            return exponentialForm
        }
        return self
    }
    //    func convertToExponentialForm() {
    //        let exponentialForm = getExponentialForm
    //        if hasDirectSymbs {
    //            extractTerms() // revise
    //        }
    //        // account for hasDirectRadical
    //        setBrackets()
    //        parent!.op = op
    //        op = .plus
    //        parent!.power = power
    //        power = exponentialForm.power
    //        valueSK = exponentialForm.valueSK
    //    }
    var isEquation: Bool {
        !otherSide.isEmpty
    }
    var isEquationWithYNoZ: Bool {
        guard isEquation else {return false}
        let allVarsFlat = allNodes.allVarsFlat
        if allVarsFlat.contains(where: {$0.isSymbType(type: .z)}) {return false}
        return allVarsFlat.contains(where: {$0.isSymbType(type: .y)})
    }
    var multChainFirst: StepNode {
        multChain(forward: false).first!
    }
    var afterDotCount: Int {
        if !isDecimal {return 0}
        let afterDotKeys = [Key](valueKeys.split(separator: .dot).last!)
        return afterDotKeys.count
    }
    var tenPoweredToDecimalCount: StepNode {
        let power = afterDotCount
        let tenPowered = pow(Double(10), Double(power))
        return tenPowered.newNode
    }
    var isInSimplestFraction: Bool {
        parentFraction?.isFraction(.simplest(for: .all)) ?? false
    }
    var sideIsZero: Bool {
        root.children.isZero
    }
    func seperateTermsFromNode() {
        if !isCoeff {fatalError()}
        let newOneTerms = StepNode.newOneNode.withOp(.times)
        newOneTerms.radicalParent = radicalParent
        newOneTerms.directSymbs = directSymbs
        insertAfter(newOneTerms)
        removeSymbs()
        removeRadical()
    }
    func seperateSymbFromSymbs() {
        if !isSymb {fatalError()}
        let newOneSymbs = StepNode.newOneNode.withOp(.times)
        let tmpCoeff = coeffNode
        remove()
        newOneSymbs.directSymbs = [self]
        tmpCoeff.insertAfter(newOneSymbs)
    }
    func seperateRadicalFromCoeff() {
        if !isSqrt {fatalError()}
        let newOneRadical = StepNode.newOneNode.withOp(.times)
        let tmpCoeff = coeffNode
        remove()
        newOneRadical.radicalParent = self
        tmpCoeff.insertAfter(newOneRadical)
    }
    
    var isDivideByZero: Bool {
        !valueSK.first!.isHiddenBracket && (isZero(opCase: .divide) || parentFraction?.denominator.isZero ?? false)
    }
    var isZeroPowerZero: Bool {
        valueIsZero && isPoweredByZero
    }
    var isZeroPowerByNegative: Bool {
        guard valueIsZero && isPowered && power.isSimplestForm else {return false}
        if power.hasVarOrNotVarXFlat {return false}
        return power.resultValue() < 0
    }
    var isUndefinableZero: Bool {
        isDivideByZero || isZeroPowerZero || isZeroPowerByNegative
    }
    var convertIsNotAllowed: Bool {
        let isNotSimplestForm = !(children.isSimplestFormNegletTimesBracket &&
                                  children.first(where: { $0.isBrackets })?.children.isSimplestForm ?? true)
        
        let hasLargeNumber = children.flatTree.contains(where: { 
            !$0.isSymb && 
            $0.isNumber(mayBePowered: false) && 
            $0.valueDouble >= 1e16
        })
        
        let isNotSingleLargeNumber = !(children.count == 1 && 
                                       children.first!.isNumber(mayBePowered: false) && 
                                       children.first!.valueDouble >= 1e13 && 
                                       children.first!.valueDouble < 1e16)
        
        let hasSpecialCase = children.isEmpty || 
                             (children.count == 1 && children.first!.isWholeNumberMaybeVarOrNotVarXOrI) || 
                             convertIsNotAllowedBecauseOfVarNotVarXOrI
        
        return isNotSimplestForm || hasLargeNumber || (isNotSingleLargeNumber && hasSpecialCase)
    }
    var convertIsNotAllowedBecauseOfVarNotVarXOrI: Bool {
        (children.isMulti || children.first?.isFraction(.notSingle(for: .any)) ?? false || children.isBrackets) && children.hasVarOrNotVarXOrIFlatNoPow || children.allpowersFlattened.hasVarOrNotVarXOrI || children.isFraction && children.first?.denominator.hasVarOrNotVarXOrI ?? false || children.flatTree.contains(where: {$0.radicalParent != nil && $0.radicalParent!.hasVarOrNotVarXOrI})
    }
    var childrenExprCharsWidth: Double {
        children.map({$0.exprCharsWidth}).reduce(0, +)
    }
    var exprCharsWidth: Double {
        var charsWidth: Double = 0
        let node = self
        if node.isFraction {
            var tmpLength: Double = 0
            tmpLength += !node.hasParent || node.isFirst ? node.op.key == .plus ? 0 : node.isMinus ? 0.8 : node.op.key.charWidth : node.op.key.charWidth
            tmpLength += 0.5
            tmpLength += max(node.children.first!.childrenExprCharsWidth, node.children.last!.childrenExprCharsWidth)
            charsWidth += tmpLength * (node.isPowerer ? 0.8 : 1)
        } else if node.isBrktsNotSqrt {
            if node.showTimesBeforeBrackets {
                charsWidth += !node.hasParent || node.isFirst ? node.op.key == .plus ? 0 : node.isMinus ? 0.8 : node.op.key.charWidth : node.op.key.charWidth
            }
            charsWidth += node.valueKeys.charsWidth
            charsWidth += node.childrenExprCharsWidth
            charsWidth += node.powerCharsWidth
        } else {
            if !(node.op.idIsZero || node.isOneRadical && node.op.key == .times || node.isOneTermAfterFraction) {
                charsWidth += !node.hasParent || node.isFirst ? node.op.key == .plus ? 0 : node.isMinus ? 0.8 : node.op.key.charWidth : node.op.key.charWidth
            }
            if node.isOneTerm {
                if node.showOneTerm {
                    charsWidth += Key.one.charWidth
                }
            } else {
                charsWidth += node.valueKeys.charsWidth
            }
            charsWidth += node.powerCharsWidth
            if let radicalParent = node.radicalParent {
                charsWidth += Key.sqrt.charWidth
                let indexKeys = radicalParent.indexSK.keys
                charsWidth += indexKeys == [.openCurlyBrkt] || indexKeys != [.two] ? indexKeys.charsWidth*0.45 : 0
                charsWidth += radicalParent.childrenExprCharsWidth
                charsWidth += radicalParent.powerCharsWidth
            }
            for symbNode in node.directSymbs {
                charsWidth += symbNode.valueKeys.charsWidth
                charsWidth += symbNode.powerCharsWidth
            }
        }
        return charsWidth
    }
    var powerCharsWidth: Double {
        if let powerNode = powerParent, let powerNodeParent = powerNode.parent {
            let isNestedPower = powerNodeParent.isPowerer
            return powerNode.childrenExprCharsWidth * (isNestedPower ? 0.72 : 0.61) + (isNestedPower ? 0.27 : 0.18)
        }
        return 0
    }
    var hasSingleVar: Bool {
        directSymbs.filter({$0.isVar}).count == 1
    }
    func hasSingleEqualVar(with node: StepNode) -> Bool {
        hasSingleVar && directSymbs.first(where: {$0.isVar})!.valueKeys == node.directSymbs.first(where: {$0.isVar})!.valueKeys
    }
    func getFlatSKsFromNode(forCursor: Bool, alwaysShowTimes: Bool, noRoots: Bool, withPows: Bool) -> [StepKey] {
        var nodes: [StepNode] {isRoot ? children : [self]}
        var flatSKs = [StepKey]()
        nodes.convertNodesToExpr(flatSKs: &flatSKs, alwaysShowTimes: alwaysShowTimes, noRoots: noRoots, withPows: withPows)
        if forCursor {
            if root.isLeft {
                flatSKs.insert(.rootHiddenOpenBracketLHS, at: 0)
            } else {
                flatSKs.insert(.rootHiddenOpenBracketRHS, at: 0)
            }
        }
        return flatSKs
    }
    var isReduceToSimplifyForFraction: Bool {
        
        // Conditions
        if !isFraction {fatalError()}
        let fractionClone = clone(changeID: false, withParent: false)
        let tmpParent = StepNode()
        tmpParent.children = [fractionClone]
        let denChain = fractionClone.denominatorMultChain(termMix: false).filter({!$0.isDecimal})
        let numChain = fractionClone.numeratorMultChain(termMix: false).filter({!$0.isDecimal})
        
        // Reduce
        for numNode in numChain.dropBracketsNotSingleNeg {
            if denChain.contains(where: {[numNode,$0].getGCD != nil}) {return true}
        }
        return false
    }
    // alignmentChoice removed (returned SwiftUI VerticalAlignment — pure rendering metadata)
    var maxNestedNum: Double {
        var currentFraction = StepNode()
        var inBrktMax = 0.0
        for node in children {
            if node.isFraction {
                if currentFraction.isEmpty || node.numerator.nestedFractionsAndPowCount > currentFraction.numerator.nestedFractionsAndPowCount {
                    currentFraction = node
                }
            } else if node.isBrackets {
                inBrktMax = max(node.maxNestedNum, inBrktMax)
            } else if let radicalParent = node.radicalParent {
                inBrktMax = max(radicalParent.maxNestedNum, inBrktMax)
            }
        }
        return currentFraction.isEmpty ? inBrktMax : max(max(currentFraction.numerator.nestedFractionsAndPowCount,inBrktMax), 1)
    }
    var maxNestedDen: Double {
        var currentFraction = StepNode()
        var inBrktMax = 0.0
        for node in children {
            if node.isFraction {
                if currentFraction.isEmpty || node.denominator.nestedFractionsAndPowCount > currentFraction.denominator.nestedFractionsAndPowCount {
                    currentFraction = node
                }
            } else if node.isBrackets {
                inBrktMax = max(node.maxNestedDen, inBrktMax)
            } else if let radicalParent = node.radicalParent {
                inBrktMax = max(radicalParent.maxNestedDen, inBrktMax)
            }
        }
        return currentFraction.isEmpty ? inBrktMax : max(max(currentFraction.denominator.nestedFractionsAndPowCount, inBrktMax), 1)
    }
    var maxNestedNumIgnorePow: Double {
        var currentFraction = StepNode()
        var inBrktMax = 0.0
        for node in children {
            if node.isFraction {
                if currentFraction.isEmpty || node.numerator.nestedFractionsCount > currentFraction.numerator.nestedFractionsCount {
                    currentFraction = node
                }
            } else if node.isBrackets {
                inBrktMax = max(node.maxNestedNumIgnorePow, inBrktMax)
            } else if let radicalParent = node.radicalParent {
                inBrktMax = max(radicalParent.maxNestedNumIgnorePow, inBrktMax)
            }
        }
        return currentFraction.isEmpty ? inBrktMax : max(max(currentFraction.numerator.nestedFractionsCount, inBrktMax), 1)
    }
    var maxNestedDenIgnorePow: Double {
        var currentFraction = StepNode()
        var inBrktMax = 0.0
        for node in children {
            if node.isFraction {
                if currentFraction.isEmpty || node.denominator.nestedFractionsCount > currentFraction.denominator.nestedFractionsCount {
                    currentFraction = node
                }
            } else if node.isBrackets {
                inBrktMax = max(node.maxNestedDenIgnorePow, inBrktMax)
            } else if let radicalParent = node.radicalParent {
                inBrktMax = max(radicalParent.maxNestedDenIgnorePow, inBrktMax)
            }
        }
        return currentFraction.isEmpty ? inBrktMax : max(max(currentFraction.denominator.nestedFractionsCount, inBrktMax), 1)
    }
    var innerID: Int32 {
        if isSymb {
            return valueSK.first!.id
        } else if isFirst {
            if let parent = parent {
                if parent.isRoot {
                    if isLeft {
                        return StepKey.lhsFirstID
                    } else {
                        return StepKey.rhsFirstID
                    }
                } else if isInNumerator {
                    return parentFraction!.valueSK.first!.id
                } else if parent.isSqrt {
                    return parent.op.id
                } else {
                    return parent.valueSK.first!.id
                }
            } else {fatalError()}
        } else if isBrackets {
            return valueSK.last!.id
        } else {
            return op.id
        }
    }
    var innerIDWithRepCount: String {
        if isBrackets || isFraction {
            return valueSK.last!.titleAndRepcount
        } else if isSymb {
            return valueSK.first!.titleAndRepcount
        } else if isChild {
            return parent!.valueSK.first!.titleAndRepcount+String(idx!)
        } else {
            return "r\(idx!)"
        }
    }
//    var stepKeyIDandIdx: String {
//        if isBrackets || isFraction {
//            return valueSK.last!.id.uuidString
//        } else if isSymb {
//            return valueSK.first!.id.uuidString
//        } else if isChild {
//            return parent!.valueSK.first!.id.uuidString+String(idx)
//        } else {
//            return "s\(idx)"
//        }
//    }
    var staticIDs: [Int32] {
        [staticID] + children.staticIDs + power.staticIDs + (radicalParent?.staticIDs ?? []) 
    }
    func hasStaticIDsOverlap(staticIDs: [Int32]) -> Bool {
        self.staticIDs.contains(where: {staticIDs.contains($0)})
    }
    var cloneWithChangedStaticIDs: StepNode {
        let clone = self.clone(changeID: true, withParent: false)
        clone.changeStaticIDWithChildren()
        return clone
    }
    var reciprocalLevel: [StepNode] {
        let baseNode = baseNodeIfOneTerm
        if !baseNode.isInFraction {fatalError()}
        let fractionNode = baseNode.parentFraction!
        let isInNumerator = baseNode.isInNumerator
        return isInNumerator ? fractionNode.denominator : fractionNode.numerator
    }
    func hasSymbType(type: Key?) -> Bool {
        directSymbs.contains(where: {$0.type?.key == type})
    }
    var isNumberNotPoweredNotCoeff: Bool {
        isNumber(mayBePowered: false) && !isCoeff
    }
    var isAlone: Bool {
        level!.count == 1
    }
    var numeratorAndDenominator: [StepNode] {
        if !isFraction {fatalError()}
        return numerator+denominator
    }
    var otherPartOfTheFraction: [StepNode] {
        if !isInFraction {fatalError()}
        return isInNumerator ? parentFraction!.denominator : parentFraction!.numerator
    }
    var isOnlyEmptyStuff: Bool {
        if children.isEmptyOrSemiEmpty || children.flatKeys == [.minus] {return true}
        let clone = self.clone(changeID: false, withParent: false)
        var didChange = false
        repeat {
            didChange = false
            for node in clone.flatTree {
                if !node.exist {continue} // used to be: if !node.exist && !node.op.key == .pow {continue}
                if node.isFraction(.empty(for: .all)) || node.valueSK.isEmpty || node.valueKeys == [.minus] || node.valueSK.contains(where: {$0.key.isOpenBracket}) && (node.children.isSemiEmpty || node.children.isEmpty) {
                    if node.isSqrt && node.coeffNode.isOneSingleRadical {
                        node.coeffNode.remove()
                    } else {
                        node.remove()
                    }
                    didChange = true
                }
            }
        } while didChange
        return clone.children.isEmptyOrSemiEmpty
    }
    var isFractionDividable: Bool {
        isFraction(.single(simplest: false, for: .all)) && !numeratorAndDenominator.hasFraction(flat: true) && numerator.first!.isDividableBy(node: denominator.first!, mayEqual: true)
    }
    var numOrDenIsFractionDividable: Bool {
        if !isFraction {fatalError()}
        return numerator.first!.isFractionDividable || denominator.first!.isFractionDividable
    }
    var isFractionSingleWholeNumberNotMultipliedOrDivided: Bool {
        isFraction(.singleWholeNumber(mustBeReduced: false)) && !isMultipliedOrDivided
    }
    var willBeAddedToFraction: Bool {
        if isFractionSingleWholeNumberNotMultipliedOrDivided {} else {return false}
        let allFractions = (isChild ? level! : (root.children + (isEquation ? otherSide.children : []))).dropNode(node: self).filter({$0.isFractionSingleWholeNumberNotMultipliedOrDivided})
        if allFractions.isEmpty {return false}
        let sameSymbFractions = fractionNodesCommonTerm(in: allFractions)
        if sameSymbFractions.isEmpty {return false}
        let sameDenFractions = sameSymbFractions.filter({$0.denominator.first!.isEqualTo(node: self.denominator.first!)})
        if sameDenFractions.isEmpty {return false}
        let allNodes = sameDenFractions + [self]
        if !allNodes.contains(where: {!$0.isFractionDividable}) {return false} else {return true}
    }
    var denIsMultipleOrDividerOfOtherDens: Bool {
        if isFractionSingleWholeNumberNotMultipliedOrDivided {} else {return false}
        let allFractions = (isChild ? level! : (root.children + (isEquation ? otherSide.children : []))).dropNode(node: self).filter({$0.isFractionSingleWholeNumberNotMultipliedOrDivided})
        if allFractions.isEmpty {return false}
        let sameSymbFractions = fractionNodesCommonTerm(in: allFractions)
        if sameSymbFractions.isEmpty || sameSymbFractions.contains(where: {!$0.isFraction(.simplestReduced)}) {return false}
        if !sameSymbFractions.contains(where: {!$0.denominator.first!.valueDouble.isMultipleOrDivider(of: denominator.first!.valueDouble)}) {return true}
        else {return false}
    }
    var denIsMultipleOfAllDensAfterReduce: Bool {
        if isFractionSingleWholeNumberNotMultipliedOrDivided {} else {return false}
        let allFractions = (isChild ? level! : (root.children + (isEquation ? otherSide.children : []))).dropNode(node: self).filter({$0.isFractionSingleWholeNumberNotMultipliedOrDivided})
        if allFractions.isEmpty {return false}
        let sameSymbFractions = fractionNodesCommonTerm(in: allFractions)
        if sameSymbFractions.isEmpty {return false}
        let reducedSelf = reducedFractionIsolated
        if reducedSelf.isFraction {} else {return false}
        if !sameSymbFractions.contains(where: {!reducedSelf.denominator.first!.valueDouble.isMultiple(of: $0.denominator.first!.valueDouble)}) {return true}
        else {return false}
    }
    var isReducingEqualsAndNoLargerMultiples: Bool {
        if isFractionSingleWholeNumberNotMultipliedOrDivided {} else {return false}
        if reducedFractionIsolated.isOne {} else {return false}
        let allFractions = (isChild ? level! : (root.children + (isEquation ? otherSide.children : []))).dropNode(node: self).filter({$0.isFractionSingleWholeNumberNotMultipliedOrDivided})
        if allFractions.isEmpty {return false}
        let sameSymbFractions = fractionNodesCommonTerm(in: allFractions)
        if sameSymbFractions.isEmpty {return false}
        if sameSymbFractions.denominatorsFirsts.valuesDouble.contains(where: {$0.isMultiple(of: denominator.first!.valueDouble)}) {return false}
        else {return true}
    }
    var sqrtIsCeiling: Bool {
        if let parent = baseNode.parent {
            if parent.op.key == .sqrt {
                return true
            } else if baseNode.isInNumerator {
                return baseNode.parentFraction!.sqrtIsCeiling
            } else if parent.isBrackets {
                return parent.sqrtIsCeiling
            }
        }
        return false
    }
    var fractionDividerIsCeiling: Bool {
        if baseNode.isInDenominator {
            return true
        } else if baseNode.isInNumerator {
            return baseNode.parentFraction!.fractionDividerIsCeiling
        } else if let parent = baseNode.parent, parent.isBrackets {
            return parent.fractionDividerIsCeiling
        }
        return false
    }
    var hasDirectRadical: Bool {
        radicalParent != nil
    }
    var hasDirectI: Bool {
        directSymbs.contains(where: {$0.isSymbType(type: .imaginary)})
    }
    func hasDirectRadical(_ conditions: (StepNode) -> Bool) -> Bool {
        if let radicalParent = radicalParent {
            return conditions(radicalParent)
        }
        return false
    }
    var hasDirectDoubleRadical: Bool {
        if let radicalParent = radicalParent {
            return radicalParent.children.hasRadicalFlat && radicalParent.children.count == 1
        }
        return false
    }
    var isDoubleRadical: Bool {
        isSqrt && children.isOneSingleRadical && !children.first!.isPowered
    }
    var hasBeforeSymbsRadical: Bool {
        if let radicalParent = radicalParent {
            return radicalParent.isBeforeSymbs
        }
        return false
    }
    var hasAfterSymbsRadical: Bool {
        if let radicalParent = radicalParent {
            return radicalParent.isAfterSymbs
        }
        return false
    }
    var hasRadicalFlat: Bool {
        !allRadicalsFlat.isEmpty
    }
    func removeRadical() {
        if isSqrt {
            if coeffNode.isOneSingleTerm {
                coeffNode.remove()
            } else {
                remove()
            }
        } else {
            radicalParent = nil
        }
    }
    func removeTerms() {
        radicalParent = nil
        removeSymbs()
    }
    var shouldMergeTermWithPrev: Bool {
        if op.key == .pow || !exist {return false}
        if isOneTerm && !showOneTerm && isTimes {} else {return false}
//        if directSymbs.contains(where: {!$0.power.isSimplestForm}) {return false}
        if prev.isNumber(mayBePowered: true) && !prev.isDivide && !(hasDirectRadical && prev.hasDirectRadical || hasBeforeSymbsRadical && hasDirectSymbs && prev.isCoeff || hasDirectSymbs && prev.hasAfterSymbsRadical && prev.hasDirectSymbs || !(firstTerm!.nodeProduct?.isCommaNode ?? false) && !hasBeforeSymbsRadical && hasDirectSymbs && prev.directSymbs.last?.isSymbType(type: directSymbs.first!.type?.key) ?? false) {} else {return false}
        return true
    }
    func surfAndEvaluateAndApplyFnTillEnd() {
        if !isFraction {fatalError()}
        let calcBrain = CalcBrain()
        var fakeSteps = [StepModel()]
        let newRoot = StepNode()
        let clone = clone(changeID: false, withParent: false)
        newRoot.children = [clone]
        calcBrain.surfAndEvaluateAndApplyFnTillEnd(parent: newRoot, fnCtrl: [.skipPrintStep], &fakeSteps)
        self.content = clone.content
    }
    func reduceFraction() {
        if !isFraction {fatalError()}
        let calcBrain = CalcBrain()
        var fakeSteps = [StepModel()]
//        calcBrain.stepsInit(nodeL: self.root, nodeR: StepNode(), fnCtrl: [.skipPrintStep], steps: &fakeSteps)
        calcBrain.reduceFraction(node: self.multChainFirst, fnCtrl: [.force, .skipPrintStep], &fakeSteps)
    }
    func reduceFraction(fnCtrl: [FnCtrl]) {
        if !isFraction {fatalError()}
        let calcBrain = CalcBrain()
        var fakeSteps = [StepModel()]
        calcBrain.reduceFraction(node: self.multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep], &fakeSteps)
    }
    var isReducibleFraction: Bool {
        let clone = clone(changeID: false, withParent: true)
        clone.pinRootExpr()
        clone.reduceFraction()
        return clone.pinnedRootDidChange
    }
    var isReducibleFractionSkipSimplify: Bool {
        let clone = clone(changeID: false, withParent: true)
        clone.pinRootExpr()
        clone.reduceFraction(fnCtrl: [.skipReduceToSimplify])
        return clone.pinnedRootDidChange
    }
    var isReducibleIsolatedFraction: Bool {
        let fractionClone = clone(changeID: false, withParent: false)
        fractionClone.op = .plus
        let newRoot = StepNode()
        newRoot.children = [fractionClone]
        newRoot.pinRootExpr()
        fractionClone.reduceFraction(fnCtrl:  [.forceReduce])
        return newRoot.pinnedRootDidChange
    }
    var reducedFractionIsolated: StepNode {
        if !isFraction {fatalError()}
        let fractionClone = clone(changeID: false, withParent: false)
        fractionClone.op = .plus
        let newRoot = StepNode()
        newRoot.children = [fractionClone]
        newRoot.pinRootExpr()
        fractionClone.reduceFraction(fnCtrl: [.forceReduce])
        return fractionClone
    }
    func isRootable(indexValue: Double) -> Bool {
        isPoweredByWholeNumberOrNotPowered && (powerValue > 0 && powerValue.isMultiple(of: indexValue) || !(isTerm || isBrackets || isFraction) && !valueIsOne && pow(valueSK.getDouble, 1/indexValue).isWholeNumber) || isRootableFraction(indexValue: indexValue)
    }
    func isSimplifiableRadicand(indexValue: Double, isNotRootableIfMultiplied: Bool) -> Bool {
        if isSqrt || isDecimal || isFraction || !isPoweredByWholeNumberOrNotPowered || valueIsOne {return false}
        if isPowered {
            return powerValue > indexValue
        } else if !(isSymb || isBrackets) {
            if isNotRootableIfMultiplied && isRootableIfMultiplied {return false}
            if valueSK.getDouble > Double(Int.max)  {return false}
            let primeFactors = valueSK.getInt.primeFactors
            return primeFactors.map({factor in primeFactors.filter({$0 == factor}).count}).contains(where: {$0 >= Int(indexValue)})
        }
        return false
    }
    func rootableOrSimplifiableNodes(indexValue: Double) -> [StepNode] {
        if !isSqrt {fatalError()}
        var tmpToSqrtNodes = [StepNode]()
        for node in children {
            if node.isRootableFraction(indexValue: indexValue) {
                tmpToSqrtNodes.append(node)
            } else if node.isBrackets {
                if node.isRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false) {
                    tmpToSqrtNodes.append(node)
                }
            } else if !node.isFraction {
                if !node.valueIsOne && node.isRootable(indexValue: indexValue) || !node.parent!.coeffNode.isInSqrtGeneral && node.isSimplifiableRadicand(indexValue: indexValue, isNotRootableIfMultiplied: true) {
                    tmpToSqrtNodes.append(node)
                }
                for termNode in node.directTerms {
                    if termNode.isRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false) {
                        tmpToSqrtNodes.append(termNode)
                    }
                }
            }
        }
        return tmpToSqrtNodes
    }
    func rootableNodes(indexValue: Double) ->  [StepNode] {
        if !isSqrt {fatalError()}
        var tmpToSqrtNodes = [StepNode]()
        for node in children {
            if node.isBrackets {
                if node.isRootable(indexValue: indexValue) {
                    tmpToSqrtNodes.append(node)
                }
            } else if !node.isFraction {
                if !node.isTarget && !node.valueIsOne && node.isRootable(indexValue: indexValue) {
                    tmpToSqrtNodes.append(node)
                }
                for termNode in node.directTerms {
                    if termNode.isRootable(indexValue: indexValue) {
                        tmpToSqrtNodes.append(termNode)
                    }
                }
            }
        }
        return tmpToSqrtNodes
    }
    func isRootableFraction(indexValue: Double) -> Bool {
        if isFraction {
            if numeratorAndDenominator.hasOnlyNumbers && !isReducibleFractionSkipSimplify && !numeratorAndDenominator.hasRadicalNotSimplestFlat && (isAlone && isFraction(.simplest(for: .all)) || numeratorAndDenominator.hasRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false)) {
                return true
            }
        }
        return false
    }
    var isRootableIfMultiplied: Bool {
        guard let radicalParent = parent, radicalParent.isSqrt else {fatalError()}
        let indexValue = radicalParent.indexValue
        let nonRootables = level!.dropNode(node: self).onlyNumbers.filter({!$0.isRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false)})
        let calcBrain = CalcBrain()
        return nonRootables.contains(where: {pow(calcBrain.getResultByExecute(exprKeys: valueKeys+[.times]+$0.valueKeys, precision: 13), 1/indexValue).isWholeNumber})
    }
    func isRootableOrSimplifiable(indexValue: Double, isNotRootableIfMultiplied: Bool) -> Bool {
        isRootable(indexValue: indexValue) || isSimplifiableRadicand(indexValue: indexValue, isNotRootableIfMultiplied: isNotRootableIfMultiplied)
    }
    func extractPosAloneRadicalContent() {
        //
        if !isSqrt {fatalError()}
        if coeffNode.isPlus && coeffNode.isAlone && coeffNode.isOneSingleRadical && !isPowered {} else {fatalError()}
        
        //
        coeffNode.insertAfter(contentsOf: children)
        coeffNode.remove()
    }
    func extractRadicalContent() {
        var fakeMarkedKeys = [StepKey]()
        extractRadicalContent(markedKeys: &fakeMarkedKeys)
    }
    func extractRadicalContent(markedKeys: inout [StepKey]) {
        
        //
        if !isSqrt {fatalError()}
       
        //
        splitAtRadical(markedKeys: &markedKeys)
        
        //
        if children.count == 1 && !children.first!.isPowered {
            let newOneNode = StepNode.newOneNode
            newOneNode.content = children.first!.content
            if newOneNode.isMinus {
                newOneNode.setSelfToBrackets()
                markedKeys.append(contentsOf: newOneNode.valueSK)
            }
            newOneNode.op = coeffNode.op
            coeffNode.content = newOneNode.content
        } else {
            let newBrkts = StepNode.newBracketsNode
            newBrkts.children = children
            markedKeys.append(contentsOf: newBrkts.valueSK)
            newBrkts.op = coeffNode.op
            if (coeffNode.isPlus || newBrkts.children.isPlus) && (newBrkts.children.isHighOpChain || !coeffNode.isMultipliedOrDivided) {
                if newBrkts.children.isPlus {
                    newBrkts.children[0].op = coeffNode.op
                }
                coeffNode.insertAfter(contentsOf: newBrkts.children)
                coeffNode.remove()
            } else {
                coeffNode.content = newBrkts.content
//                markedKeys.append(newBrkts.op)
            }
        }
    }
    func cursorAtIndex(cursorKey: StepKey) -> Bool {
       isSqrt && (indexSK == [cursorKey] || cursorKey.key.isOpenCurlyBrkt)
    }
    var hasShownIndex: Bool {
        if !isSqrt {fatalError()}
        return indexSK.keys != [.two]
    }
    var isSimplestRadical: Bool {
        if !isSqrt {fatalError()}
        if isPowered {return false}
        return isSimplestRadicalMayBePowered
    }
    var isSimplestRadicalMayBePowered: Bool {
        if !isSqrt {fatalError()}
        let content = children
        if content.isSimplestFormMulti {return true}
        if !indexIsEven && content.isMinus && !content.hasVarFlat {return false}
        if !content.isSimplestForm {return false}
        if isRadVarInEqWithConditions {return true}
        if indexIsEven && content.isMinus {return true}
        for node in content {
            if node.isNumber(mayBePowered: false) {} else {return false}
            if node.directTerms.contains(where: {$0.isRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false)}) {return false}
            if node.valueIsOne || !node.isRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false) {} else {return false}
        }
        return true
    }
    func extractEachTerm() {
        if !isCoeff {return}
        for term in directTerms.reversed() {
            if valueIsOne && term.id == firstTerm!.id {return}
            let newOneNode = StepNode.newOneNode.withOp(.times)
            term.remove()
            if term.isSqrt {
                newOneNode.radicalParent = term
            } else {
                newOneNode.directSymbs = [term]
            }
            insertAfter(newOneNode)
        }
    }
    var hasDirectRadVar: Bool {
        if let radicalParent = radicalParent {
            return radicalParent.children.hasVarFlat
        }
        return false
    }
    var hasDirectRadVarOrNotVarX: Bool {
        if let radicalParent = radicalParent {
            return radicalParent.children.hasVarOrNotVarXFlat
        }
        return false
    }
    var hasDirectRadVarNoPow: Bool {
        if let radicalParent = radicalParent {
            return radicalParent.children.hasVarFlat && !radicalParent.children.flatTree.onlyVars.contains(where: {$0.isVar(firstDeg: false)})
        }
        return false
    }
    var has3RadicalParents: Bool {
        var radicalParentsCount = 0
        if isSqrt {radicalParentsCount += 1}
        if generalRadicalParent != nil {radicalParentsCount += 1} else {return false}
        if generalRadicalParent!.generalRadicalParent != nil {radicalParentsCount += 1}
        if generalRadicalParent!.generalRadicalParent?.generalRadicalParent != nil {radicalParentsCount += 1}
        return radicalParentsCount >= 3
    }
    var parentIndicesProduct: Int {
        if isSqrt {
            return indexInt*coeffNode.parentIndicesProduct
        } else if let generalRadicalParent = generalRadicalParent {
            return generalRadicalParent.indexInt * generalRadicalParent.coeffNode.parentIndicesProduct
        }
        return 1
    }
    var childrenOrGrandChildren: [StepNode] {
        if children.isBrackets {
            return children.first!.children
        } else {
            return children
        }
    }
    var selfOrChild: StepNode {
        if isBrktsNotSqrt {
            if children.count > 1 {fatalError()}
            return children.first!
        } else {
            return self
        }
    }
    var shouldReorderRadical: Bool {
        if hasDirectSymbs {} else {return false}
        if let radicalParent = radicalParent {
            return radicalParent.isBeforeSymbs && radicalParent.children.hasVarFlat || radicalParent.isAfterSymbs && !radicalParent.children.hasVarFlat && directSymbs.contains(where: {$0.isVar})
        }
        return false
    }
    func flipRadicalOrder() {
        if !isSqrt {fatalError()}
        if isAfterSymbs {
            isAfterSymbs = false
        } else {
            isAfterSymbs = true
        }
    }
    func hasSameIndex(with radParent: StepNode) -> Bool {
        indexInt == radParent.indexInt
    }
    var isSingleNode: Bool {
        if isTerm {fatalError()}
        return !isCoeff || isOneSingleTerm
    }
    func removeTimesFromTerm(markedKeys: inout [StepKey]) {
        markedKeys.append(op)
        pinRootExpr()
        removeTimesFromTerm()
        if !pinnedRootDidChange {
            markedKeys.removeLast()
        }
    }
    func removeTimesFromTerm() {
        guard shouldMergeTermWithPrev else {return}
        var prevIsOne = false
        if prev.isOne {
            prevIsOne = true
        }
        if let radicalParent = radicalParent {
            if prev.isCoeff {
                radicalParent.isAfterSymbs = true
            }
            prev.radicalParent = radicalParent
        }
        prev.directSymbs.append(contentsOf: directSymbs)
        if prevIsOne {
            prev.showOneTerm = true
        }
        remove()
    }
    func replaceOpValueSKWithSimilarKeys(_ stepKeys: [StepKey]) {
        var stepKeys = stepKeys
        op.matchToFirstEqualKey(In: &stepKeys)
        for i in 0..<valueSK.count {
            valueSK[i].matchToFirstEqualKey(In: &stepKeys)
        }
    }
    func replaceSimilarKeys(with flatSKs: [StepKey], withPow: Bool) {
        var flatSKs = flatSKs
        privateReplaceSimilarKeys(with: &flatSKs, exceptSKs: [], withPow: withPow)
    }
    func replaceSimilarKeys(with flatSKs: [StepKey], exceptSKs: [StepKey], withPow: Bool) {
        var flatSKs = flatSKs
        privateReplaceSimilarKeys(with: &flatSKs, exceptSKs: exceptSKs, withPow: withPow)
    }
    private func privateReplaceSimilarKeys(with flatSKs: inout [StepKey], exceptSKs: [StepKey], withPow: Bool) {
        let overlappingSKs = flatSKs.filter({self.flatSKs.contains($0)})
        flatSKs = flatSKs.dropSKs(overlappingSKs)
        let exceptSKs = exceptSKs + overlappingSKs
        for node in (withPow ? flatTree : flatTreeNoPow) {
            if !exceptSKs.contains(node.op) {
                node.op.matchToFirstEqualKey(In: &flatSKs)
            }
            if node.isOneTerm && !node.showOneTerm {continue}
            if !node.isSqrt {
                for i in 0..<node.valueSK.count {
                    if !exceptSKs.contains(node.valueSK[i]) {
                        node.valueSK[i].matchToFirstEqualKey(In: &flatSKs)
                    }
                }
            }
        }
    }
    var withOppiteSign: StepNode {
        if !isPlusOrMinus {fatalError()}
        return clone(changeID: false, withParent: false).withOp(isPlus ? .minus : .plus)
    }
    func hasConjugate(in nodes: [StepNode]) -> Bool {
        let firstBrackets = self
        if firstBrackets.children.count == 2 && firstBrackets.isBrackets(.distributeReady) {} else {return false}
        for secondBrackets in nodes.dropNode(node: firstBrackets) {
            if firstBrackets.isConjugate(of: secondBrackets) {return true} else {continue}
        }
        return false
    }
    func isConjugate(of node: StepNode) -> Bool {
        let firstBrackets = self
        let secondBrackets = node
        if firstBrackets.isBrackets(.distributeReady) && secondBrackets.isBrackets(.distributeReady) {} else {return false}
        if firstBrackets.children.count == 2 && secondBrackets.children.count == 2 {} else {return false}
        guard let firstOpposite = firstBrackets.children.first(where: {firstOpposite in secondBrackets.children.contains(where: {firstOpposite.isEqualTo(node: $0.withOppiteSign)})}) else {return false}
        guard let secondOpposite = secondBrackets.children.first(where: {$0.isEqualTo(node: firstOpposite.withOppiteSign)}) else {fatalError()}
        let firstEqual = firstBrackets.children.dropNode(node: firstOpposite).first!
        let secondEqual = secondBrackets.children.dropNode(node: secondOpposite).first!
        return firstEqual.isEqualTo(node: secondEqual)
    }
    func hasEqualNode(in nodes: [StepNode]) -> Bool {
        for node in nodes.dropNode(node: self) {
            if self.isEqualTo(node: node) {return true} else {continue}
        }
        return false
    }
    func hasEqualBase(in nodes: [StepNode]) -> Bool {
        for node in nodes.dropNode(node: self) {
            if self.hasEqualBase(with: node) {return true} else {continue}
        }
        return false
    }
    var isPowOrSqrt: Bool {
        op.key.isPowOrSqrt
    }
    var isPow: Bool {
        op.key == .pow
    }
    func dropPower(withParent: Bool) -> StepNode {
        let clone = clone(changeID: false, withParent: withParent)
        clone.removePower()
        return clone
    }
    func splitAtRadical() {
        var fakeMarkedKeys = [StepKey]()
        splitAtRadical(markedKeys: &fakeMarkedKeys)
    }
    func splitAtRadical(markedKeys: inout [StepKey]) {
        if !isSqrt {fatalError()}
        var radCoeff: StepNode {coeffNode}
        if isAfterSymbs || !radCoeff.valueIsOne {
            radCoeff.splitTermsAt(self)
        } else if radCoeff.hasDirectSymbs {
            radCoeff.extractSymbs()
        }
        if radCoeff.isTimes {
            markedKeys.append(radCoeff.op)
        }
    }
    var termMix: [StepNode] {
        var termMixArray = [StepNode]()
        if !isOneTerm {
            termMixArray.append(self)
        }
        let showRadBeforeSymbs = hasBeforeSymbsRadical
        if showRadBeforeSymbs {
            if let radicalParent = radicalParent {
                termMixArray.append(radicalParent)
            }
        }
        if hasDirectSymbs {
            termMixArray.append(contentsOf: directSymbs)
        }
        if !showRadBeforeSymbs {
            if let radicalParent = radicalParent {
                termMixArray.append(radicalParent)
            }
        }
        return termMixArray
    }
    var symbMix: [StepNode] {
        var symbMixArray = [StepNode]()
        symbMixArray.append(self)
        if hasDirectSymbs {
            symbMixArray.append(contentsOf: directSymbs)
        }
        return symbMixArray
    }
    func allowMerging(with cloneNodes: [StepNode]) -> Bool {
        if !isOneTerm && cloneNodes.contains(where: {!$0.hasEqualBase(with: self)}) {return false}
        if directTerms.contains(where: {origTerm in cloneNodes.contains(where: {!$0.directTerms.contains(where: {$0.hasEqualBase(with: origTerm)})})}) {return false}
        return true
    }
    func markedParent(markedKeys: [StepKey]) -> StepNode {
        let withEachTermExtracted = children.withEachTermExtracted.termMix.dropOneTerms
        for node in withEachTermExtracted {
            if node.opValueSK.overlaps(with: markedKeys) {
                return self.isFraction ? self.parent! : self
            } else if node.power.flatSKs.overlaps(with: markedKeys) {
                return node.powerParent!.markedParent(markedKeys: markedKeys)
            }
        }
        let containsMarkedNodes = withEachTermExtracted.filter({$0.flatSKs.overlaps(with: markedKeys)})
        if containsMarkedNodes.count > 1 {
            return self.isFraction ? self.parent! : self
        } else {
            if let potentialParent = containsMarkedNodes.first {
                return potentialParent.markedParent(markedKeys: markedKeys)
            }
            return self        }
    }
    func markedLevel(markedParent: StepNode) -> [StepNode] {
        markedParent.isRoot ? children : flatTree.first(where: {$0.staticID == markedParent.staticID && $0.opValueSK == markedParent.opValueSK})!.children
    }
    func theHigherLevel(with otherNode: StepNode) -> StepNode {
        otherNode.children.flatTree.contains(where: {$0.staticID == self.staticID && $0.opValueSK == self.opValueSK}) ? otherNode : self.children.flatTree.contains(where: {$0.staticID == otherNode.staticID && $0.opValueSK == otherNode.opValueSK}) ? self : otherNode
    }
    var dontHaveRootableAndWillHaveRootableOrSimplifiable: Bool {
        if !isSqrt {fatalError()}
        let childrenClonesRoot = children.clone(changeID: false, withParent: false)
        if childrenClonesRoot.children.hasRootable(indexValue: indexValue) {return false}
        let calcBrain = CalcBrain()
        var fakeSteps = [StepModel()]
        calcBrain.surfAndEvaluateTillEnd(parent: childrenClonesRoot, fnCtrl: [.force, .skipPrintStep], &fakeSteps)
        return childrenClonesRoot.children.hasRootableOrSimplifiable(indexValue: indexValue, isNotRootableIfMultiplied: false)
    }
    var multiplierNode: StepNode? {
        isTimes ? prev : next.isTimes ? next : nil
    }
    var numDenAreEqual: Bool {
        if !isFraction {fatalError()}
        return numerator.isEqualTo(nodes: denominator)
    }
    var childrenStr: String {
        children.flatSKs(.dropPlus).str
    }
    func resultDecimalFormTuple() -> (resultSKs: [StepKey], isApproximate: Bool, precision: Int) {
        let realResult = resultNoVarOrNotVarXValue(precision: 13)
        let positiveRealResult = abs(realResult)
        var precision = 7
        if positiveRealResult < 0.0001 && positiveRealResult.count > 11 {
            precision = 3
        } else if positiveRealResult < 0.001 {
            precision = 10
        } else if positiveRealResult < 0.01 {
            precision = 9
        } else if positiveRealResult < 0.1 {
            precision = 8
        }
        if positiveRealResult >= 1 && positiveRealResult.isFinite {
            let intDigits = Int(log10(positiveRealResult)) + 1
            if intDigits > precision {
                precision = intDigits + 3
            }
        }
        precision += (realResult < 0 ? 1 : 0)
        let roundedResult = resultNoVarOrNotVarXValue(precision: precision)
        return (roundedResult.newSKs, roundedResult != realResult, precision)
    }
    func resultNoVarOrNotVarXValue(precision: Int) -> Double {
        var keys = dropVarAndRadVar(dropNotVarX: true).getFlatSKsFromNode(forCursor: false, alwaysShowTimes: false, noRoots: false, withPows: true).keys
        keys.removeAll(where: {$0 == .plusMinus})
        let calcBrain = CalcBrain()
        return calcBrain.getResultByExecute(exprKeys: keys, precision: precision)
    }
    func powerKeys(equalTo keys: [Key]) -> Bool {
        power.flatSKs(.dropPlus).keys == keys
    }
    func setToBeHiddenOpIDsToZero() {
        for node in children.flatTree.filter({!($0.isTerm)}) {
            if node.level!.containsNode(node) && node.isFirst && node.op.key == .plus
                || !node.showTimesBeforeBrackets || node.isOneTermAfterFraction
                || node.isOneRadical && node.isTimes && !node.showOneTerm && !node.prev.isDivide {
                node.op.idIsZero = true
            }
        }
    }
    var isOneTermAfterFraction: Bool {
        isOneTerm && isTimes && prev.isFraction && !prev.isDivide
    }
    var parentIsRoot: Bool {
        parent == root
    }
    var isInDenominatorAndWillAddFractions: Bool {
        isInDenominator && level!.isMultChain && parentFraction!.level!.isMultiNotHighOpChain
    }
    func changeStaticIDForStepIncrement() {
        staticIDForStepIncrement = Int32.random
    }
    func changeStaticIDForStepIncIfOpChanged(with oldRoot: StepNode) {
        for node in flatTree {
            if let oldNode = oldRoot.flatTree.first(where: {$0.staticIDForStepIncrement == node.staticIDForStepIncrement}) {
                if node.op.key != oldNode.op.key {
                    node.changeStaticIDForStepIncrement()
                }
            }
        }
    }
    var isEvenNegRootNoVarOrNotVarX: Bool {
        if isSqrt && indexIsEven && !children.hasVarOrNotVarXFlat {} else {return false}
        if children.resultValue() < 0 {} else {return false}
        return true
    }
    func hasGCDTermWithBNotC(bNode: StepNode, cNode: StepNode) -> Bool {
        if directSymbs.isEmpty {return true}
        let bVarsWithoutCVars = bNode.directSymbs.filter({bVar in !cNode.directSymbs.contains(where: {$0.isSymbType(type: bVar.type?.key)})})
        guard directSymbs.count == bVarsWithoutCVars.count else {return false}
        for symbNode in bVarsWithoutCVars {
            guard let bNodeSymb = bNode.directSymbs.first(where: {$0.isSymbType(type: symbNode.type?.key)}) else {return false}
            guard let aNodeSymb = directSymbs.first(where: {$0.isSymbType(type: symbNode.type?.key)}) else {return false}
            if aNodeSymb.powerValue / bNodeSymb.powerValue != 2 {return false}
        }
        return true
    }
    func hasDuplicateAndNotPoweredByFraction(In nodes: [StepNode]) -> Bool {
        !power.hasFraction(flat: true) && nodes.dropNode(node: self).contains(where: {$0.hasEqualBase(with: self)})
    }
    var isRadVarInEqWithConditions: Bool {
        if !isSqrt {fatalError()}
        if hasVarFlat && isEquation {
            if children.hasFraction(flat: true) || allVars.hasPowered {return true}
            guard coeffNode.parentIsRoot else {return false}
            guard root.children.isSimplestFormNegletRadMulti || otherSide.children.isSimplestFormNegletRadMulti else {return true}
        }
        return false
    }
    var isBrktAloneInPoweredBrkt: Bool {
        isBracketsNotHidden && (parent?.isBrackets(.powered) ?? false) && isAlone
    }
    var radVarAssymptoteValues: [Double] {
        guard isSqrt && hasVarOrNotVarXFlat else {return []}
        if children.hasRadVarOrNotVarXFlat {return []}
        //
        let rootL = StepNode()
        rootL.children = children.allNotVarXReplacedWithX
        let rootR = StepNode(valueSK: [.typedEqual])
        rootR.isLeft = false
        rootR.children = [StepNode(valueKeys: [.zero])]
        //
        let calcBrain = CalcBrain()
        let fakeSteps = calcBrain.solveForX(nodeL: rootL, nodeR: rootR, shouldCheckEquality: true)
        if rootL.isIncomplete {return []}
        else if rootL.resultCase == .unableToSolve {return []}
        if fakeSteps.isEmpty {return []}
        guard rootL.children.isOneSingleVar(mayBeInSqrt: false) else {return []}
        if rootR.hasVarOrNotVarXFlat {return []}
        //
        let resultNodes = fakeSteps.getResultNodes
        return resultNodes.hasIFlat ? [] : resultNodes.map({$0.children.resultValue()})
    }
}
