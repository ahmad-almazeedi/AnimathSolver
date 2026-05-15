//
//  StepModel.swift
//  Hulul
//
//  Created by Ahmad on 6/25/20.
//  Copyright © 2020 Ahmad. All rights reserved.
//

import Foundation

struct StepModel {
    var dynamicExprs = [Expression()]
    var prevExprs = [Expression()]
    var explanation = ""
    var note = ""
    var nextExprs = [Expression()]
    var markedKeys = [StepKey]()
    var strikeKeys = [(key: StepKey, count: Int)]()
    var cloneIDs = [(originalKeyID: Int32, cloneMergeID: Int32)]()
    var mergeIDs = [(originalKeyID: Int32, cloneMergeID: Int32)]()
    var fadingKeysIDs = (fadingInIDs: [Int32](), fadingOutIDs: [Int32]())
    var inMainSteps = false
    var shouldShowMainStep = false
    var stepIdx = 0
    var parentStepIdx = 0
    var multiSubSteps = [[StepModel]()] {
        didSet {
            if oldValue[0].isEmpty && subSteps.count == 1 {
                subSteps[0].inMainSteps = false
                subSteps[0].strikeKeys.removeAll()
                subSteps[0].cloneIDs.removeAll()
                subSteps[0].mergeIDs.removeAll()
#if DEBUG
                subSteps[0].parentStepIdx = stepIdx
#endif
            }
        }
    }
    
    //
    func exprs(isPrev: Bool) -> [Expression] {
        isPrev ? prevExprs : nextExprs
    }
    var nodeL: StepNode {
        get {
            return prevExprs.first!.nodeL
        }
        set {
            prevExprs[0].nodeL = newValue
        }
    }
    var nodeR: StepNode {
        get {
            return prevExprs.first!.nodeR
        }
        set {
            prevExprs[0].nodeR = newValue
        }
    }
    var dynamicNodeL: StepNode {
        get {
            return dynamicExprs.first!.nodeL
        }
        set {
            dynamicExprs[0].nodeL = newValue
        }
    }
    var dynamicNodeR: StepNode {
        get {
            return dynamicExprs.first!.nodeR
        }
        set {
            dynamicExprs[0].nodeR = newValue
        }
    }
    var subSteps: [StepModel] {
        get {
            multiSubSteps.first!
        }
        set {
            multiSubSteps[0] = newValue
        }
    }
    var cloneMergeIDs: [(originalKeyID: Int32, cloneMergeID: Int32)] {
        cloneIDs + mergeIDs
    }
    
    var id: Int32 {
        nodeL.id
    }
    var staticID: Int32 {
        nodeL.staticID
    }
    
    var flatSKsTuple: ([StepKey],[StepKey]) {
        let flatSKsLHS = nodeL.getFlatSKsFromNode(forCursor: false, alwaysShowTimes: false, noRoots: false, withPows: true)
        let flatSKsRHS = nodeR.getFlatSKsFromNode(forCursor: false, alwaysShowTimes: false, noRoots: false, withPows: true)
        return(flatSKsLHS,flatSKsRHS)
    }
    func flatSKs(dropEqual: Bool) -> [StepKey] {
        prevExprs.flatSKs(dropEqual: dropEqual)
    }
    var allNodes: [StepNode] {
        nodeL.children+nodeR.children
    }
    
    var isEquation: Bool {
        !nodeR.isEmpty
    }
    var hasFraction: Bool {
        (nodeL.children+nodeR.children).hasFraction(flat: true)
    }
    var hasSubSteps: Bool {
        !subSteps.isEmpty
    }
    var hasOtherSteps: Bool {
        multiSubSteps.count > 1
    }
    var isEmpty: Bool {
        nodeL.isEmpty && explanation.isEmpty
    }
    var isLocalStep: Bool? {
        if exprs(isPrev: true).allSatisfy({!nodeL.isEmpty && $0.nodes.isEmpty}) {return true}
        if exprs(isPrev: true).allSatisfy({nodeL.isEmpty && !$0.nodes.isEmpty}) {return false}
        return nil
    }
    var isAIStep: Bool? {
        guard let isLocalStep = isLocalStep else {return nil}
        return !isLocalStep
    }
    
    // Save and load content
    func maxNestedFraction(substep: StepModel? = nil) -> Double {
        if exprHasLatexNodes {
            return prevExprs.nestedFractionCountForLatex + nextExprs.nestedFractionCountForLatex + (substep?.maxNestedFraction() ?? 0)
        } else {
            let maxNestedNumPrev = prevExprs.map({max($0.nodeL.maxNestedNumIgnorePow, $0.nodeR.maxNestedNumIgnorePow)}).max() ?? 0
            let maxNestedDenPrev = prevExprs.map({max($0.nodeL.maxNestedDenIgnorePow, $0.nodeR.maxNestedDenIgnorePow)}).max() ?? 0
            let maxNestedNumNext = nextExprs.map({max($0.nodeL.maxNestedNumIgnorePow, $0.nodeR.maxNestedNumIgnorePow)}).max() ?? 0
            let maxNestedDenNext = nextExprs.map({max($0.nodeL.maxNestedDenIgnorePow, $0.nodeR.maxNestedDenIgnorePow)}).max() ?? 0
            return maxNestedNumPrev + maxNestedDenPrev + maxNestedNumNext + maxNestedDenNext + (substep?.maxNestedFraction() ?? 0)
        }
    }
    func equationsLength(isPrev: Bool? = nil) -> Double {
        let prevLength = prevExprs.equationsLengthForStepNodes
        let nextLength = nextExprs.equationsLengthForStepNodes
        if let isPrev = isPrev {
            return isPrev ? prevLength : nextLength
        } else {
           return max(prevLength, nextLength)
        }
    }
    func markedSide(parentStep: StepModel) -> StepNode {
        markedKeys.overlaps(with: nodeL.children.flatSKs) || parentStep.markedKeys.overlaps(with: parentStep.nodeL.children.flatSKs) ? nodeL : nodeR
    }
    var clone: StepModel {
        var stepsClone = self
        stepsClone.nodeL = stepsClone.nodeL.clone(changeID: false, withParent: false)
        stepsClone.nodeR = stepsClone.nodeR.clone(changeID: false, withParent: false)
        return stepsClone
    }
    mutating func appendCloneIDs(originalKeysIDs: [Int32], clonesKeysIDs: [[Int32]]) {
        for cloneKeysIDs in clonesKeysIDs {
            cloneIDs.append(contentsOf: Array(zip(originalKeysIDs, cloneKeysIDs)))
        }
    }
    mutating func appendMergeIDs(originalKeysIDs: [Int32], mergesKeysIDs: [[Int32]]) {
        for mergeKeysIDs in mergesKeysIDs {
            mergeIDs.append(contentsOf: Array(zip(originalKeysIDs, mergeKeysIDs)))
        }
    }
    mutating func appendMergeIDs(mergeIDs: [(originalKeyID: Int32, cloneMergeID: Int32)]) {
        self.mergeIDs.append(contentsOf: mergeIDs)
    }
    
    mutating func appendCloneIDs(originalNode: StepNode, cloneNodes: [StepNode], withOp: Bool) {
        
        //
        if originalNode.allowMerging(with: cloneNodes) {} else {return}
        
        //
        if !originalNode.isOneTerm {
            if withOp {
                appendCloneIDs(originalKeysIDs: [originalNode.op.id], clonesKeysIDs: [cloneNodes.dropFirst(cloneNodes.isPlus).filter({$0.op.key == originalNode.op.key}).map({$0.op.id})])
            }
            appendCloneIDs(originalKeysIDs: originalNode.valueSK.ids, clonesKeysIDs: cloneNodes.map({$0.valueSK.ids}))
            appendCloneIDs(originalKeysIDs: originalNode.power.flatSKs.ids, clonesKeysIDs: cloneNodes.map({$0.power.flatSKs.ids}))
        }
        for origTerm in originalNode.directSymbs {
            appendCloneIDs(originalKeysIDs: origTerm.flatSKs.ids, clonesKeysIDs: cloneNodes.map({$0.directSymbs.first(where: {$0.hasEqualBase(with: origTerm)})!.flatSKs.ids}))
        }
        if let origRadicalParent = originalNode.radicalParent {
            appendCloneIDs(originalKeysIDs: origRadicalParent.flatSKs.ids, clonesKeysIDs: cloneNodes.map({$0.radicalParent!.flatSKs.ids}))
        }
    }
    fileprivate mutating func appendMergeIDs(originalNode: StepNode, mergeNodes: [StepNode], withOp: Bool) {
        if !originalNode.isOneTerm {
            if withOp {
                appendMergeIDs(originalKeysIDs: [originalNode.op.id], mergesKeysIDs: [mergeNodes.dropFirst(mergeNodes.isPlus).filter({$0.op.key == originalNode.op.key}).map({$0.op.id})])
            }
            appendMergeIDs(originalKeysIDs: originalNode.valueSK.ids, mergesKeysIDs: mergeNodes.map({$0.valueSK.ids}))
            appendMergeIDs(originalKeysIDs: originalNode.power.flatSKs.ids, mergesKeysIDs: mergeNodes.map({$0.power.flatSKs.ids}))
        }
        for origTerm in originalNode.directSymbs {
            appendMergeIDs(originalKeysIDs: origTerm.flatSKs.ids, mergesKeysIDs: mergeNodes.map({$0.directSymbs.first(where: {$0.hasEqualBase(with: origTerm)})!.flatSKs.ids}))
        }
        if let origRadicalParent = originalNode.radicalParent {
            appendMergeIDs(originalKeysIDs: origRadicalParent.flatSKs.ids, mergesKeysIDs: mergeNodes.map({$0.radicalParent!.flatSKs.ids}))
        }
    }
    mutating func removeAllMergedKeys(where shouldBeRemoved: ((originalKeyID: Int32, cloneMergeID: Int32)) -> (Bool)) {
        cloneIDs.removeAll(where: shouldBeRemoved)
    }
    var wholeExplanationCount: Int {
        explanation.count + note.count
    }
    func setToBeHiddenOpIDsToZero() {
        prevExprs.setToBeHiddenOpIDsToZero()
        nextExprs.setToBeHiddenOpIDsToZero()
    }
    var isEquationOrSemiEquation: Bool {
        !nodeR.isEmptyOrSemiEmpty && !(nodeR.children.isEmptyOrSemiEmpty || nodeR.isOnlyEmptyStuff || nodeL.isOnlyEmptyStuff)
    }
    var contentStr: String {
        let flatSKs =  flatSKs(dropEqual: false)
        let exprsStr = flatSKs.str
        let explanation = explanation + note
        let markedKeysStr = markedKeys.str
        let strikeKeysStr = strikeKeys.map({$0.key}).str
        let cloneMergeKeysStr = flatSKs.filter({cloneMergeIDs.map({[$0.originalKeyID, $0.cloneMergeID]}).flatMap({$0}).contains($0.id)}).str
        return exprsStr + ":" + explanation + ":" + (markedKeysStr.isEmpty ? "," : markedKeysStr) + ":" + (strikeKeysStr.isEmpty ? "," : strikeKeysStr) + ":" + (cloneMergeKeysStr.isEmpty ? "," : cloneMergeKeysStr)
        
    }
    var allSubSteps: [StepModel] {
        multiSubSteps.flatMap({$0})
    }
    mutating func setTitle(title: String, subtitle: String) {
        let newSubStep = StepModel(prevExprs: [Expression(nodeL: StepNode(), nodeR: StepNode(valueKeys: [.zero, .one]))], explanation: title, note: subtitle)
        multiSubSteps.append([newSubStep])
    }
    mutating func copyTitleFrom(titleStep: StepModel) {
        multiSubSteps.append([titleStep])
    }
    mutating func removeTitleStep() {
        multiSubSteps.removeAll(where: {$0.first?.isTitleStep ?? false})
    }
    var titleStep: StepModel? {
        guard let substeps = multiSubSteps.first(where: {$0.first?.isTitleStep ?? false}) else {return nil}
        return substeps.first!
    }
    var titleStepContentStr: String {
        guard let substeps = multiSubSteps.first(where: {$0.first?.isTitleStep ?? false}) else {return ""}
        return substeps.first!.explanation + " " + substeps.first!.note
    }
    var isTitleStep: Bool {
        nodeR.valueKeys == [.zero, .one]
    }
    var isUndefinedNodeStep: Bool {
        guard let valueSKFirst = nodeR.valueSK.first else {return false}
        return valueSKFirst.key == .notEqual && valueSKFirst.id.isOdd
    }
    var isNotTitleNorUndefStep: Bool {
        !isTitleStep && !isUndefinedNodeStep
    }
    var hasSplittedSteps: Bool {
        multiSubSteps.dropFirst().contains(where: {$0.last!.isNotTitleNorUndefStep})
    }
    var splittedSteps: [[StepModel]]? {
        let splittedSteps = [[StepModel]](multiSubSteps.dropUndefinedSteps.dropTitleSteps.dropFirst())
        return splittedSteps.isEmpty ? nil : splittedSteps
    }
    var exprHasLatexNodes: Bool {
        !(prevExprs.first?.nodes.isEmpty ?? true)
    }
    func nestedFractionMin(substep: StepModel? = nil) -> Double {
        let maxNestedFraction = maxNestedFraction(substep: substep)
        let divider = 10+(maxNestedFraction-7)/1.5
        return maxNestedFraction > 6 ? 1-(maxNestedFraction-6)/divider : 1
    }
    func explanationAndNote(aiSummary: String? = nil) -> String {
        explanation + (note.isEmpty ? "" : " \(note)") + (aiSummary ?? "")
    }
    var nextIsEmpty: Bool {
        nextExprs.isEmptyOrNodesEmpty
    }
    var isOverview: Bool {
        nextIsEmpty && explanation != Global.answerReachedStr
    }
}

extension Array where Element == StepModel {
    var beforeLastStep: StepModel {
        get {self[count-2]}
        set {self[count-2] = newValue}
    }
    var beforeLastStepFlat: StepModel {
        beforeLastStep.hasSubSteps ? beforeLastStep.subSteps.lastStep : beforeLastStep
    }
    var lastStep: StepModel {
        get {self.last!}
        set {self[count-1] = newValue}
    }
    var lastMarked: [StepKey] {
        get {last!.markedKeys}
        set {self[count-1].markedKeys = newValue}
    }
    var lastExplanation: String {
        get {last!.explanation}
        set {self[count-1].explanation = newValue}
    }
    var lastNote: String {
        get {last!.note}
        set {self[count-1].note = newValue}
    }
    var lastStepSubsteps: [StepModel] {
        get {last!.multiSubSteps.first!}
        set {self[count-1].multiSubSteps[0] = newValue}
    }
    var lastStepBeforeLastSplitStep: [StepModel] {
        get {last!.multiSubSteps.last(where: {$0.areNotTitleNorUndefNorEmptySteps && $0.first!.id != lastStepLastSplitStep.first!.id})!}
        set {
            let beforeLastSplitStepIdx = last!.multiSubSteps.lastIndex(where: {$0.areNotTitleNorUndefNorEmptySteps && $0.first!.id != lastStepLastSplitStep.first!.id})!
            self[count-1].multiSubSteps[beforeLastSplitStepIdx] = newValue
        }
    }
    var lastStepLastSplitStep: [StepModel] {
        get {last!.multiSubSteps.last(where: {$0.areNotTitleNorUndefNorEmptySteps})!}
        set {
            let lastSplitStepIdx = last!.multiSubSteps.lastIndex(where: {$0.areNotTitleNorUndefNorEmptySteps})!
            self[count-1].multiSubSteps[lastSplitStepIdx] = newValue
        }
    }
    var lastStepLastSubsteps: [StepModel] {
        get {last!.multiSubSteps.last!}
        set {self[count-1].multiSubSteps[last!.multiSubSteps.count-1] = newValue}
    }
    var lastMultiSubSteps: [[StepModel]] {
        get {last!.multiSubSteps}
        set {self[count-1].multiSubSteps = newValue}
    }
    var lastStrikeKeys: [(key: StepKey, count: Int)] {
        get {last!.strikeKeys}
        set {self[count-1].strikeKeys = newValue}
    }
    var lastCloneIDs: [(originalKeyID: Int32, cloneMergeID: Int32)] {
        get {last!.cloneIDs}
        set {self[count-1].cloneIDs = newValue}
    }
    var lastMergeIDs: [(originalKeyID: Int32, cloneMergeID: Int32)] {
        get {last!.mergeIDs}
        set {self[count-1].mergeIDs = newValue}
    }
    var allNodesFlat: [StepNode] {
        map({$0.allNodes}).flatMap({$0}).flatTree
    }
    var hasEvenRadVar: Bool {
        allNodesFlat.contains(where: {$0.hasDirectRadical && $0.radicalParent!.indexIsEven && $0.hasVarFlat})
    }
    mutating func setToUnableToSolve(nodeL: StepNode, nodeR: StepNode) {
        self[count-1].nodeL.resultCase = .unableToSolve
        self[count-1].nodeR.resultCase = .unableToSolve
        nodeL.resultCase = .unableToSolve
        nodeR.resultCase = .unableToSolve
    }
    mutating func setEquationIsTrue(nodeL: StepNode, nodeR: StepNode) {
        if varsAtStart.count > 1 {
            setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
        } else if varsAtStart.count == 1 {
            if allNodesFlat.contains(where: {$0.isSqrt && $0.children.hasVarFlat}) {
                setToUnableToSolve(nodeL: nodeL, nodeR: nodeL)
                return
            }
            let varStr = varsAtStart.first!.title
            lastExplanation = "The statement is true for any value of \(varStr), because both sides are identical"
            lastNote = "\(varStr) ∈ ℝ"
            self[count-1].nodeL.resultCase = .trueForAllX
            self[count-1].nodeR.resultCase = .trueForAllX
            nodeL.resultCase = .trueForAllX
            nodeR.resultCase = .trueForAllX
            let undefinedNodes = first!.multiSubSteps.getUndefinedNodes
            if !undefinedNodes.isEmpty {
                lastExplanation = "The statement is true for any value of \(varStr) except \(undefinedNodes.undefinedNodesStrWithAnd)"
                lastNote.append(contentsOf: " \\ {\(undefinedNodes.undefinedNodesAsSetStr)}")
            }
        } else {
            lastExplanation = "The equality is true because both sides are identical"
            self[count-1].nodeL.resultCase = .trueEq
            self[count-1].nodeR.resultCase = .trueEq
            nodeL.resultCase = .trueEq
            nodeR.resultCase = .trueEq
        }
        lastMarked = [.typedEqual] + nodeL.flatSKs + nodeR.flatSKs
        self[0].shouldShowMainStep = true
    }
    mutating func setEquationIsFalse(nodeL: StepNode, nodeR: StepNode) {
        if varsAtStart.count > 1 {
            setToUnableToSolve(nodeL: nodeL, nodeR: nodeR)
        } else if varsAtStart.count == 1 {
            lastExplanation = "The statement is false for any value of \(varsAtStart.first!.title)"
            lastNote = "No Solution"
            self[count-1].nodeL.resultCase = .falseForAnyX
            self[count-1].nodeR.resultCase = .falseForAnyX
            nodeL.resultCase = .falseForAnyX
            nodeR.resultCase = .falseForAnyX
        } else {
            lastExplanation = "The equality is false because the left-hand and right-hand sides are different"
            self[count-1].nodeL.resultCase = .falseEq
            self[count-1].nodeR.resultCase = .falseEq
            nodeL.resultCase = .falseEq
            nodeR.resultCase = .falseEq
        }
        lastMarked = [.typedEqual] + nodeL.flatSKs + nodeR.flatSKs
        self[0].shouldShowMainStep = true
    }
    mutating func setEquationIsFalseForRad(nodeL: StepNode, nodeR: StepNode) {
        lastExplanation = "The statement is false for any value of \(varsAtStart.first!.title) because the even root function is always positive or 0"
        lastNote = "No Solution"
        self[count-1].nodeL.resultCase = .falseForAnyX
        self[count-1].nodeR.resultCase = .falseForAnyX
        nodeL.resultCase = .falseForAnyX
        nodeR.resultCase = .falseForAnyX
        lastMarked = [.typedEqual] + nodeL.flatSKs + nodeR.flatSKs
        self[0].shouldShowMainStep = true
    }
    mutating func setEquationIsFalseForSpliSteps(nodeL: StepNode, nodeR: StepNode) {
        lastExplanation = "Since the equation is undefined for all of the given values, the equation has no solution"
        lastNote = "No Solution"
        self[count-1].nodeL.resultCase = .falseForAnyX
        self[count-1].nodeR.resultCase = .falseForAnyX
        nodeL.resultCase = .falseForAnyX
        nodeR.resultCase = .falseForAnyX
    }
    var clone: [StepModel] {
        var stepsClone = self
        for i in 0..<stepsClone.count {
            stepsClone[i].nodeL = stepsClone[i].nodeL.clone(changeID: false, withParent: false)
            stepsClone[i].nodeR = stepsClone[i].nodeR.clone(changeID: false, withParent: false)
        }
        return stepsClone
    }
    var showOnlySubSteps: Bool {
        count == 2 && !first!.subSteps.isEmpty && !first!.shouldShowMainStep
    }
    
    mutating func determineMarkedNodes() {
        for i in 0..<self.count {
            if self[i].hasSubSteps {
                self[i].subSteps.determineMarkedNodesForStep(self[i])
            }
        }
    }
    
    func setToBeHiddenOpIDsToZero() {
        for i in 0..<self.count {
            self[i].setToBeHiddenOpIDsToZero()
            for subSteps in self[i].multiSubSteps {
                subSteps.setToBeHiddenOpIDsToZero()
            }
        }
    }
    
    mutating func setFadingKeysIDs() {
        for i in 0..<count {
            if i > 0 {
                let flatSKsFadingInIDs = self[i].flatSKs(dropEqual: false).filter({newKey in !self[i-1].flatSKs(dropEqual: false).contains(where: {oldKey in oldKey.id == newKey.id && (oldKey.key == newKey.key || oldKey.key.isFractionOrDivide && newKey.key.isFractionOrDivide)})}).ids
                self[i].fadingKeysIDs.fadingInIDs.append(contentsOf: flatSKsFadingInIDs.filter({!self[i-1].cloneMergeIDs.map({$0.cloneMergeID}).contains($0)}))
            }
            if i < count-1 {
                var nextWholeExpr = self[i+1].flatSKs(dropEqual: false)
                if self[i].hasSplittedSteps && self[i+1].hasSplittedSteps {
                    nextWholeExpr = self[i+1].splittedSteps!.map({$0.first!.flatSKs(dropEqual: false)}).flatMap({$0})
                }
                let flatSKsFadingOutIDs = self[i].flatSKs(dropEqual: false).filter({oldKey in !nextWholeExpr.contains(where: {newKey in newKey.id == oldKey.id && (newKey.key == oldKey.key || newKey.key.isFractionOrDivide && oldKey.key.isFractionOrDivide)})}).ids
                self[i].fadingKeysIDs.fadingOutIDs.append(contentsOf: flatSKsFadingOutIDs.filter({!self[i+1].cloneMergeIDs.map({$0.cloneMergeID}).contains($0)}))
            }
            for j in 0..<self[i].multiSubSteps.count {
                if count > 1 && self[i].multiSubSteps[j].areNotTitleNorUndefNorEmptySteps {} else {continue}
                self[i].multiSubSteps[j].setFadingKeysIDs()
                if i == count-2 && j > 0 {
                    if !self[i+1].multiSubSteps.dropFirst().contains(where: {self[i].multiSubSteps[j].last!.staticID == $0.first!.staticID}) {
                        if self[i].multiSubSteps.count > 2 {} else {continue}
                        if j == 1 {
                            self[i].multiSubSteps[j+1].beforeLastStep.fadingKeysIDs.fadingOutIDs.append(self[i].multiSubSteps[j+1].beforeLastStep.nodeL.staticID)
                        } else {
                            self[i].multiSubSteps[j].beforeLastStep.fadingKeysIDs.fadingOutIDs.append(self[i].multiSubSteps[j].beforeLastStep.nodeL.staticID)
                        }
                        if self[i].splittedSteps!.last!.first!.id == self[i].multiSubSteps[j].first!.id {
                            self[i].multiSubSteps[j].beforeLastStep.fadingKeysIDs.fadingOutIDs.append(contentsOf: self[i].multiSubSteps[j].beforeLastStep.flatSKs(dropEqual: false).ids)
                        } else {
                            self[i].multiSubSteps[j].lastStep.fadingKeysIDs.fadingOutIDs.append(contentsOf: self[i].multiSubSteps[j].lastStep.flatSKs(dropEqual: false).ids)
                        }
                    }
                } else if i == count-1 && j == self[i].multiSubSteps.count-1 && self[i].multiSubSteps[j].count == 1 && self[i-1].multiSubSteps.count == self[i].multiSubSteps.count && self[i-1].multiSubSteps[j].count > 1 {
                    // Fixing no fadeIn in last splitStep
                    let flatSKsFadingInIDs = self[i].multiSubSteps[j][0].flatSKs(dropEqual: false).filter({newKey in !self[i-1].multiSubSteps[j].beforeLastStep.flatSKs(dropEqual: false).contains(where: {oldKey in oldKey.id == newKey.id && (oldKey.key == newKey.key || oldKey.key.isFractionOrDivide && newKey.key.isFractionOrDivide)})}).ids
                    self[i].multiSubSteps[j][0].fadingKeysIDs.fadingInIDs.append(contentsOf: flatSKsFadingInIDs.filter({!self[i-1].multiSubSteps[j].beforeLastStep.cloneMergeIDs.map({$0.cloneMergeID}).contains($0)}))
                }
            }
        }
    }
    
    private mutating func determineMarkedNodesForStep(_ parentStep: StepModel) {
        
        // return if equation
        if self.count <= 1 || self[1].nodeL.children.flatSKs.overlaps(with: first!.markedKeys) && self[1].nodeR.children.flatSKs.overlaps(with: first!.markedKeys) {return}
        if self.count > 1 && !first!.isEquation && self[1].isEquation {return}
        
        // determine all markedKeys
        var generalMarkedKeys = self.allMarkedKeys + parentStep.markedKeys
        let isEvaluatingPowerOrDividingExponents = parentStep.explanation == "Evaluate the power" || self[0...1].map({$0.explanation}).contains(where: {$0.contains("subtracting their exponents")})
        if parentStep.explanation == "Calculate the product" {
            generalMarkedKeys.insert(.dot, at: 0)
        }
        
        //
        let firstStepMarkedParent = first!.markedSide(parentStep: parentStep).markedParent(markedKeys: parentStep.markedKeys)
        let lastStepMarkedParent = last!.markedSide(parentStep: parentStep).markedParent(markedKeys: generalMarkedKeys)
        let markedParent = firstStepMarkedParent == lastStepMarkedParent ? firstStepMarkedParent : firstStepMarkedParent.theHigherLevel(with: lastStepMarkedParent)
        let markedLevelWithEachTermExtracted = first!.markedSide(parentStep: parentStep).markedLevel(markedParent: markedParent).withEachTermExtracted
        let filteredMarkedKeys = parentStep.markedKeys.dropOps.dropHiddens.filter({markedKey in markedLevelWithEachTermExtracted.flatSKs.contains(markedKey)}) + first!.markedKeys.dropOps.dropHiddens.filter({markedKey in markedLevelWithEachTermExtracted.flatSKs.contains(markedKey)})
        let tmpMarkedNodes = markedLevelWithEachTermExtracted.filter({$0.flatSKs.overlaps(with: filteredMarkedKeys)})
        let shouldGetOnlyMarked = !parentStep.explanation.contains("Cancel out the common factor")
        ||
        firstStepMarkedParent == lastStepMarkedParent && tmpMarkedNodes.count == 1
        || lastStepMarkedParent == markedParent && !lastStepMarkedParent.children.staticIDs.contains(firstStepMarkedParent.staticID) && firstStepMarkedParent.valueKeys.contains(.openBracket)
        || !tmpMarkedNodes.flatSKs.dropOps.dropHiddens.contains(where: {markedNodeKey in !filteredMarkedKeys.contains(markedNodeKey)})
        || !filteredMarkedKeys.contains(where: {markedKey in !markedLevelWithEachTermExtracted.opValuesSKpows.contains(markedKey)})
        
        //
        for i in 0..<self.count {
            let markedLevel = self[i].markedSide(parentStep: parentStep).markedLevel(markedParent: markedParent)
            var markedNodes = shouldGetOnlyMarked ? markedLevel.getMarkedNodes(markedKeys: generalMarkedKeys) : markedLevel.clone(changeID: false, withParent: false).children
            if markedNodes.count <= 1 && markedNodes.isBrackets(.notPowered) {
                markedNodes = markedNodes.first!.children
            }
            if !markedNodes.isPlusOrMinus || isEvaluatingPowerOrDividingExponents {
                markedNodes[0].op = .plus
            }
            let newRoot = StepNode().withChildren(children: markedNodes)
            self[i].nodeR = StepNode()
            self[i].nodeL = newRoot
        }
    }
    var varsAtStart: [Key] {first!.nodeL.isEquation ? (first!.nodeL.children+first!.nodeR.children).uniqueSymbs(flat: true).filter({!$0.isComma && $0 != .pi && $0 != .euler}) : []}
    var allMarkedKeys: [StepKey] {
        map({$0.markedKeys}).flatMap({$0})
    }
    var hasNodeWithVeryLargeValue: Bool {
        allNodesFlat.contains(where: {!$0.isSymb && !$0.valueKeys.contains(.questionMark) && $0.isNumber(mayBePowered: false) && $0.valueDouble >= 10000000000000000})
    }
    var getResultNodes: [StepNode] {
        if contains(where: {$0.splittedSteps != nil}) {
            return last!.prevExprs.map({$0.nodeR})
        } else {
            let varIsFound = last!.isEquationOrSemiEquation && last!.nodeL.children.count == 1
            let toShowExpr = varIsFound ? last!.nodeR : isEmpty ? StepNode.newZeroNode.parent! : last!.nodeL
            return [toShowExpr]
        }
    }
    
    var isEquationWithMainVar: Bool {
        !isEmpty && last!.isEquationOrSemiEquation && last!.nodeL.children.isOneSingleVar(mayBeInSqrt: true) && !last!.nodeL.children.first!.hasDirectRadical
    }
    mutating func splitNodeIntoTwoNodes(node: StepNode, split1: StepNode, split2: StepNode) {
        if !node.valueIsOne {
            [split1, split2].replaceSimilarKeys(with: node.valueSK, withPow: false)
            lastStep.appendCloneIDs(originalKeysIDs: node.valueSK.filter({origSK in !split1.valueSK.contains(origSK)}).ids, clonesKeysIDs: [split1.valueSK.filter({cloneSK in !node.valueSK.contains(cloneSK)}).ids])
            if node.valueKeys.overlaps(with: split2.valueKeys) {
                lastStep.appendCloneIDs(originalKeysIDs: node.valueSK.filter({origSK in !split2.valueSK.contains(origSK)}).filter({origSK in split2.valueKeys.contains(origSK.key)}).ids.reversed(), clonesKeysIDs: [split2.valueSK.filter({cloneSK in !node.valueKeys.contains(cloneSK.key)}).ids])
            } else {
                lastStep.appendCloneIDs(originalKeysIDs: node.valueSK.filter({origSK in !split2.valueSK.contains(origSK)}).ids.reversed(), clonesKeysIDs: [split2.valueSK.filter({cloneSK in !node.valueSK.contains(cloneSK)}).ids])
            }
        }
    }
    mutating func appendMactchedMarkedKeysOfLastSubStepWithMain(mainWholeExpr: [StepKey]) {
        var markIdxs = [Int]()
        let markedKeys = last!.markedKeys
        for i in 0..<mainWholeExpr.count {
            if markedKeys.contains(mainWholeExpr[i]) {
                markIdxs.append(i)
            }
        }
        let lastSubStepWholeExpr = lastStepSubsteps.last!.flatSKs(dropEqual: true)
        for idx in markIdxs {
            lastStep.markedKeys.append(lastSubStepWholeExpr[idx])
        }
    }
    var dropRedundants: [StepModel] {
        var existingSteps = [StepModel]()
        for step in self {
            if existingSteps.contains(where: {$0.flatSKs(dropEqual: false).keys == step.flatSKs(dropEqual: false).keys}) {continue}
            existingSteps.append(step)
        }
        return existingSteps
    }
    var absLastSteps: [StepModel] {
        if let splittedSteps = last!.splittedSteps {
            return splittedSteps.map({$0.last!})
        } else {
            return [last!]
        }
    }
    var hasSplittedSteps: Bool {
        last!.splittedSteps != nil
    }
    var areNotTitleNorUndefNorEmptySteps: Bool {
        !isEmpty && last!.isNotTitleNorUndefStep
    }
    func dropLast(_ flag: Bool) -> [StepModel] {
        flag ? dropLast() : self
    }
    mutating func appendMergeIDs(originalKeysIDs: [Int32], mergesKeysIDs: [[Int32]]) {
        lastStep.appendMergeIDs(originalKeysIDs: originalKeysIDs, mergesKeysIDs: mergesKeysIDs)
        if count > 1 {
            replaceDuplicateMergedKeyForMerge()
        }
    }
    mutating func appendMergeIDs(mergedIDs: [(originalKeyID: Int32, cloneMergeID: Int32)]) {
        lastStep.appendMergeIDs(mergeIDs: mergedIDs)
        if count > 1 {
            replaceDuplicateMergedKeyForMerge()
        }
    }
    mutating func appendMergeIDs(originalNode: StepNode, mergeNodes: [StepNode], withOp: Bool) {
        lastStep.appendMergeIDs(originalNode: originalNode, mergeNodes: mergeNodes, withOp: withOp)
        if count > 1 {
            replaceDuplicateMergedKeyForMerge()
        }
    }
    private mutating func replaceDuplicateMergedKeyForMerge() {
        while let toChangeMergeIDIdx = last!.mergeIDs.firstIndex(where: {mergeID in last!.flatSKs(dropEqual: false).ids.contains(mergeID.cloneMergeID)}) {
            let newId = Int32.random
            let existingKeyID = last!.mergeIDs[toChangeMergeIDIdx].cloneMergeID
            beforeLastStep.appendCloneIDs(originalKeysIDs: [existingKeyID], clonesKeysIDs: [[newId]])
            lastStep.mergeIDs[toChangeMergeIDIdx].cloneMergeID = newId
        }
        var newMergeTuples = last!.mergeIDs
        while let newMergeWithOldOriginalAsAMerge = newMergeTuples.first(where: {newMerge in
            beforeLastStep.mergeIDs.map({$0.originalKeyID}).contains(newMerge.cloneMergeID)
        }) {
            newMergeTuples.removeAll(where: {$0.originalKeyID == newMergeWithOldOriginalAsAMerge.originalKeyID && $0.cloneMergeID == newMergeWithOldOriginalAsAMerge.cloneMergeID})
            while let newMergeWithOldOriginalAsOriginalIdx = last!.mergeIDs.firstIndex(where: {newMerge in
                newMerge.originalKeyID == newMergeWithOldOriginalAsAMerge.cloneMergeID
            }) {
                lastStep.mergeIDs[newMergeWithOldOriginalAsOriginalIdx].originalKeyID = newMergeWithOldOriginalAsAMerge.originalKeyID
            }
        }
    }
    func changeStaticIDsForStepIncrementIfLong(viewSize: CGSize) {
        let exprMaxLength = viewSize.forDim(.exprMaxLength)
        if contains(where: {$0.nestedFractionMin() < 1}) || hasLongExpr(exprMaxLength: exprMaxLength) {
            allStepsFlat.changeStaticIDsForStepInc()
        }
        for step in allStepsFlat {
            if step.hasSubSteps {
                if step.subSteps.hasLongExpr(exprMaxLength: exprMaxLength*(showOnlySubSteps ? 1 : 0.95)) {
                    [StepModel](step.subSteps.dropFirst()).changeStaticIDsForStepInc()
                }
            }
        }
    }
    func hasLongExpr(exprMaxLength: CGFloat) -> Bool {
        for i in 0..<count {
            if currentStep([i]).equationsLength() < exprMaxLength {continue}
            return true
        }
        return false
    }
    func changeStaticIDsForStepInc() {
        for step in self {
            step.nodeL.flatTree.changeStaticIDsForStepIncrement()
            step.nodeR.flatTree.changeStaticIDsForStepIncrement()
        }
    }
    var mixedWithSubsteps: [StepModel] {
        map({[$0] + $0.subSteps}).flatMap({$0})
    }
    var hasWrongSolution: Bool {
        last!.nodeR.valueSK.first!.key == .notEqual
    }
    var undefinedNodesSet: [StepNode] {
        if !isEmpty && first!.multiSubSteps.count > 1 {} else {return []}
        let nodes = first!.multiSubSteps.getUndefinedNodes
        var repKeys = [Key]()
        for node in nodes {
            node.setRepCount(repKeys: &repKeys)
        }
        return nodes
    }
    var hasEmpty: Bool {
        contains(where: {$0.isEmpty})
    }
    func firstOrLast(isPrev: Bool) -> StepModel? {
        return isPrev ? first : last
    }
    var isEmptyFromRealSteps: Bool {
        isEmpty
    }
    var solutionStep: StepModel? {
        hasSolutionStep ? last : nil
    }
    var mainOrSubsteps: [StepModel] {
        showOnlySubSteps ? first!.subSteps : self
    }
}

extension Array where Element == [StepModel] {
    var dropRedundants: [[StepModel]] {
        var existingMultiSteps = [[StepModel]]()
        for steps in self {
            let step = steps.last!
            if existingMultiSteps.contains(where: {$0.last!.flatSKs(dropEqual: false).keys == step.flatSKs(dropEqual: false).keys}) {continue}
            existingMultiSteps.append(steps)
        }
        return existingMultiSteps
    }
    var getUndefinedSteps: [StepModel] {
        [[StepModel]](dropFirst()).filter({$0.last!.isUndefinedNodeStep && $0.last!.nodeL.resultCase != .falseForAnyX}).map({$0.last!}).dropRedundants
    }
    var getUndefinedNodes: [StepNode] {
        [[StepModel]](dropFirst()).filter({$0.last!.isUndefinedNodeStep && $0.last!.nodeL.resultCase != .falseForAnyX}).map({$0.getResultNodes.first!}).dropRedundants(ignoreOp: false)
    }
    var flatForSplittedSteps: [StepModel] {
        let lastID = last!.first!.id
        return map({$0.first!.id == lastID ? $0 : [StepModel]($0.dropLast())}).flatMap({$0})
    }
    var dropUndefinedSteps: [[StepModel]] {
        filter({$0.isEmpty || !$0.last!.isUndefinedNodeStep})
    }
    var dropTitleSteps: [[StepModel]] {
        filter({$0.isEmpty || !$0.last!.isTitleStep})
    }
    var dropWrongSolutions: [[StepModel]] {
        filter({!$0.hasWrongSolution})
    }
    var onlyWrongSolutions: [[StepModel]] {
        filter({$0.hasWrongSolution})
    }
    var hasWrongSolution: Bool {
        contains(where: {$0.hasWrongSolution})
    }
}
