//
//  EvaluateAddition.swift
//  Hulul
//
//  Created by Ahmad on 25/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func evaluateAddition(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        guard let level = node.level else {return}
        if !fnCtrl.contains(.forcePowerAddition) && fnCtrl.contains(.skipAddition) {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        guard node.isNumber(mayBePowered: false) else {return}
        let filteredLevel = level.dropPoweredBySymb.dropFractions
        if filteredLevel.hasHighOp || filteredLevel.hasBrackets(.any) {return}
        guard node.termsAreInSimplestForm else {return}
        if node.hasEqualTerms(in: filteredLevel) && node.isFirstOfSameTerms(in: filteredLevel) {} else {return}
        
        //
        node.pinRootExpr()
        cancelOppositeTerms(node: node, fnCtrl: fnCtrl, &steps)
        if node.pinnedRootDidChange {return}
        
        // Set Same Terms
        let termNodes = node.nodesSameTerm(in: filteredLevel)
        if termNodes.contains(where: {!$0.isPlusOrMinus || $0.isMultipliedOrDivided || $0.op.key == .plusMinus}) {return}
        
        //
        if termNodes.hasLongDecimal {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        
        //
        for node in termNodes {
            reorderTermsFromIn(node: node, fnCtrl: fnCtrl, &steps)
        }
        let originalSKs = termNodes.flatSKsNoTerms(.any)

        //
        let firstTerm = termNodes.first!.directTerms
        let otherTerms = termNodes.dropFirst().map({$0.directTerms})
        
        // Mark and explain
        steps.lastMarked = termNodes.opValuesSK(.onlyPlusOrMinus)
        steps.lastExplanation = termNodes.hasTerm ? "Collect like terms" : additionExplanation(keys: termNodes.flatSKsNoTerms(.dropPlus).keys)
        steps.lastMarked.append(contentsOf: termNodes.directTerms.flatSKs)
        
        // Substeps
        steps.lastStepSubsteps = [steps.last!]
        
        var tmpTermNodes = termNodes
        
        // loop and evaluate
        while tmpTermNodes.count > 1 {
            
            //
            var isPowerOf10 = false
            var adderNode = StepNode()
            if let tmpAdderNode = tmpTermNodes.first(where: { adderNode in
                tmpTermNodes.dropNode(node: adderNode).contains(where: {
                    let resultValue = $0.opValueSK.getDouble+(adderNode.opValueSK.getDouble)
                    return resultValue != 1 && log10(resultValue).isWholeNumber
                })
            }) {
                isPowerOf10 = true
                adderNode = tmpAdderNode
            } else if let tmpAdderNode = tmpTermNodes.first(where: { adderNode in
                tmpTermNodes.dropNode(node: adderNode).contains(where: {
                    let resultValue = $0.opValueSK.getDouble+(adderNode.opValueSK.getDouble)
                    return resultValue.truncatingRemainder(dividingBy: 10) == 0 || $0.isDecimal && resultValue.isWholeNumber
                })
            }) {
                adderNode = tmpAdderNode
            } else {
                adderNode = tmpTermNodes.first!
            }
            let addendNode = tmpTermNodes.dropNode(node: adderNode).first(where: {
                let resultValue = $0.opValueSK.getDouble+(adderNode.opValueSK.getDouble)
                if isPowerOf10 {
                    return resultValue != 1 && log10(resultValue).isWholeNumber
                } else {
                    return resultValue.truncatingRemainder(dividingBy: 10) == 0 || $0.isDecimal && resultValue.isWholeNumber
                }
            }) ?? termNodes.dropNode(node: adderNode).filter({$0.exist}).first!
            
            // set to evalute nodes
            let originalAdder = adderNode.clone(changeID: false, withParent: false)
            let subNodes = [adderNode, addendNode]
            
            //
            if adderNode.isFirstIn(in: termNodes) && addendNode.isFirstIn(in: termNodes.dropFirst.filter({$0.exist})) {
                steps.lastStepSubsteps.lastExplanation = additionExplanation(keys: subNodes.flatSKsNoTerms(.dropPlus).keys)
            } else {
                steps.lastStepSubsteps.lastExplanation = adderNode.isDecimal ? "\(addendNode.isPlus ? "Add" : "Subtract") the decimals that result in a whole number" : "To make the calculation easier, first \(addendNode.isPlus ? "add" : "subtract") the numbers that result in multiples of 10"
            }
            
            //
            let innerLastTermIDs = addendNode.directTerms.flatSKs.ids
            let innerFirstTermIDs = adderNode.directTerms.flatSKs.ids
            
            // should cancel
            let shouldCancel = getOppositeEqualChain(for: adderNode).isEqualTo(nodes: [addendNode]) && !adderNode.isCoeff
            
            // Mark and explain
            steps.lastStepSubsteps.lastMarked = subNodes.opValuesSK(.onlyPlusOrMinus) + subNodes.directTerms.flatSKs
            if shouldCancel {
                steps.lastStepSubsteps.lastExplanation = "The sum of two opposites equals 0"
                steps.lastStepSubsteps.lastStrikeKeys = [adderNode.strikeKeyWithSymb, addendNode.strikeKeyWithSymb]
            }
            
            // Evaluate and replace nodes with result
            let resultNode = subNodes.getResultNodeForAddition()
            adderNode.level!.replaceNodesWithResult(nodes: subNodes, resultNode: resultNode)
            
            // Mark and append
            steps.lastStepSubsteps.lastMarked.append(contentsOf: resultNode.opValueSK(.onlyPlusOrMinus))
            if resultNode.isPlus && originalAdder.isPlus {
                steps.lastStepSubsteps.lastMarked.removeAll(where: {$0 == resultNode.op})
            }
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipRemoveUslessBrackets])
            
            //
            if !firstTerm.isEmpty {
                steps.lastStepSubsteps.appendMergeIDs(originalKeysIDs: innerFirstTermIDs, mergesKeysIDs: [innerLastTermIDs])
            }
            
            //
            tmpTermNodes.removeAll(where: {!$0.exist})
        }
        
        //
        var hadOnlyTwoSubsteps = false
        if steps.lastStepSubsteps.count == 2 {
            steps.lastStepSubsteps[0].explanation = steps.lastExplanation
            hadOnlyTwoSubsteps = true
        }
        
        // Append main node
        if node.valueSK.count > 1 || node.valueSK.first!.key == originalSKs.first!.key {
            node.valueSK.replaceSimilarKeys(similarKeys: originalSKs)
        }
        steps.lastMarked.append(contentsOf: node.opValueSK(.onlyPlusOrMinus))
        if node.isPlus && originalSKs.first!.key.isPlus {
            steps.lastMarked.removeAll(where: {$0 == node.op})
        } else if node.isMinus && originalSKs.first!.key.isMinus {
            node.op = originalSKs.first!
        }
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if !hadOnlyTwoSubsteps && !firstTerm.isEmpty {
            steps.appendMergeIDs(originalKeysIDs: firstTerm.flatSKs.ids, mergesKeysIDs: otherTerms.map({$0.flatSKs.ids}))
        }
        
        //
        removeAddedZero(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func additionExplanation(keys: [Key]) -> String {
        if keys.isEmpty || keys.filter({$0.isOp}).contains(where: {!$0.isPlusOrMinus}) {return ""}
        enum ExplType {
            case add, sum, subtract, difference, calculate
        }
        let plusCount = keys.filter({$0 == .plus}).count
        let minusCount = keys.filter({$0 == .minus}).count
        
        var explType: ExplType {
            if plusCount == 1 && minusCount == 0 {
                return .add
            } else if plusCount > 1 && minusCount == 0 {
                return .sum
            } else if minusCount == 1 && plusCount == 0 {
                return .subtract
            } else if minusCount > 1 && plusCount == 0 {
                return .difference
            } else if plusCount > 0 && minusCount > 0 {
                return .calculate
            } else {
                return .calculate
            }
        }
        
        switch explType {
        case .add:
            return "Add the numbers"
        case .sum:
            return "Calculate the sum"
        case .subtract:
            return "Subtract the numbers"
        case .difference:
            return "Calculate the difference"
        case .calculate:
            return "Calculate the expression"
        }
    }
}
