//
//  ExprFinalEnhanceBrain.swift
//  Hulul
//
//  Created by Ahmad on 12/6/19.
//  Copyright © 2019 Ahmad. All rights reserved.
//

import Foundation

struct CalcBrain {
    
    private func replaceParenFn(exprKeys: [Key], allowNegEvenRoot: Bool) -> [Key] {
        var tempEq = exprKeys.filter({!$0.isComma})
        var tempParenFnValue = ""
        var isAttachedParenFnAtStart = false
        var ungroupedOperand = [Key]()
        var groupedOperand: Double = 0
        var i = 0
        while i < tempEq.count {
            if tempEq[i] == .sqrt {
                let indexHolder = i
                if i == 1 {
                    isAttachedParenFnAtStart = true
                }
                var indexKey = [tempEq[i+1]]
                if tempEq[i+2].isNumber {
                    indexKey.append(tempEq[i+2])
                    i += 1
                }
                let indexValue: Double = indexKey == [.openBracket] ? 2 : indexKey.getDouble
                i += 3
                if !tempEq[i-1].isOpenBracket {fatalError()}
                var closeBracketC = 1
                while true {
                    if tempEq[i] == .closeBracket {
                        closeBracketC -= 1
                        if closeBracketC == 0 {break}
                    } else if tempEq[i] == .openBracket {
                        closeBracketC += 1
                    }
                    ungroupedOperand.append(tempEq[i])
                    i += 1
                }
                groupedOperand = getResultByExecute(exprKeys: ungroupedOperand, precision: 13, allowNegEvenRoot: allowNegEvenRoot)
                if !allowNegEvenRoot && (groupedOperand.isCodeForNegEvenRoot || groupedOperand < 0) && indexValue.isEven {return [.comma, .comma, .comma]}
                tempParenFnValue = String(groupedOperand < 0 ? -pow(-groupedOperand, 1/indexValue) : pow(groupedOperand, 1/indexValue))
                if tempParenFnValue == "nan" {
                    tempEq = [.zero,.divide,.zero]
                } else if tempParenFnValue.hasSuffix("inf") || tempParenFnValue.contains("e") {
                    tempEq = [.one,.divide,.zero]
                } else {
                    while indexHolder <= i {
                        tempEq.remove(at: i)
                        if i == 0 {
                            break
                        }
                        i -= 1
                    }
                    if i == 0 && !isAttachedParenFnAtStart {
                        tempParenFnValue = "(" + tempParenFnValue + ")"
                        while !tempParenFnValue.isEmpty {
                            if tempParenFnValue.first! != "+" {
                                guard let tempParenFnValueFirst = tempParenFnValue.first!.key else {return [.comma, .comma, .comma]}
                                tempEq.insert(tempParenFnValueFirst, at: i)
                                i += 1
                            }
                            tempParenFnValue = String(tempParenFnValue.dropFirst())
                        }
                    } else {
                        tempParenFnValue = "(" + tempParenFnValue + ")"
                        while !tempParenFnValue.isEmpty {
                            if tempParenFnValue.first! != "+" {
                                i += 1
                                guard let tempParenFnValueFirst = tempParenFnValue.first!.key else {return [.comma, .comma, .comma]}
                                tempEq.insert(tempParenFnValueFirst, at: i)
                            }
                            tempParenFnValue = String(tempParenFnValue.dropFirst())
                        }
                        isAttachedParenFnAtStart = false
                    }
                    tempEq = replaceParenFn(exprKeys: tempEq, allowNegEvenRoot: allowNegEvenRoot)
                }
            }
            i += 1
        }
        return tempEq
    }
    
    private func parenthesizeMinus(exprKeys: [Key]) -> [Key] {
        var tempEq = exprKeys
        
        while true {
            let compareExpr = tempEq
            var i = 0
            while i < tempEq.count {
                if tempEq.first!.isMinus || tempEq[i].isMinus && i > 0 && tempEq[i-1].isOpenBracket {
                    tempEq.remove(at: i)
                    tempEq.insert(.superTimes, at: i)
                    tempEq.insert(.closeBracket, at: i)
                    tempEq.insert(.one, at: i)
                    tempEq.insert(.minus, at: i)
                    tempEq.insert(.zero, at: i)
                    tempEq.insert(.openBracket, at: i)
                    break
                }
                i += 1
            }
            if tempEq == compareExpr {break}
        }
        return tempEq
    }
         
    private func addTimesWithAttachedOperand(exprKeys: [Key]) -> [Key] {
        var tempEq = exprKeys
        var i = 0
        while i < tempEq.count {
            if i != 0 {
                if (tempEq[i].isOpenBracket || tempEq[i].isSymb || tempEq[i] == .sqrt) && (tempEq[i-1].isOperand || tempEq[i-1].isCloseBracket) {
                    tempEq.insert(.times , at: i)
                }
            }

            if tempEq.count-1 != i {
                if (tempEq[i].isCloseBracket || tempEq[i].isSymb) && (tempEq[i+1].isOperand || tempEq[i+1].isOpenBracket || tempEq[i+1] == .sqrt) {
                    tempEq.insert(.times , at: i+1)
                }
            }

            i += 1
        }

        return tempEq
    }
    
    private func addZeroIfAloneInBracket(exprKeys: [Key]) -> [Key] {
        var tempEq = exprKeys
        var i = tempEq.count-1
        var openBracketCount = 0
        var closeBracketCount = 0
        while tempEq[i].isCloseBracket {
            closeBracketCount += 1
            i -= 1
        }
        i = 0
        while tempEq[i].isOpenBracket {
            openBracketCount += 1
            i += 1
        }
        if openBracketCount > 0 && openBracketCount == closeBracketCount {
            while i < tempEq.count - 1 - closeBracketCount {
                if !tempEq[i].isOperand && !tempEq.isAttachedMinusNew(idx: i) {
                    return exprKeys
                } else {
                    i += 1
                }
            }
            tempEq.append(.plus)
            tempEq.append(.zero)
            return tempEq
        }
        return exprKeys
    }
    
    func exprKeysFinalEnhance(exprKeys: [Key], allowNegEvenRoot: Bool) -> [Key] {
        let parenFnReplaced = replaceParenFn(exprKeys: exprKeys, allowNegEvenRoot: allowNegEvenRoot)
        if parenFnReplaced == [.comma, .comma, .comma] {return parenFnReplaced}
        let timesWithAttachedOperandAdded = addTimesWithAttachedOperand(exprKeys: parenFnReplaced)
        let minusParenthesized = parenthesizeMinus(exprKeys: timesWithAttachedOperandAdded)
        let zeroAddedWithAloneInBrackets = addZeroIfAloneInBracket(exprKeys: minusParenthesized)
        return zeroAddedWithAloneInBrackets
    }
}
