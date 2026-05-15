//
//  KeyHelpers.swift
//  Animath
//
//  Created by Ahmad on 04/11/2024.
//

import Foundation

extension Key {
    static var allSymbTypes = [x,y,z,pi,euler]
    mutating func flipSign() {
        if self == .plus {
            self = .minus
        } else if self == .minus {
            self = .plus
        } else if self != .plusMinus {fatalError()}
    }
    var newSK: StepKey {
        .stepKey(self)
    }
    func withID(_ id: Int32) -> StepKey {
        StepKey(self, id: id)
    }
    var getPriority: Int {
        switch self {
        case .plus, .minus:
            return 1
        case .divide, .times:
            return 2
        case .superTimes, .fraction:
            return 3
        case .pow:
            return 4
        case .factorial:
            return 5
        default:
            return 0
        }
    }
}

extension Array where Element == Key {
    func isAttachedMinusNew(idx: Int) -> Bool {
        if (self[idx].isMinus && idx == 0) || (self[idx].isMinus && idx > 0 && !self[idx-1].isOperand && !self[idx-1].isCloseBracket) {
            return true
        } else {
            return false
        }
    }
    var newSKs: [StepKey] {
        self.map({StepKey($0)})
    }
    var getDouble: Double {
        let tempExpr = self
        var valueStr = ""
        for x in 0..<tempExpr.count {
            valueStr += tempExpr[x].title
        }
        valueStr = String(valueStr.map({$0 == "−" ? "-" : $0}))
        return Double(valueStr)!
    }
    func getResultValue() -> Double {
        let calcBrain = CalcBrain()
        return calcBrain.getResultByExecute(exprKeys: self, precision: 13)
    }
    var charsWidth: Double {
        map({$0.charWidth}).reduce(0, +)
    }
    var str: String {
        var keysStr = ""
        for key in self {
            keysStr += key.title
        }
        return keysStr
    }
    var strForGraphPoint: String {
        var keysStr = ""
        for key in self {
            keysStr += key.title.regulerMinuses
        }
        return keysStr
    }
    var sympyStr: String? {
        var sympyStr = ""
        for key in self {
            guard let sympyTitle = key.titleForSympy else {return nil}
            sympyStr += sympyTitle
        }
        return sympyStr
    }
    var dropFirstIfPlus: [Key] {
        first!.isPlus ? [Key](self.dropFirst()) : self
    }
    var dropFirstOp: [Key] {
        first!.isOp ? [Key](self.dropFirst()) : self
    }
    var replaceHiddenBrkts: [Key] {
        var tmpExpr = self
        for i in 0..<tmpExpr.count {
            if tmpExpr[i].isHiddenOpenBrkt {
                tmpExpr[i] = .openBracket
            } else if tmpExpr[i].isHiddenCloseBrkt {
                tmpExpr[i] = .closeBracket
            }
        }
        return tmpExpr
    }
    var replaceI: [Key] {
        var tmpExpr = self
        var j = 0
        while j < tmpExpr.count {
            if tmpExpr[j] == .imaginary {
                tmpExpr.remove(at: j)
                tmpExpr.insert(contentsOf: [.openBracket, .one, .closeBracket], at: j)
                j += 2
            }
            j += 1
        }
        return tmpExpr
    }
    func overlaps(with otherKeys: [Key]) -> Bool {
        contains(where: {origKey in otherKeys.contains(origKey)})
    }
    var hasVarNotXYZ: Bool {
        contains(where: {$0.isVarNotXYZ})
    }
    var dropCommas: [Key] {
        filter({$0 != .comma})
    }
    var dropPlusMinuses: [Key] {
        filter({$0 != .plusMinus})
    }
    var strForExpl: String {
        let originalKeys = self
        let keysWithRegBrkts = originalKeys.replaceHiddenBrkts
        var valueStr = ""
        var i = 0
        while i < keysWithRegBrkts.count {
            if keysWithRegBrkts[i] == .pow && !originalKeys[i+2..<originalKeys[i+2..<originalKeys.count].firstIndex(of: .closeSquareBrkt)!].contains(where: {$0.powTitle == nil}) {
                i += 1
                if originalKeys[i] == .openSquareBrkt {
                    i += 1
                }
                while i < keysWithRegBrkts.count && originalKeys[i] != .closeSquareBrkt {
                    valueStr += keysWithRegBrkts[i].powTitle!
                    i += 1
                }
                i += 1
            } else if keysWithRegBrkts[i] == .sqrt {
                if keysWithRegBrkts[i+1] != .two {
                    if i != 0 && keysWithRegBrkts[i-1].isOperand {valueStr += "×"}
                    valueStr += keysWithRegBrkts[i+1].powTitle!
                }
                valueStr += keysWithRegBrkts[i].title
                i += 2
            } else {
                valueStr += keysWithRegBrkts[i].title
                i += 1
            }
        }
        return valueStr
    }
    var sympyToStr: String? {
        let originalKeys = self
        let keysWithRegBrkts = originalKeys.replaceHiddenBrkts
        var valueStr = ""
        var shouldSkipBrkAt = -1
        var i = 0
        while i < keysWithRegBrkts.count {
            if shouldSkipBrkAt == i {
                shouldSkipBrkAt = -1
                i += 1
            } else if keysWithRegBrkts[i] == .pow && !originalKeys[i+2..<originalKeys[i+2..<originalKeys.count].firstIndex(of: .closeSquareBrkt)!].contains(where: {$0.powTitle == nil}) {
                i += 1
                if originalKeys[i] == .openSquareBrkt {
                    i += 1
                }
                while i < keysWithRegBrkts.count && originalKeys[i] != .closeSquareBrkt {
                    valueStr += keysWithRegBrkts[i].powTitle!
                    i += 1
                }
                i += 1
            } else if keysWithRegBrkts[i] == .sqrt {
                if keysWithRegBrkts[i+1] != .two {return nil}
                valueStr += keysWithRegBrkts[i].title.regulerMinuses
                i += 2
                if keysWithRegBrkts[i] == .openBracket {
                    guard let closeBracketIdx = keysWithRegBrkts[i..<keysWithRegBrkts.count].firstIndex(of: .closeBracket) else {return nil}
                    if closeBracketIdx+1 >= keysWithRegBrkts.count || closeBracketIdx+1 < keysWithRegBrkts.count && keysWithRegBrkts[closeBracketIdx+1] != .fraction {
                        shouldSkipBrkAt = closeBracketIdx
                        i += 1
                    }
                }
            } else {
                valueStr += keysWithRegBrkts[i].title.regulerMinuses
                i += 1
            }
        }
        return valueStr
    }
    func getResult(subtitutes: [[Key]], allowNegEvenRoot: Bool) -> Double? {
        var exprKeys = self
        exprKeys.removeAll(where: {$0 == .plusMinus})
        var i = 0
        while i < exprKeys.count {
            if exprKeys[i].isVarOrNotVarX {
                guard var subtitute = subtitutes.first else {return nil}
                if subtitutes.count > 1 {
                    if exprKeys[i] == .x || exprKeys[i] == .notVarX {
                        subtitute = subtitutes.first!
                    } else if exprKeys[i] == .y {
                        subtitute = subtitutes[1]
                    } else if exprKeys[i] == .z {
                        guard subtitutes.count > 2 else {return nil}
                        subtitute = subtitutes[2]
                    }
                }
                exprKeys.remove(at: i)
                exprKeys.insert(.closeBracket, at: i)
                for subKey in subtitute.reversed() {
                    exprKeys.insert(subKey, at: i)
                }
                exprKeys.insert(.openBracket, at: i)
            }
            i += 1
        }
        let calcBrain = CalcBrain()
        return allowNegEvenRoot ? calcBrain.getResultByExecute(exprKeys: exprKeys, precision: 13) : calcBrain.getResultByExecuteForEqualityCheck(exprKeys: exprKeys, precision: 13)
    }
}

extension Array where Element == [Key] {
    var dropRedundants: [[Key]] {
        var uniqueValuesKeys = [[Key]]()
        for tmpKeys in self {
            if !uniqueValuesKeys.contains(tmpKeys) {
                uniqueValuesKeys.append(tmpKeys)
            }
        }
        return uniqueValuesKeys
    }
}

extension StepKey {
    
    fileprivate init(_ key: Key) {
        self.key = key
        id = Int32.random
    }
    fileprivate init(_ key: Key, id: Int32) {
        self.key = key
        self.id = id
    }
    
    var isHiddenBracket: Bool {key.isSquareBrkt || key.isCurlyBrkt || isFirstHiddenBracket}
    var isFirstHiddenBracket: Bool {key == .openBracket && (id == StepKey.lhsFirstID || id == StepKey.rhsFirstID)}
    var isHiddenOpenBrkt: Bool {key.isHiddenOpenBrkt || isFirstHiddenBracket}
    
    static var openBracket: StepKey {StepKey(.openBracket)}
    static var closeBracket: StepKey {StepKey(.closeBracket)}
    static var openSquareBrkt: StepKey {StepKey(.openSquareBrkt)}
    static var closeSquareBrkt: StepKey {StepKey(.closeSquareBrkt)}
    static var openCurlyBrkt: StepKey {StepKey(.openCurlyBrkt)}
    static var closeCurlyBrkt: StepKey {StepKey(.closeCurlyBrkt)}
    static var fraction: StepKey {StepKey(.fraction)}
    static var mixedFrac: StepKey {StepKey(.mixedFrac)}
    static var x: StepKey {StepKey(.x)}
    static var y: StepKey {StepKey(.y)}
    static var z: StepKey {StepKey(.z)}
    static var seven: StepKey {StepKey(.seven)}
    static var eight: StepKey {StepKey(.eight)}
    static var nine: StepKey {StepKey(.nine)}
    static var divide: StepKey {StepKey(.divide)}
    static var four: StepKey {StepKey(.four)}
    static var five: StepKey {StepKey(.five)}
    static var six: StepKey {StepKey(.six)}
    static var times: StepKey {StepKey(.times)}
    static var sqrt: StepKey {StepKey(.sqrt)}
    static var cbrt: StepKey {StepKey(.cbrt)}
    static var one: StepKey {StepKey(.one)}
    static var two: StepKey {StepKey(.two)}
    static var three: StepKey {StepKey(.three)}
    static var plus: StepKey {StepKey(.plus)}
    static var plusMinus: StepKey {StepKey(.plusMinus)}
    static var pi: StepKey {StepKey(.pi)}
    static var euler: StepKey {StepKey(.euler)}
    static var i: StepKey {StepKey(.imaginary)}
    static var zero: StepKey {StepKey(.zero)}
    static var dot: StepKey {StepKey(.dot)}
    static var typedEqual: StepKey {StepKey(.typedEqual)}
    static var notEqual: StepKey {StepKey(.notEqual)}
    static var approximately: StepKey {StepKey(.approximately)}
    static var minus: StepKey {StepKey(.minus)}
    static var comma: StepKey {StepKey(.comma)}
    static var questionMark: StepKey {StepKey(.questionMark)}
    static var pow: StepKey {StepKey(.pow)}
    static var temp: StepKey {StepKey(.temp)}
    static var C: StepKey {StepKey(.ac)}
    
    static var lhsFirstID = Int32.random
    static var rhsFirstID = Int32.random
    static var rootHiddenOpenBracketLHS = StepKey(.openBracket).withID(lhsFirstID)
    static var rootHiddenOpenBracketRHS = StepKey(.openBracket).withID(rhsFirstID)
    
    static var staticComma = StepKey(.comma)
    static var sin: StepKey {StepKey(.sin)}
    static var csc: StepKey {StepKey(.csc)}
    static var sinh: StepKey {StepKey(.sinh)}
    static var arcsin: StepKey {StepKey(.arcsin)}
    static var cos: StepKey {StepKey(.cos)}
    static var sec: StepKey {StepKey(.sec)}
    static var cosh: StepKey {StepKey(.cosh)}
    static var arccos: StepKey {StepKey(.arccos)}
    static var tan: StepKey {StepKey(.tan)}
    static var cot: StepKey {StepKey(.cot)}
    static var tanh: StepKey {StepKey(.tanh)}
    static var arctan: StepKey {StepKey(.arctan)}
    static var log: StepKey {StepKey(.log)}
    static var logBase: StepKey {StepKey(.logBase)}
    static var ln: StepKey {StepKey(.ln)}
    static var piHalf: StepKey {StepKey(.piHalf)}
    static var piThird: StepKey {StepKey(.piThird)}
    static var ePower: StepKey {StepKey(.eulerPow)}
    static var factorial: StepKey {StepKey(.factorial)}
}


extension String {
    var keys: [Key] {
        var tempKeys = [Key]()
        for char in self {
            if let mappedKey = char.key {
                tempKeys.append(mappedKey)
            } else {
                tempKeys.append(.custom(String(char)))
            }
        }
        return tempKeys
    }
    var stepKeys: [StepKey] {
        keys.newSKs
    }
    var getResultCase: ResultCase {
        switch self {
        case "undefined":
            return .undefined
        case "unableToSolve":
            return .unableToSolve
        case "falseForAnyX":
            return .falseForAnyX
        case "trueForAllX":
            return .trueForAllX
        case "falseEq":
            return .falseEq
        case "trueEq":
            return .trueEq
        case "none":
            return .none
        default:
            fatalError()
        }
    }
    
    func dropOuterBrackets(flag: Bool) -> String {
        if !flag || self.first! != "(" || self.last! != ")" {return self}
        var str = self
        str.removeFirst()
        str.removeLast()
        return str
    }
    func parenthesized(flag: Bool) -> String {
        if flag {} else {return self}
        return "(" + self + ")"
    }
    var withPaddedFractions: String {
        var newStr = ""
        for char in self {
            if char == "/" {
                newStr.append(contentsOf: " \(char) ")
            } else {
                newStr.append(char)
            }
        }
        return newStr
    }
    
    func differenceWith(_ str2: String) -> String {
        var diffStr = ""
        for i in 0..<count {
            if i > str2.count-1 {
                diffStr = "nil" + " | \(self[i])"
                break
            }
            if self[i] == str2[i] {
                continue
            } else {
                diffStr = "\(str2[i])" + " | \(self[i])"
                break
            }
        }
        return diffStr
    }
    var removeLastColon: String {
        if let i = lastIndex(of: ":") {
            let index: Int = distance(from: startIndex, to: i)
            return substring(toIndex: index)
        }
        fatalError()
    }
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, count) ..< count]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(count, r.lowerBound)),
                                            upper: min(count, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    var AIQuestionTitle: String {
        components(separatedBy: Global.titlePromptDiv).first ?? self
    }
    var AIQuestionContent: String {
        components(separatedBy: Global.titlePromptDiv).last ?? self
    }
    var startsWithArabic: Bool {
        guard let firstCharacter = self.first else { return false }
        let firstCharacterStr = String(firstCharacter)
        let rtlCharacters = ["\u{200F}", "\u{202B}", "\u{202E}", "\u{2067}", "\u{2069}"]
        return firstCharacterStr.range(of: "\\p{InArabic}", options: .regularExpression) != nil || rtlCharacters.contains(firstCharacterStr)
    }
    var containsArabic: Bool {
        let arabicRange = self.range(of: "\\p{InArabic}", options: .regularExpression)
        let rtlCharacters = ["\u{200F}", "\u{202B}", "\u{202E}", "\u{2067}", "\u{2069}"]
        return arabicRange != nil || rtlCharacters.contains { self.contains($0) }
    }
    var heightInStepArea: Int {
        count/27+filter({$0 == "\n"}).count
    }
    var ansArray: [String] {
        isEmpty ? [] : components(separatedBy: Global.qsDiv)
    }
    var fltrdSummarySteps: String {
        let components = components(separatedBy: "\n")
        let fltrdComponents = components.count <= 3 ? components : [components.first!, components[components.count/2], components.last!]
        return fltrdComponents.joined(separator: "\n")
    }
    var langCodePref: String? {
        components(separatedBy: "-").first
    }
    var getLanguage: Language {
        Global.getLanguage(langCodePref: self)
    }
    mutating func removeExcludedFromAddingQ() {
        removeAll(where: {char in Global.excludedFromAddingQ.contains(where: {String(char) == $0})})
    }
    mutating func addReplyInStrIfArabic() {
        if startsWithArabic {
            self = replacingOccurrences(of: "\u{200F}", with: "")
            let language = Global.getLanguage
            if language.isArabic {
                self = self + Global.titlePromptDiv + self + " (\(language.replyInStr))"
            }
        }
    }
    var arr: [Character] {
        Array(self)
    }
    var withoutDotZero: String {
        if self.hasSuffix(".0") {
            return String(self.dropLast(2))
        } else {
            return self
        }
    }
    // points: [GraphPoint] removed (graph rendering type, not solver)
    func contains(either strs: [String]) -> Bool {
        for str in strs {
            if self.contains(str) {return true}
        }
        return false
    }
    var regulerMinuses: String {
        replacingOccurrences(of: "−", with: "-")
    }
    var regulerXs: String {
        replacingOccurrences(of: Key.x.title, with: "x")
    }
    var longerMinuses: String {
        replacingOccurrences(of: "-", with: "−")
    }
    func containsIgnoringCase(_ substring: String) -> Bool {
        return self.range(of: substring, options: .caseInsensitive) != nil
    }
    func hasPrefixCaseInsensitive(_ substring: String) -> Bool {
        return lowercased().hasPrefix(substring.lowercased())
    }
    func explanationLinesCount(viewSize: CGSize) -> Int {
        Int(ceil(Double(count)/(27*viewSize.exprMaxLengthRatio)))
    }
    func dropUpToAndIncluding(_ character: Character) -> String {
        if let index = firstIndex(of: character) {
            let newIndex = self.index(after: index)
            return String(self[newIndex...])
        }
        return self
    }
    var isOp: Bool {
        count == 1 && first!.isOp
    }
    var isArrow: Bool {
        count == 1 && first!.isArrow
    }
    var isParenthesis: Bool {
        count == 1 && first!.isParenthesis
    }
    var isEquality: Bool {
        count == 1 && first!.isEquality
    }
    func isOpenBracket(isAbs: Bool = false) -> Bool {
        count == 1 && first!.isOpenBracket(isAbs: isAbs)
    }
    func isCloseBracket(isAbs: Bool = false) -> Bool {
        count == 1 && first!.isCloseBracket(isAbs: isAbs)
    }
    var isEscapeCharForLatex: Bool {
        count == 1 && first!.isEscapeCharForLatex
    }
    var hasNumber: Bool {
        rangeOfCharacter(from: .decimalDigits) != nil
    }
    var keyTitleOrStr: String {
        if count == 1 {
            return first!.keyTitle ?? ""
        } else {
            return self
        }
    }
    
    var toSuperscript: String? {
        let superscriptMap: [Character: String] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
            "a": "ᵃ", "b": "ᵇ", "c": "ᶜ", "d": "ᵈ", "e": "ᵉ",
            "f": "ᶠ", "g": "ᵍ", "h": "ʰ", "i": "ⁱ", "j": "ʲ",
            "k": "ᵏ", "l": "ˡ", "m": "ᵐ", "n": "ⁿ", "o": "ᵒ",
            "p": "ᵖ", "r": "ʳ", "s": "ˢ", "t": "ᵗ", "u": "ᵘ",
            "v": "ᵛ", "w": "ʷ", "x": "ˣ", "y": "ʸ", "z": "ᶻ",
            "A": "ᴬ", "B": "ᴮ", "D": "ᴰ", "E": "ᴱ", "G": "ᴳ",
            "H": "ᴴ", "I": "ᴵ", "J": "ᴶ", "K": "ᴷ", "L": "ᴸ",
            "M": "ᴹ", "N": "ᴺ", "O": "ᴼ", "P": "ᴾ", "R": "ᴿ",
            "T": "ᵀ", "U": "ᵁ", "V": "ⱽ", "W": "ᴾ",
            "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾",
            "/": "ᐟ"
        ]
        
        var superscriptString = ""
        
        for char in self {
            if let superscriptChar = superscriptMap[char] {
                superscriptString.append(superscriptChar)
            } else {
                return nil
            }
        }
        
        return superscriptString
    }
    
    var toSubscript: String? {
        let subscriptMap: [Character: String] = [
            "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
            "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
            "a": "ₐ", "e": "ₑ", "h": "ₕ", "i": "ᵢ", "j": "ⱼ",
            "k": "ₖ", "l": "ₗ", "m": "ₘ", "n": "ₙ", "o": "ₒ",
            "p": "ₚ", "r": "ᵣ", "s": "ₛ", "t": "ₜ", "u": "ᵤ",
            "v": "ᵥ", "x": "ₓ", "+": "₊", "-": "₋", "=": "₌",
            "(": "₍", ")": "₎"
        ]
        
        var subscriptString = ""
        
        for char in self {
            if let subscriptChar = subscriptMap[char] {
                subscriptString.append(subscriptChar)
            } else {
                return nil
            }
        }
        
        return subscriptString
    }
    static var allOperators: String {
        "+-−×⋅·÷/=<>≠≈≤≥±—≡∝≅≃∼≨≩"
    }
    static var allArrows: String {
        "→←⇄⇆⇒⇔⇐⇌⇋⇍↔↦⟶⟹⟺⟸⟷⟼⟿↪↩"
    }
    static var allEqualities: String {
        "=<>≠≈≤≥≡∝≅≃≨≩"
    }
    static var escapeCharsForLatex: String {
        "(){}[]$#_^&%\\"
    }
   static func allOpenBrackets(includeAbs: Bool) -> String {
        "({[" + (includeAbs ? "|" : "")
    }
    static func allCloseBrackets(includeAbs: Bool) -> String {
        ")}]" + (includeAbs ? "|" : "")
    }
    var dropThickChevrons: String {
        replacingOccurrences(of: Global.thickChevron.left, with: "").replacingOccurrences(of: Global.thickChevron.right, with: "")
    }
}

extension Array where Element == String {
    var AIQuestionTitles: [String] {
        map({$0.AIQuestionTitle})
    }
    var mainQsSum: Int {
        map({
            let components = $0.components(separatedBy: Global.titlePromptDiv)
            return Int(components[1]) ?? 0
        }).reduce(0, +)
    }
    var mainQsWithoutSummarySum: Int {
        filter({!$0.contains("Summary\(Global.titlePromptDiv)")}).map({
            let components = $0.components(separatedBy: Global.titlePromptDiv)
            return Int(components[1]) ?? 0
        }).reduce(0, +)
    }
    var secondQsSum: Int {
        map({
            let components = $0.components(separatedBy: Global.titlePromptDiv)
            return Int(components[2]) ?? 0
        }).reduce(0, +)
    }
    var allQsSum: Int {
        map({
            let components = $0.components(separatedBy: Global.titlePromptDiv)
            return [Int(components[1]) ?? 0, Int(components[2]) ?? 0]
        }).flatMap({$0}).reduce(0, +)
    }
    var twoDAIQsCounts: [[String]] {
        map({$0.components(separatedBy: Global.cloudDataDiv)[3].components(separatedBy: Global.qsDiv)})
    }
    var sortedDescendingQsCount: [String] {
        sorted { first, second in
            let firstCount = Int(first.components(separatedBy: Global.titlePromptDiv)[1]) ?? 0
            let secondCount = Int(second.components(separatedBy: Global.titlePromptDiv)[1]) ?? 0
            return firstCount > secondCount
        }
    }
    var lastNOrP: String? {
        last(where: {$0 == "n" || $0 == "p"})
    }
    var stepKeyMatrix: [[StepKey]] {
        map({$0.stepKeys})
    }
}

extension Array where Element == [String] {
    var summedAIQsCounts2D: [[String]] {
        let aiQsCountsFlat = flatMap({$0}).map({$0.components(separatedBy: Global.titlePromptDiv)})
        let existingQs = [String](Set(aiQsCountsFlat.map({$0.first!})))
        var tmpSummedAIQsCounts2D = [[String]]()
        for qTitle in existingQs {
            let mainQSum = String(aiQsCountsFlat.filter({$0.first! == qTitle}).map({Int($0[1])!}).reduce(0, +))
            let secondQSum = String(aiQsCountsFlat.filter({$0.first! == qTitle}).map({Int($0[2])!}).reduce(0, +))
            let aiQCounts = [qTitle, mainQSum, secondQSum]
            tmpSummedAIQsCounts2D.append(aiQCounts)
        }
        return tmpSummedAIQsCounts2D
    }
    var sortedDescending: [[String]] {
        return sorted {
            guard let firstValue = Int($0[1]), let secondValue = Int($1[1]) else { return false }
            return firstValue > secondValue
        }
    }
}

extension Character {
    var getKeyForVar: Key {
        switch self {
        case "𝒙": return .x
        case "y": return .y
        case "z": return .z
        case "n", ",": return .comma
        default: fatalError()
        }
    }
    var isOp: Bool {
        String.allOperators.contains(self)
    }
    var isArrow: Bool {
        String.allArrows.contains(self)
    }
    var isParenthesis: Bool {
        "()".contains(self)
    }
    var isEquality: Bool {
        String.allEqualities.contains(self)
    }
    func isOpenBracket(isAbs: Bool) -> Bool {
        String.allOpenBrackets(includeAbs: isAbs).contains(self)
    }
    func isCloseBracket(isAbs: Bool) -> Bool {
        String.allCloseBrackets(includeAbs: isAbs).contains(self)
    }
    var isEscapeCharForLatex: Bool {
        String.escapeCharsForLatex.contains(self)
    }
    var str: String {
        String(self)
    }
    var keyTitle: String? {
        str.keys.first?.title
    }
    var isArabic: Bool {
        String(self).containsArabic
    }
    var closeEquivalent: String? {
        switch self {
        case "(": return ")"
        case "[": return "]"
        case "{": return "}"
        case "|": return "|"
        default: return nil
        }
    }
    var openEquivalent: String? {
        switch self {
        case ")": return "("
        case "]": return "["
        case "}": return "{"
        case "|": return "|"
        default: return nil
        }
    }
}

extension Array where Element == Character {
    func subCompare(from: Int, equalTo otherStr: String) -> Bool {
        let range = otherStr.count
        return sub(idx: from, range: range) == otherStr.arr
    }
    func sub(idx: Int, range: Int) -> [Character] {
        if idx+range > count {return []}
        return self[idx...idx+range-1].arr
    }
}

extension ArraySlice where Element == Character {
    var arr: [Character] {
        return Array(self)
    }
}
