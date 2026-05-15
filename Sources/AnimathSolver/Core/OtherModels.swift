//
//  OtherModels.swift
//  Hulul
//
//  Created by Ahmad on 02/06/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

enum FnCtrl {
    case forceFlatSubsteps, skipEqualityCheck, skipDistribute, skipDistributeEval, skipAddition, skipReduceToSimplify, skipRemoveOneTimesBrkt, skipMergeFraction, force, targetOnly, skipPrintStep, skipCommonFactor, forceMoveMinusOut, forceMerge, forceMergeWithBrkt, forceFractionAddition, checkAllowed, skipSymbMultOrOrder, skipAppendStep, forcePowerAddition, forceReduce, forceDistribute, forceReduceToOne, skipReduceExponentiable, skipReduce, forceConvertNestedFraction, skipReduceDivisible, keepTargets, forceConvertToDecimal, divBothForHighDegOrNoBrkt, extractCmnFctrFromRight, forceCancelOppositeTerms, skipCancelIfWillRemain, lowCostSolve, skipRemoveUslessBrackets, skipRemoveUslessBrktsWithMultiChild, skipMultBothSidesBySingleCheck, noFractionAfterMoveCoeffTrue, noFractionAfterMoveCoeffFalse, skipPow, skipFlattenning, forceConvertDecimalToFraction, moreCertainForceConvertDecimalToFraction, forceFlipSigns, skipRationalizeDen, forceRadVarEval, skipRadicalEval, skipRadicalSimplifying, skipRemoveTimesFromTerms, skipRemoveDenIfOne, forceRemoveTimesFromTerms, skipRemoveTimesOne, forceSkip, setInMainSteps, forceExtractMinus, skipAllExceptFctrBrkt, skipCopyStepTitle, skipReduceSameFraction, justRemoveBrktInRmvUslsBrkt, forceMergeRadWithDiffIdx, skipMergeSameBaseIfAlone, skipRootBothSidesCheck, skipMergeKeysPassing, skipRootSidesOrSolveNonLinear, skipSetNegRootToUndef, forceRationalizeDen, splitRadicalFromEnd, isInSplittedSteps, skipMergeI, skipMergedKeysInCheckSolution, isInUndefinedSteps, skipExtractI, skipDivToFracIfDividedHasFraction, skipExtractCommonFactor, forceSetNegRootToUndefCheck, reduceAfterFctrPoly, forceDivideBothSides, forceConvNegExp, forceRemoveTimesZero, isInCheckingOurAnswer, skipMergeSameBaseInSqrtIfHasNonRootable, forceEvaluateNthPowerInNthRoot, skipCancelEqualTerms, semiForceEvalPow, targetToSkipPowOnly
}

extension Array where Element == FnCtrl {
    var isForced: Bool {
        contains(.force)
    }
    var targetOnly: Bool {
        contains(.targetOnly)
    }
    var skipPrintStep: Bool {
        contains(.skipPrintStep)
    }
    var isCheckAllowed: Bool {
        contains(.checkAllowed)
    }
    var isKeepTargets: Bool {
        contains(.keepTargets)
    }
    var isSkipAppendStep: Bool {
        contains(.skipAppendStep)
    }
    var isLowCost: Bool {
        contains(.lowCostSolve)
    }
    func drop(_ singleFnCntrl: FnCtrl) -> [FnCtrl] {
        filter({$0 != singleFnCntrl})
    }
}

extension CGFloat {
    func str(precision: Int) -> String {
        Double(self).str(precision: precision)
    }
    func range(min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(Swift.min(self, maxValue), minValue)
    }
    func flip(_ flag: Bool) -> CGFloat {
        flag ? -self : self
    }
}

extension Double {
    var keys: [Key]? {
        var tempTempValue: String {
            if String(self).hasSuffix(".0") {
                return String(String(self).dropLast().dropLast())
            } else {
                return String(self).replacingOccurrences(of: "inf", with: "∞")
            }
        }
        var tempValue = tempTempValue
        var tempExpr = [Key]()
        while !tempValue.isEmpty {
            if tempValue.hasPrefix("e+") {
                tempValue = String(tempValue.dropFirst().dropFirst())
                var exponent = Int(tempValue)!
                if tempExpr.contains(.dot) {
                    exponent = exponent - tempExpr.split(separator: .dot).last!.count
                    tempExpr.removeAll(where: {$0 == .dot})
                }
                for _ in 0..<exponent {
                    tempExpr.append(.zero)
                }
                break
            } else if tempValue.hasPrefix("e-") {
                tempValue = String(tempValue.dropFirst().dropFirst())
                let exponent = Int(tempValue)!
                if tempExpr.contains(.dot) {
                    if tempExpr[1] != .dot && !(tempExpr.first!.isMinus && tempExpr[2] == .dot) {return nil}
                    tempExpr.removeAll(where: {$0 == .dot})
                }
                let insertIdx = (tempExpr.first?.isMinus ?? false) ? 1 : 0
                for _ in 0..<(exponent-1) {
                    tempExpr.insert(.zero, at: insertIdx)
                }
                tempExpr.insert(contentsOf: [.zero, .dot], at: insertIdx)
                break
            } else if tempValue.first != "+" {
                guard let tempValueFirst = tempValue.first!.key else {return nil}
                tempExpr.append(tempValueFirst)
            }
            tempValue = String(tempValue.dropFirst())
        }
        return tempExpr
    }
    var newSKs: [StepKey] {
        keys!.newSKs
    }
    var newNode: StepNode {
        StepNode(opKey: opKey, valueKeys: abs(self).keys!)
    }
    var opKey: Key {
        self < 0 ? .minus : .plus
    }
    var isDecimal: Bool {
        isFinite && floor(self) != self
    }
    var isWholeNumber: Bool {
        let roundedValue = rounded
        return floor(roundedValue) == roundedValue
    }
    var isEven: Bool {
        if !isWholeNumber {fatalError()}
        return Int(self).isEven
    }
    var isOdd: Bool {
        if !isWholeNumber {fatalError()}
        return Int(self).isOdd
    }
    var count: Int {
        keys!.count
    }
    var str: String? {
        keys?.str
    }
    var strForGraphPoint: String? {
        keys?.strForGraphPoint
    }
    func str(precision: Int) -> String {
        operationResultRounded(precision: precision, isError: false).keys!.str
    }
    func operationResultRounded(precision: Int, isError: Bool) -> Double {
        if isError {
            return pow(777,777)
        } else if String(self).contains("e") && precision >= 13 {
            var tempOpResult = String(self)
            var storeDeleted = ""
            while tempOpResult.contains("e") {
                storeDeleted += String(tempOpResult.last!)
                tempOpResult = String(tempOpResult.dropLast())
            }
            var exponent = 0
            if tempOpResult.contains(".") {
                exponent = max(0,precision - tempOpResult.split(separator: ".")[0].count)
            }
            let multiplyer = pow(10, Double(exponent))
            let multTimesResult = multiplyer*Double(tempOpResult)!
            return Double(String(multTimesResult.rounded()/multiplyer) + storeDeleted.reversed())!
        } else {
            let resultStr = String(self)
            var exponent = 0
            if resultStr.contains(".") {
                exponent = max(0,precision - resultStr.split(separator: ".")[0].count)
            }
            let multiplyer = pow(10, Double(exponent))
            return (multiplyer*self).rounded()/multiplyer
        }
    }
    var rounded: Double {
        operationResultRounded(precision: 13, isError: false)
    }
    func isAlmostEqualWithConsiderations(to otherValue: Double) -> Bool {
        if isAlmostEqual(to: otherValue) {return true}
        if isNaN && otherValue.isNaN {return true}
        if String(self).contains("e-") && otherValue == 0 {return true}
        if String(self).contains("e-") && String(otherValue).contains("e-") {
            if String(self).split(separator: "-").last! == String(otherValue).split(separator: "-").last! {
                if String(self).first! == String(otherValue).first! {return true}
            }
        }
        return false
    }
    func logBase(_ base: Double) -> Double {
        log10(self)/log10(base)
    }
    func isMultiple(of otherDouble: Double) -> Bool {
        if Int(str!) == nil || Int(otherDouble.str!) == nil {return false}
        if !isWholeNumber || !otherDouble.isWholeNumber {fatalError()}
        return Int(self).isMultiple(of: Int(otherDouble))
    }
    func isMultipleOrDivider(of otherValue: Double) -> Bool {
        isMultiple(of: otherValue) || otherValue.isMultiple(of: self)
    }
    var scientificFormattedForResult: String {
        return Formatter.scientificForResult.string(for: self) ?? ""
    }
    var resultFormatted: String {
        let numberFormatter = NumberFormatter()
        let range: Double = 1000000000
        let resultCountThres = 9
        if self >= range || self <= -range || String(self).contains("e-") {
            return self.scientificFormattedForResult
        } else if (String(self).hasPrefix("0.") || String(self).hasPrefix("-0.")) && String(self).count > resultCountThres {
            var tempResult = String(self)
            var zeroAfterDecimalCount = 0
            tempResult = String(self).hasPrefix("-") ? String(tempResult.dropFirst().dropFirst().dropFirst()) : String(tempResult.dropFirst().dropFirst())
            while tempResult.hasPrefix("0") {
                tempResult = String(tempResult.dropFirst())
                zeroAfterDecimalCount += 1
            }
            numberFormatter.maximumSignificantDigits = resultCountThres - 1 - zeroAfterDecimalCount
            return numberFormatter.string(from: NSNumber(value: self))!
        } else {
            return String(self)
        }
    }
    var strWithParenthesisIfNeg: String {
        if self < 0 {
            return "(\(str!))"
        } else {
            return str!
        }
    }
    var factors: [Int] {
        Int(self).factors
    }
    var int: Int {
        if !isWholeNumber {fatalError()}
        return Int(self)
    }
    var isNormalOrZero: Bool {
        isNormal || self == 0
    }
    var isCodeForNegEvenRoot: Bool {
        self == Double.codeForNegEvenRootCheck
    }
    var isCodeForImgOrInf: Bool {
        isInfinite || isCodeForNegEvenRoot
    }
    static var codeForNegEvenRootCheck: Double {
        99989018.99969016
    }
    func rounded(to digits: Int) -> Double {
        if self == floor(self) {
            return self
        }
        let multiplier = pow(10.0, Double(digits))
        return (self * multiplier).rounded() / multiplier
    }
    var hasEPlusOver99: Bool {
        let numberString = String(self)
        if let range = numberString.range(of: "e+") {
            let exponentPart = numberString[range.upperBound...]
            return exponentPart.count > 2 && exponentPart.allSatisfy { $0.isNumber }
        }
        return false
    }
    func isEqual(to other: Double, tolerance: Double) -> Bool {
        return abs(self - other) <= tolerance
    }
    func flip(_ flag: Bool) -> Double {
        flag ? -self : self
    }
}
extension Formatter {
    static let scientificForResult: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.positiveFormat = "0.#####E0"
        formatter.positiveInfinitySymbol = "Error"
        formatter.negativeInfinitySymbol = "Error"
        formatter.notANumberSymbol = "Error"
        formatter.exponentSymbol = "e"
        return formatter
    }()
}

extension Array where Element == Double {
    var gcd: Double {
        if count == 1 {
            return first!
        } else if count == 2 {
            return gcdDual(a: first!, b: last!)
        } else {
            return gcdDual(a: first!, b: [Double](dropFirst()).gcd)
        }
    }
    private func gcdDual(a: Double, b: Double) -> Double {
        let roundedA = a.rounded
        let roundedB = b.rounded
        if roundedB == 0 { return roundedA }
        let truncatingRemainder = roundedA.truncatingRemainder(dividingBy: roundedB)
        let roundedGCDdual = gcdDual(a: roundedB.rounded, b: truncatingRemainder.rounded)
        return roundedGCDdual.rounded
    }
    var addGetPMultGetQ: (p: Int, q: Int)? {
        if count != 2 || !last!.isWholeNumber {fatalError()}
        let lastIsPlus = last! >= 0
        let firstIsMinus = first! < 0
        guard let unsignedPair = abs(Int(last!)).factorsPairs.first(where: {
            if lastIsPlus {
                return Double($0.p + $0.q) == abs(first!)
            } else if firstIsMinus {
                return Double($0.p - $0.q) == first!
            } else {
                return Double($0.q - $0.p) == first!
            }
        }) else {return nil}
        let signedP = lastIsPlus ? (firstIsMinus ? -unsignedPair.p : unsignedPair.p) : (firstIsMinus ? unsignedPair.p : -unsignedPair.p)
        let signedQ = firstIsMinus ? -unsignedPair.q : unsignedPair.q
        return (signedP,signedQ)
    }
    var allValuesAreEqual: Bool {
        !contains(where: {$0 != first!})
    }
    var onlyWholeNumbers: [Int] {
        filter({$0.isWholeNumber}).map({Int($0)})
    }
    mutating func removeAdjacentPoints(to asymptotes: [Double], epsilon: Double) {
        for asymptote in asymptotes {
            guard let index = self.firstIndex(where: { abs($0 - asymptote) < epsilon/10 }) else {
                continue
            }
            if index > 0 {
                self.remove(at: index - 1)
            } else if index < self.count - 1 {
                self.remove(at: index + 1)
            }
        }
    }
}

extension Int {
    func colorName(_ isAutoLight: Bool) -> String {
        if self == 6 {
            return isAutoLight ? "ClassicLIcon" : "ClassicDIcon"
        } else if self == 7 {
            return isAutoLight ? "ProgLIcon" : "ProgDIcon"
        } else if self == 8 {
            return isAutoLight ? "BlueLIcon" : "BlueDIcon"
        } else if self == 0 {
            return "ClassicLIcon"
        } else if self == 1 {
            return "ClassicDIcon"
        } else if self == 2 {
            return "ProgLIcon"
        } else if self == 3 {
            return "ProgDIcon"
        } else if self == 4 {
            return "BlueLIcon"
        } else if self == 5 {
            return "BlueDIcon"
        }
        return ""
    }
    var isClassicTheme: Bool {
        [0,1,6].contains(self)
    }
    func adjustedColorIdx(_ isAutoLight: Bool) -> Int {
        self >= 6 ? ((self-6)*2 + (isAutoLight ? 0 : 1)) : self
    }
    func isLightMode(_ isAutoLight: Bool) -> Bool {
        [0,2,4].contains(self) || self >= 6 && isAutoLight
    }
    func isDarkMode(_ isAutoLight: Bool) -> Bool {
        !isLightMode(isAutoLight)
    }
    func isClassicLight(_ isAutoLight: Bool) -> Bool {
        self == 0 || self == 6 && isAutoLight
    }
    func isClassicDark(_ isAutoLight: Bool) -> Bool {
        self == 1 || self == 6 && !isAutoLight
    }
    func isProgLight(_ isAutoLight: Bool) -> Bool {
        self == 2 || self == 7 && isAutoLight
    }
    func isProgDark(_ isAutoLight: Bool) -> Bool {
        self == 3 || self == 7 && !isAutoLight
    }
    func isBlueDark(_ isAutoLight: Bool) -> Bool {
        self == 5 || self == 8 && !isAutoLight
    }
    func relatedAutoOrStatic(_ isAutoLight: Bool) -> Int {
        if isEven && isAutoLight {
            return self == 0 ? 6 : self == 2 ? 7 : 8
        } else if isOdd && !isAutoLight {
            return self == 1 ? 6 : self == 3 ? 7 : 8
        }
        return self
    }
    
    func nextSameAppearanceColor(_ isAutoLight: Bool) -> Int {
        // First get the actual color index (converting from auto if needed)
        let currentIdx = self.adjustedColorIdx(isAutoLight)
        let isLightMode = currentIdx.isEven
        
        // Calculate next index while maintaining light/dark mode
        let nextIdx = currentIdx + 2
        let baseNextIdx = nextIdx > 5 ? (isLightMode ? 0 : 1) : nextIdx
        
        // If we started with an auto color (6,7,8), return the corresponding auto color
        if self >= 6 {
            return baseNextIdx.relatedAutoOrStatic(isAutoLight)
        }
        
        return baseNextIdx
    }
    
    var keys: [Key] {
        var tempValue = String(self)
        var tempExpr = [Key]()
        while !tempValue.isEmpty {
            if tempValue.first != "+" {
                tempExpr.append(tempValue.first!.key!)
            }
            tempValue = String(tempValue.dropFirst())
        }
        return tempExpr
    }
    var newSKs: [StepKey] {
        keys.newSKs
    }
    var newNode: StepNode {
        StepNode(opKey: opKey, valueKeys: abs(self).keys)
    }
    var str: String {
        keys.str
    }
    var strWithOp: String {
        self < 0 ? str : ("+" + str)
    }
    var isEven: Bool {
        self%2 == 0
    }
    var isOdd: Bool {
        self%2 == 1
    }
    var primeFactors: [Int] {
        var n = self
        var factors: [Int] = []
        var divisor = 2
        while divisor * divisor <= n {
            while n % divisor == 0 {
                factors.append(divisor)
                n /= divisor
            }
            divisor += divisor == 2 ? 1 : 2
        }
        if n > 1 {
            factors.append(n)
        }
        return factors
    }
    var factorsPairs: [(p: Int, q: Int)] {
        if self < 1 {fatalError()}
        var tmpFactorsPairs = [(Int,Int)]()
        tmpFactorsPairs.append((1,self))
        if self <= 3 {return tmpFactorsPairs}
        for i in 2...self/2 {
            if i == self/2 && self != 4 {break}
            if Double(self).isMultiple(of: Double(i)) {} else {continue}
            tmpFactorsPairs.append((i,self/i))
        }
        return tmpFactorsPairs
    }
    var opKey: Key {
        self < 0 ? .minus : .plus
    }
    var strWithParenthesisIfNeg: String {
        if self < 0 {
            return "(\(str))"
        } else {
            return str
        }
    }
    var factors: [Int] {
        Array(Set(factorsPairs.map({[$0.p,$0.q,-$0.p,-$0.q]}).flatMap({$0})))
    }
    var withFlippedSign: Int {
        if self < 0 {
            return abs(self)
        } else {
            return -self
        }
    }
    var double: Double {
        Double(self)
    }
    static var random100b: Int {
        Int.random(in: 0...100000000000)
    }
    func flip(_ flag: Bool) -> Int {
        flag ? -self : self
    }
}

extension Array where Element == Int {
    func simplifyToTwoFactors(withIndex: Int) -> (Int, Int)? {
        var rootable = [Int]()
        var nonRootable = [Int]()
        for factor in Set(self) {
            let recurrentCount = filter({$0 == factor}).count
            
            for _ in 0..<recurrentCount-recurrentCount%withIndex {
                rootable.append(factor)
            }
            for _ in 0..<recurrentCount%withIndex {
                nonRootable.append(factor)
            }
        }
        if rootable.isEmpty || nonRootable.isEmpty {return nil}
        return (rootable.reduce(1, {$0*$1}), nonRootable.reduce(1, {$0*$1}))
    }
    var lcm: Int {
        let values = self
        if values.count == 1 {
            return values.first!
        } else if values.count == 2 {
            return dualLCM(values.first!, values.last!)
        } else {
            return dualLCM(values.first!, [Int](values.dropFirst()).lcm)
        }
    }
    private func dualLCM(_ x: Int, _ y: Int) -> Int {
        return x / Int([Double(x), Double(y)].gcd) * y
    }
    var doubles: [Double] {
        map({Double($0)})
    }
    func allRatios(with dividers: [Int]) -> [(num: Int, den: Int)] {
        var tmpAllRatios = [(num: Int, den: Int)]()
        for mult in self.doubles {
            for divider in dividers.doubles {
                let ratio = (mult/divider).rounded
                tmpAllRatios.append(ratio.isWholeNumber ? (Int(ratio),1) : (Int(mult),Int(divider)))
            }
        }
        var filteredRatios = [(num: Int, den: Int)]()
        for ratio in tmpAllRatios {
            if !filteredRatios.contains(where: {$0.num.double/$0.den.double == ratio.num.double/ratio.den.double}) {
                filteredRatios.append(ratio)
            }
        }
        for i in 0..<filteredRatios.count {
            if filteredRatios[i].num < 0 && filteredRatios[i].den < 0 {
                filteredRatios[i] = (abs(filteredRatios[i].num),abs(filteredRatios[i].den))
            } else if filteredRatios[i].den < 0 {
                filteredRatios[i] = (-filteredRatios[i].num,abs(filteredRatios[i].den))
            }
        }
        for i in 0..<filteredRatios.count {
            let gcd = [Double(filteredRatios[i].num), Double(filteredRatios[i].den)].gcd
            if abs(gcd) != 1 && filteredRatios[i].den != 1 {
                filteredRatios[i].num = Int((filteredRatios[i].num.double/gcd).rounded)
                filteredRatios[i].den = Int((filteredRatios[i].den.double/gcd).rounded)
            }
        }
        return filteredRatios
    }
}

extension Int32 {
    static var random: Int32 {
        Int32.random(in: Int32.min...Int32.max)
    }
    static var randomEven: Int32 {
        var randomNumber = Int32.random(in: Int32.min...Int32.max)
        randomNumber &= ~1 // Clear the least significant bit to ensure evenness
        return randomNumber
    }
    static var randomOdd: Int32 {
        var randomNumber = Int32.random(in: Int32.min...Int32.max)
        randomNumber |= 1 // Set the least significant bit to ensure oddness
        return randomNumber
    }
    static var topLevelStarterID: Int32 {
        23587
    }
    var isEven: Bool {
        self % 2 == 0
    }
    var isOdd: Bool {
        self % 2 != 0
    }
    var str: String {
        String(self)
    }
    func hashToInt8(avoiding collisionsWith: [Int8]) -> Int8 {
        var hash = Int8(truncatingIfNeeded: self % 256)
        while collisionsWith.contains(hash) {
            hash = (hash == 127) ? -128 : hash + 1
        }
        return hash
    }
    func mapToHashedInt8(using mapping: [(Int32, Int8)]) -> Int8 {
        if let correspondingHash = mapping.first(where: { $0.0 == self })?.1 {
            return correspondingHash
        } else {
            var randomHash: Int8
            repeat {
                randomHash = Int8.random(in: -128...127)
            } while mapping.contains { $0.1 == randomHash }
            return randomHash
        }
    }
}

extension Array where Element == Int32 {
    var hashedToInt8Tuples: [(int32: Int32, int8: Int8)] {
        var hashedValues = [Int8]()
        var result = [(Int32, Int8)]()
        for value in self {
            let hash = value.hashToInt8(avoiding: hashedValues)
            hashedValues.append(hash)
            result.append((value, hash))
        }
        return result
    }
    var hashedToInt8: [Int8] {
        var hashedValues = [Int8]()
        for value in self {
            let hash = value.hashToInt8(avoiding: hashedValues)
            hashedValues.append(hash)
        }
        return hashedValues
    }
    func mapToHashedInt8(using mapping: [(Int32, Int8)]) -> [Int8] {
        map{$0.mapToHashedInt8(using: mapping)}
    }
}

extension Array where Element == Int8 {
    var int32: [Int32] {
        map({Int32($0)})
    }
    var str: String {
        "[\(map { "\($0)" }.joined(separator: ","))]"
    }
    var uniques: [Int8] {
        Array(Set(self))
    }
    func reorder(basedOn order: [Int8]) -> [Int8] {
        order.filter { self.contains($0) }
    }
}

extension Array where Element == [Int8] {
    var str: String {
        "[\(map { "\($0.str)" }.joined(separator: ","))]"
    }
}

extension UUID {
    // generateColor removed (returned SwiftUI Color — rendering helper)
    var getExplainHowTapCount: Int {
        let uuidStr = uuidString
        let last4Hex = uuidStr[uuidStr.index(uuidStr.startIndex, offsetBy: 32)..<uuidStr.endIndex]
        return last4Hex == "FFFA" ? -1 : Int(last4Hex, radix: 16)!
    }
    var getShowStepsTapCount: Int {
        let uuidStr = uuidString
        let last4Hex = uuidStr[uuidStr.index(uuidStr.startIndex, offsetBy: 24)...uuidStr.index(uuidStr.startIndex, offsetBy: 28)]
        return last4Hex == "00000" ? -1 : Int(last4Hex, radix: 16)!
    }
}

extension Array where Element == [StepNode] {
    var onlyOneHasFraction: Bool {
        if count != 2 {fatalError()}
        return first!.hasFraction(flat: true) && !last!.hasFraction(flat: true) || !first!.hasFraction(flat: true) && last!.hasFraction(flat: true)
    }
    var str: String {
        map({$0.flatKeys.dropFirstIfPlus.str}).joined(separator: ", ")
    }
    func hideOneTerms() {
        for nodes in self {
            nodes.hideOneTerms()
        }
    }
}

extension Array {
    func drop(at index: Int) -> [Element] {
        guard index >= 0 && index < self.count else {
            return self
        }
        return Array(self[..<index] + self[(index + 1)...])
    }
    func subarray(after index: Int) -> [Element] {
        guard index >= 0 && index < self.count - 1 else {
            return []
        }
        return Array(self[(index + 1)...])
    }
    func subarray(before index: Int) -> [Element] {
        guard index > 0 && index <= self.count else {
            return []
        }
        return Array(self[..<index])
    }
}
