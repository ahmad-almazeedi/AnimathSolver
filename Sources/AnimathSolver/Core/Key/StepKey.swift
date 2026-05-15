//
//  StepKeyModel.swift
//  Hulul
//
//  Created by Ahmad on 10/08/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

struct StepKey: Equatable, Hashable {
    
    static func ==(lhs: StepKey, rhs: StepKey) -> Bool {
        return lhs.id == rhs.id && lhs.key == rhs.key
    }
    
    var id: Int32
    var key: Key
    var repCount = 0
    
    private init(_ key: Key, id: Int32) {
        self.key = key
        self.id = id
    }
    private init(_ key: Key) {
        self.key = key
        id = Int32.random
    }
    
    static func stepKey(_ key: Key) -> StepKey {
        StepKey(key, id: Int32.random)
    }
    
    func withID(_ id: Int32) -> StepKey {
        var newSK = self
        newSK.id = id
        return newSK
    }
    func withKey(_ key: Key) -> StepKey {
        var newSK = self
        newSK.key = key
        return newSK
    }
}

extension StepKey {
    
    mutating func changeID() {
        id = Int32.random
    }
    var title: String {
        key.title
    }
    var newSK: StepKey {
        StepKey(key)
    }
    var priority: Int {
        key.getPriority
    }
    
    func isEqual(_ key: Key) -> Bool {
        self.key == key
    }
    func isEqualKey(_ stepKey: StepKey) -> Bool {
        self.key == stepKey.key
    }
    func isEqualSK(_ stepKey: StepKey) -> Bool {
        self.key == stepKey.key && self.id == stepKey.id
    }
    mutating func setRepCount(repKeys: inout [Key]) {
        repCount = repKeys.filter({$0 == key}).count
        repKeys.append(key)
    }
    mutating func flipSign() {
        if key.isPlus {
            self = .minus
        } else if key.isMinus {
            self = .plus
        } else {fatalError()}
    }
    
    var strikeKey: (key: StepKey, count: Int) {
        (self, 1)
    }
    
    mutating func matchToFirstEqualKey(In stepKeys: inout [StepKey]) {
        if let sameSK = stepKeys.first(where: {$0.key == self.key}) {
            self.id = sameSK.id
            stepKeys.removeAll(where: {$0.isEqualSK(sameSK)})
        }
    }
    var getInt: Int {
        Int(title)!
    }
    var getDouble: Double {
        Double(title)!
    }
    var titleAndRepcount: String {
        "\(title)\(repCount)"
    }
    var idIsZero: Bool {
        get {
            id == 0
        }
        set {
            if newValue {
                id = 0
            } else {
                id = Int32.random
            }
        }
    }
    func hashedID(hashedIDsTuples: [(Int32, Int8)]) -> Int8 {
        id.mapToHashedInt8(using: hashedIDsTuples)
    }
}

extension Array where Element == StepKey {
    var keys: [Key] {
        self.map({$0.key})
    }
    var keysWithRegulerBrkts: [Key] {
        keys.replaceHiddenBrkts
    }
    var newSKs: [StepKey] {
        keys.newSKs
    }
    var ids: [Int32] {
        self.map({$0.id})
    }
    var isEmpty: Bool {
        count == 0 || keys == [.typedEqual] || keys == [.notEqual]
    }
    var dropFirstIfPlus: [StepKey] {
        if let firstKey = first, firstKey.key == .plus {
            return [StepKey](self.dropFirst())
        }
        return self
    }
    var dropFirstIfNotTimes: [StepKey] {
        if self.first!.key != .times {
            return [StepKey](self.dropFirst())
        }
        return self
    }
    var dropFirstIfOp: [StepKey] {
        if !self.isEmpty && self.first!.key.isOp && self.first!.key != .sqrt {
            return [StepKey](self.dropFirst())
        }
        return self
    }
    var dropFirst: [StepKey] {
        [StepKey](dropFirst())
    }
    var dropLast: [StepKey] {
        [StepKey](dropLast())
    }
    func dropFirstIfOp(_ flag: Bool) -> [StepKey] {
        if flag && self.first!.key.isOp && self.first!.key != .sqrt {
            return [StepKey](self.dropFirst())
        }
        return self
    }
    
    var dropOps: [StepKey] {
        filter({!($0.key.isOp && $0.key != .sqrt)})
    }
    var dropSqrt: [StepKey] {
        filter({$0.key != .sqrt})
    }

    var str: String {
        var valueStr = ""
        for stepKey in self {
            valueStr += stepKey.title
        }
        return valueStr
    }
    
    var strForExpl: String {
        keys.strForExpl
    }
    var stringWithSinglePower: String {
        let tempExpr = self.keys
        var valueStr = ""
        var isInPower = false
        for x in 0..<tempExpr.count {
            if tempExpr[x] == .pow {
                isInPower = true
            } else {
                valueStr += isInPower ? tempExpr[x].powTitle! : tempExpr[x].title
            }
        }
        return valueStr
    }
    var getDouble: Double {
        let tempExpr = keys
//        if keys.contains(.questionMark) {return .infinity}
        var valueStr = ""
        for x in 0..<tempExpr.count {
            valueStr += tempExpr[x].title
        }
        valueStr = String(valueStr.map({$0 == "−" ? "-" : $0}))
        return Double(valueStr)!
    }
    var canBeInt: Bool {
        Int(str) != nil
    }
    var canBeDouble: Bool {
        Double(str) != nil
    }
    var getInt: Int {
        let value = getDouble
        if value != floor(value) {fatalError()}
        return Int(value)
    }
    mutating func changeIDs() {
        for i in 0..<self.count {
            self[i].changeID()
        }
    }
    var newNode: StepNode {
        var tempStepKeys = self
        var op = StepKey.plus
        if tempStepKeys.first!.key == .minus {
            op = tempStepKeys.first!
            tempStepKeys.removeFirst()
        }
        return StepNode(op: op, valueSK: tempStepKeys)
    }
    var withRepCount: [StepKey] {
        var tmpKeys = self
        var existingKeys = [Key]()
        for i in 0..<tmpKeys.count {
            tmpKeys[i].repCount = existingKeys.filter({$0 == tmpKeys[i].key}).count
            existingKeys.append(tmpKeys[i].key)
        }
        return tmpKeys
    }
    mutating func setRepCounts(repKeys: inout [Key]) {
        for i in 0..<count {
            self[i].setRepCount(repKeys: &repKeys)
        }
    }
    mutating func incRepCount(by increment: Int) {
        for i in 0..<count {
            self[i].repCount += increment
        }
    }
    mutating func replaceSimilarKeys(similarKeys: [StepKey]) {
        let overlappingSKs = similarKeys.filter({self.contains($0)})
        var tempSimiler = similarKeys.dropSKs(overlappingSKs).filter({!$0.isHiddenBracket && !self.ids.contains($0.id)})
        for x in 0..<self.count {
            if tempSimiler.contains(where: {self[x].key == $0.key}) {
                if !overlappingSKs.contains(self[x]) {
                    self[x] = tempSimiler.first(where: {$0.key == self[x].key})!
                    tempSimiler.removeAll(where: {$0 == self[x]})
                }
            }
        }
    }

    func overlaps(with otherStepKeys: [StepKey]) -> Bool {
        self.contains(where: {hisSK in otherStepKeys.contains(hisSK)})
    }
    var dropHiddens: [StepKey] {
        filter({$0.key != .pow && !$0.isHiddenBracket})
    }
    var dropBrackets: [StepKey] {
        filter({!$0.key.isBracket})
    }
    func dropSKs(_ stepKeys: [StepKey]) -> [StepKey] {
        filter({!stepKeys.contains($0)})
    }
    var onlyNumbersOrOpenCurlyBrkt: [StepKey] {
        filter({$0.key.isNumber || $0.key == .openCurlyBrkt})
    }
    var strikeKey: (key: StepKey, count: Int) {
        (self[self.count/2], self.count)
    }
    var dropPlusMinuses: [StepKey] {
        filter({$0.key != .plusMinus})
    }
    var dropPluses: [StepKey] {
        filter({$0.key != .plus})
    }
    var dropHighOps: [StepKey] {
        filter({!$0.key.isHighOp})
    }
    var getOps: [StepKey] {
        filter({$0.key.isOp})
    }
    var uniques: [StepKey] {
        Array(Set(self))
    }
    func hashedIDs(hashedIDsTuples: [(Int32, Int8)]) -> [Int8] {
        map({$0.hashedID(hashedIDsTuples: hashedIDsTuples)})
    }
    
    func matchedIDs(with ids: [Int32]) -> [StepKey] {
        filter{ids.contains($0.id)}
    }
}

extension Array where Element == StepKey {
    private func findExpressionRange(before index: Int) -> Range<Int>? {
        var start = index - 1
        let end = index - 1
        
        if start < 0 || self[start].key == .closeCurlyBrkt {
            return nil
        }

        var depth = 0
        while start >= 0 && (self[start].key.isOperand || self[start].key.isPowOrRoot || self[start].key.isCloseBracket || depth > 0 && self[start].key.isOpenBracket) {
            if self[start].key.isCustom {return nil}
            if self[start].key.isCloseBracket {
                depth += 1
            } else if self[start].key.isOpenBracket {
                depth -= 1
            }
            start -= 1
        }
        start += 1

        return start <= end ? start..<end + 1 : nil
    }

    private func findExpressionRange(after index: Int) -> Range<Int>? {
        let start = index + 1
        var end = index + 1
        
        if start >= self.count || self[start].key == .openCurlyBrkt {
            return nil
        }

        var depth = 0
        while end < self.count && (self[end].key.isOperand || self[end].key.isPowOrRoot || self[end].key.isOpenBracket || depth > 0 && self[end].key.isCloseBracket) {
            if self[end].key.isCustom {return nil}
            if self[end].key.isOpenBracket {
                depth += 1
            } else if self[end].key.isCloseBracket {
                depth -= 1
            }
            end += 1
        }
        end -= 1

        return start <= end ? start..<end + 1 : nil
    }

    private mutating func encloseExpression(within range: Range<Int>) {
        if self[range.lowerBound].key == .openBracket && self[range.upperBound - 1].key == .closeBracket {
            self[range.lowerBound].key = .openCurlyBrkt
            self[range.upperBound - 1].key = .closeCurlyBrkt
        } else {
            self.insert(.openCurlyBrkt, at: range.lowerBound)
            self.insert(.closeCurlyBrkt, at: range.upperBound + 1)
        }
    }
}

extension Array where Element == [StepKey] {
    var strs: [String] {
        map({$0.str})
    }
    var ids: [Int32] {
        flatMap({$0}).ids
    }
    var dropHiddens: [[StepKey]] {
        map{$0.dropHiddens}
    }
}
