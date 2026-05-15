//
//  ExprCalculateBrain.swift
//  Hulul
//
//  Created by Ahmad on 12/6/19.
//  Copyright © 2019 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    
    final class exprKeysNode {
        var key: [Key]
        var right: exprKeysNode?
        var left: exprKeysNode?
        init(key: [Key]) {
            self.key = key
        }
    }
    
    func groupOperands(keys: [Key]) -> [[Key]] {
        var groupedExpr = [[Key]]()
        var temp = [Key]()
        for i in 0..<keys.count {
            if keys[i].isNumberOrDot {
                temp.append(keys[i])
            } else {
                if !temp.isEmpty {
                    groupedExpr.append(temp)
                    temp.removeAll()
                }
                groupedExpr.append([keys[i]])
            }
        }
        
        if !temp.isEmpty {
            groupedExpr.append(temp)
        }
        
        return groupedExpr
    }
    
    func infixToPrefix(infix: [[Key]]) -> exprKeysNode? {
        var operators = [Key]()
        var operands = [[exprKeysNode]]()
        var exprKeysTree = exprKeysNode(key: infix[0])
        
        for i in 0..<infix.count {
            if infix[i][0] == .openBracket {
                operators.append(infix[i][0])
            } else if infix[i][0] == .closeBracket {
                while !operators.isEmpty && operators.last != .openBracket {
                    guard let op = operators.last else {return nil}
                    operators.removeLast()
                    guard let op1 = operands.last else {return nil}
                    operands.removeLast()
                    guard let op2 = operands.last else {return nil}
                    operands.removeLast()
                    exprKeysTree = exprKeysNode(key: [op])
                    exprKeysTree.right = op1[0]
                    exprKeysTree.left = op2[0]
                    let tmp = [exprKeysTree] + op2 + op1
                    operands.append(tmp)
                }
                if operators.isEmpty {return nil}
                operators.removeLast()
            } else if !infix[i][0].isOp && !infix[i][0].isBracket {
                operands.append([exprKeysNode(key: infix[i])])
            } else {
                while !operators.isEmpty && infix[i][0].getPriority <= operators.last!.getPriority {
                    guard let op = operators.last else {return nil}
                    operators.removeLast()
                    guard let op1 = operands.last else {return nil}
                    operands.removeLast()
                    guard let op2 = operands.last else {return nil}
                    operands.removeLast()
                    exprKeysTree = exprKeysNode(key: [op])
                    exprKeysTree.right = op1[0]
                    exprKeysTree.left = op2[0]
                    let tmp = [exprKeysTree] + op2 + op1
                    operands.append(tmp)
                }
                operators.append(infix[i][0])
            }
        }
        while !operators.isEmpty {
            guard let op = operators.last else {return nil}
            operators.removeLast()
            guard let op1 = operands.last else {return nil}
            operands.removeLast()
            guard let op2 = operands.last else {return nil}
            operands.removeLast()
            exprKeysTree = exprKeysNode(key: [op])
            exprKeysTree.right = op1[0]
            exprKeysTree.left = op2[0]
            let tmp = [exprKeysTree] + op2 + op1
            operands.append(tmp)
        }
        return exprKeysTree
    }
    
    func correctInstancesForAddition(lhs: Double, rhs: Double) -> (lhs: Double, rhs: Double, mult: Double) {
        let lhsStr = String(lhs)
        let rhsStr = String(rhs)
        var lhsDecimalCount = 0
        if lhsStr.contains("e-") {
            lhsDecimalCount = lhsStr.contains(".") ? (lhsStr.split(separator: ".")[1]).split(separator: "e")[0].count : 0
            lhsDecimalCount += Int(String(lhsStr.split(separator: "e")[1]).dropFirst())!
        } else if lhsStr.contains(".") && !lhsStr.hasSuffix(".0") {
            lhsDecimalCount = lhsStr.split(separator: ".")[1].count
        }
        var rhsDecimalCount = 0
        if rhsStr.contains("e-") {
            rhsDecimalCount = rhsStr.contains(".") ? (rhsStr.split(separator: ".")[1]).split(separator: "e")[0].count : 0
            rhsDecimalCount += Int(String(rhsStr.split(separator: "e")[1]).dropFirst())!
        } else if rhsStr.contains(".") && !rhsStr.hasSuffix(".0") {
            rhsDecimalCount = rhsStr.split(separator: ".")[1].count
        }
        let decimalCount = max(lhsDecimalCount, rhsDecimalCount)
        let multiplyer = pow(10, Double(decimalCount))
        let lhsWhole = round(lhs * multiplyer)
        let rhsWhole = round(rhs * multiplyer)
        
        return (lhsWhole,rhsWhole,multiplyer)
    }
    func correctInstancesForMult(lhs: Double, rhs: Double, operation: (Double,Double) -> Double) -> (lhs: Double, rhs: Double, mult: Double) {
        let lhsStr = String(lhs)
        let rhsStr = String(rhs)
        var lhsMultiplyer: Double = 1
        var lhsDecimalCount = 0
        if lhsStr.contains("e-") {
            lhsDecimalCount = lhsStr.contains(".") ? (lhsStr.split(separator: ".")[1]).split(separator: "e")[0].count : 0
            lhsDecimalCount += Int(String(lhsStr.split(separator: "e")[1]).dropFirst())!
        } else if lhsStr.contains(".") && !lhsStr.hasSuffix(".0") {
            lhsDecimalCount = lhsStr.split(separator: ".")[1].count
        }
        lhsMultiplyer = pow(10, Double(lhsDecimalCount))
        
        var rhsMultiplyer: Double = 1
        var rhsDecimalCount = 0
        if rhsStr.contains("e-") {
            rhsDecimalCount = rhsStr.contains(".") ? (rhsStr.split(separator: ".")[1]).split(separator: "e")[0].count : 0
            rhsDecimalCount += Int(String(rhsStr.split(separator: "e")[1]).dropFirst())!
        } else if rhsStr.contains(".") && !rhsStr.hasSuffix(".0") {
            rhsDecimalCount = rhsStr.split(separator: ".")[1].count
        }
        rhsMultiplyer = pow(10, Double(rhsDecimalCount))
        
        let lhsWhole = round(lhs * lhsMultiplyer)
        let rhsWhole = round(rhs * rhsMultiplyer)
        
        return (lhsWhole,rhsWhole,operation(lhsMultiplyer,rhsMultiplyer))
    }
    
    func correctedResult(lhs: Double, rhs: Double, operation: (Double,Double) -> Double, isError: Bool) -> Double {
        let correctedSubExpr = operation(1,1) != 1 ? correctInstancesForAddition(lhs: lhs, rhs: rhs) : correctInstancesForMult(lhs: lhs, rhs: rhs, operation: operation)
        let result = operation(correctedSubExpr.lhs,correctedSubExpr.rhs)/correctedSubExpr.mult
        return isError ? pow(777, 777) : result
    }
    
    func calculateExpression(node: exprKeysNode, isError: inout Bool) -> Double? {
        if isError {
            return pow(777, 777)
        } else if node.key[0].isOp {
            guard let lhs = calculateExpression(node: node.left!, isError: &isError) else {return pow(777, 777)}
            guard let rhs = calculateExpression(node: node.right!, isError: &isError) else {return pow(777, 777)}
            switch node.key[0] {
            case .divide, .fraction:
                return correctedResult(lhs: lhs, rhs: rhs, operation: /, isError: isError)
            case .times, .superTimes:
                return correctedResult(lhs: lhs, rhs: rhs, operation: *, isError: isError)
            case .plus:
                return correctedResult(lhs: lhs, rhs: rhs, operation: +, isError: isError)
            case .minus:
                return correctedResult(lhs: lhs, rhs: rhs, operation: -, isError: isError)
            case .pow:
                if isError {
                    return pow(777, 777)
                } else if lhs == 0 && rhs == 0 {
                    return .nan
                } else if lhs < 0 && !rhs.isWholeNumber {
                    return isNumeratorEven(from: NSDecimalNumber(value: rhs)) ? pow(abs(lhs),rhs) : -pow(abs(lhs),rhs)
                } else {
                    return pow(lhs,rhs)
                }
            default:
                return 0
            }
        } else {
            switch node.key[0] {
            case .pi:
                return Double.pi
            case .euler:
                return M_E
            case .openBracket, .closeBracket:
                isError = true
                return pow(777, 777)
            default:
                return Double(node.key.map({$0.title}).joined())
            }
        }
    }
    
    private func isNumeratorEven(from decimal: NSDecimalNumber, withPrecision epsilon: Double = 1.0E-6) -> Bool {
        var numerator: Double = 1.0
        var denominator: Double = 0.0
        var lowerNumerator: Double = 0.0
        var lowerDenominator: Double = 1.0
        var value = decimal.doubleValue
        var repCount = 0
        
        repeat {
            repCount += 1
            if repCount > 16 {
                return false
            }
            let integerPart = floor(value)
            let tmpNumerator = numerator
            numerator = integerPart * numerator + lowerNumerator
            lowerNumerator = tmpNumerator
            
            let tmpDenominator = denominator
            denominator = integerPart * denominator + lowerDenominator
            lowerDenominator = tmpDenominator
            
            if abs(value - integerPart) < epsilon {
                break
            }
            
            value = 1.0 / (value - integerPart)
        } while true
        
        return Int(numerator) % 2 == 0
    }
    
    func getResultByExecute(exprKeys: [Key], precision: Int, allowNegEvenRoot: Bool = true) -> Double {
        var isError = false
        let exprKeysFinalEnhance = exprKeysFinalEnhance(exprKeys: exprKeys.replaceHiddenBrkts.dropPlusMinuses.replaceI, allowNegEvenRoot: allowNegEvenRoot)
        if exprKeysFinalEnhance == [.comma, .comma, .comma] {return Double.codeForNegEvenRootCheck}
        let infixToPrefix = infixToPrefix(infix: groupOperands(keys: exprKeysFinalEnhance))
        if infixToPrefix == nil {
            isError = true
        }
        let result = calculateExpression(node: infixToPrefix ?? exprKeysNode(key: []), isError: &isError)!
        let roundedResult = result.operationResultRounded(precision: precision, isError: false)
        return roundedResult == -0 ? 0 : roundedResult
    }
    
    func getResultByExecuteForEqualityCheck(exprKeys: [Key], precision: Int) -> Double {
        var isError = false
        let exprKeysFinalEnhance = exprKeysFinalEnhance(exprKeys: exprKeys.replaceHiddenBrkts.dropPlusMinuses.replaceI, allowNegEvenRoot: false)
        if exprKeysFinalEnhance == [.comma, .comma, .comma] {return Double.codeForNegEvenRootCheck}
        let infixToPrefix = infixToPrefix(infix: groupOperands(keys: exprKeysFinalEnhance))
        if infixToPrefix == nil {
            isError = true
        }
        let result = calculateExpression(node: infixToPrefix ?? exprKeysNode(key: []), isError: &isError)!
        let roundedResult = result.operationResultRounded(precision: precision, isError: false)
        return roundedResult == -0 ? 0 : roundedResult
    }
}
