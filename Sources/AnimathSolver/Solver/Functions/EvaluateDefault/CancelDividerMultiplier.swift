//
//  CancelDividerMultiplier.swift
//  Hulul
//
//  Created by Ahmad on 25/06/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func cancelDividerWithMultiplier(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if !node.isFirstInDividedMultChain {return}
        var multChain = node.multChain(forward: true)
        let divNode = node.multChainDivider
        if divNode.baseOrTermNode.isPoweredByPosOrNotPowered {} else {return}
        if multChain.termMix.contains(where: {!$0.isPoweredByPosOrNotPowered}) {return}
        multChain = multChain.reversed()
        
        // Actions
        if divNode.isOneTerm {
            if let multNode = multChain.directTerms.first(where: {$0.isEqualTo(node: divNode.firstTerm!)}) {
                
                // mark and explain
                steps.lastMarked = multNode.flatSKs + divNode.flatSKs
                steps.lastExplanation = "Any non-zero expression divided by itself equals 1"
    
                // Divide
                if multNode.isLast {
                    
                    if multNode.isSqrt && multNode.coeffNode.isOneRadical && multNode.coeffNode.isTimes {
                        steps.lastMarked.append(multNode.coeffNode.op)
                    }
                    
                    if multNode.coeffNode.isOneTerm && multNode.coeffNode.hasSingleTerm {
                        
                        // Mark
                        steps.lastMarked.append(multNode.coeffNode.valueSK.first!)
                        
                        // Remove
                        multNode.remove()
                        divNode.remove()
                        
                        // Append step
                        appendStep(&steps, fnCtrl: fnCtrl)
                        
                    } else {
                        
                        // Insert one node
                        let timesOneNode = StepNode.newOneNode.withOp(.times)
                        multNode.coeffNode.insertAfter(timesOneNode)
                        
                        // Remove
                        multNode.remove()
                        divNode.remove()
                        
                        // mark and append
                        steps.lastMarked.append(contentsOf: timesOneNode.flatSKs)
                        appendStep(&steps, fnCtrl: fnCtrl)
                        
                        // remove times one
                        removeHighOpOne(node: timesOneNode, fnCtrl: fnCtrl, &steps)
                    }
                } else {
                    
                    // Remove
                    multNode.remove()
                    divNode.remove()
                    
                    // mark and append
                    appendStep(&steps, fnCtrl: fnCtrl)
                }
                
            } else if let multNode = multChain.directTerms.first(where: {$0.hasEqualBase(with: divNode.firstTerm!)}) {
                divideBySubtractingExponents(multNode: multNode, divNode: divNode.firstTerm!, fnCtrl: fnCtrl, &steps)
            }
        } else if divNode.isNumber(mayBePowered: true) {
            
            // Equal Value
            node.pinRootExpr()
            if let multNode = multChain.first(where: {$0.dropTerms.withOp(.divide).isEqualTo(node: divNode.dropTerms)}) {
                
                // mark and explain
                steps.lastMarked = multNode.flatSKsNoTerms(multNode.next.isDivide ? .dropOp : .onlyTimes) + divNode.flatSKsNoTerms(.any)
                steps.lastExplanation = "Any non-zero \(multNode.isPowered ? "expression" : "number") divided by itself equals 1"
    
                // Divide
                multNode.valueSK = [.one]
                multNode.showOneTerm = true
                multNode.removePower()
                divNode.remove()
                
                // mark and append
                steps.lastMarked.append(contentsOf: multNode.valueSK)
                appendStep(&steps, fnCtrl: fnCtrl)
            }
            // Equal Base
            else if let multNode = multChain.first(where: {$0.hasEqualBase(with: divNode)}) {
                divideBySubtractingExponents(multNode: multNode, divNode: divNode, fnCtrl: fnCtrl, &steps)
            } else {
                evaluateDivision(node: node, fnCtrl: fnCtrl, &steps)
            }
            if node.pinnedRootDidChange {
                if let timeOneNode = multChain.first(where: {$0.isOne(opCase: .times) || $0.showOneTerm}) {
                    removeHighOpOne(node: timeOneNode, fnCtrl: fnCtrl + [.force], &steps)
                }
                return
            }
            
            // Dividable Numbers
            if let multNode = (multChain.filter({!$0.isDecimal}) + multChain.filter({$0.isDecimal})).dropPowBracketsFraction.first(where: {$0.isDividableBy(node: divNode, mayEqual: false)}), !divNode.isPowered {
                
                // mark and explain
                steps.lastMarked = multNode.opValueSK(multNode.next.isDivide ? .dropOp : .onlyTimes) + divNode.opValueSK
                steps.lastExplanation = "Divide the numbers"
                
                // Divide
                multNode.valueSK = [multNode, multNode.idx!+1 == divNode.idx ? divNode : divNode.withChangedIDs(withParent: true)].clone(changeID: false, withParent: false).children.getResultNodeForHighOp(returnSymbs: true).valueSK
                divNode.remove()
                
                // mark and append
                steps.lastMarked.append(contentsOf: multNode.valueSK)
                appendStep(&steps, fnCtrl: fnCtrl)
            }
        }
        
        // Equal brackets
        else if divNode.isBrackets(.complete) {
            if let multNode = multChain.onlyBrackets.first(where: {$0.isEqualToDropOp(node: divNode)}) {
                
                // mark and explain
                steps.lastMarked = multNode.flatSKs(multNode.next.isDivide ? .dropOp : .onlyTimes) + divNode.flatSKs(.any)
                steps.lastExplanation = "Any non-zero expression divided by itself equals 1"
    
                // Divide
                multNode.children.removeAll()
                multNode.valueSK = [.one]
                multNode.removePower()
                divNode.remove()
                
                // mark and append
                steps.lastMarked.append(contentsOf: multNode.valueSK)
                appendStep(&steps, fnCtrl: fnCtrl)
            } else if let multNode = multChain.onlyBrackets.first(where: {$0.hasEqualBase(with: divNode)}) {
                divideBySubtractingExponents(multNode: multNode, divNode: divNode, fnCtrl: fnCtrl, &steps)
            }
        }
        
        // Remove times one
        if let timeOneNode = multChain.first(where: {$0.isOne(opCase: .times)}) {
            removeHighOpOne(node: timeOneNode, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
}

extension CalcBrain {
    private func divideBySubtractingExponents(multNode: StepNode, divNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let allPowers = multNode.powerOrOne+divNode.powerOrOne
        let divPowerIsLarger = divNode.powerOrOne.dropTerms.resultValue() > multNode.powerOrOne.dropTerms.resultValue()
        var willHaveNotPosSingle = multNode.isPoweredByMultiple || divNode.isPoweredByMultiple || allPowers.hasFraction(flat: true) || !allPowers.isSimplestForm && divPowerIsLarger
        if willHaveNotPosSingle && !multNode.root.children.isEqualTo(nodes: [multNode.baseNode,divNode.baseNode]) && divPowerIsLarger {
            convertDivisionToFraction(node: multNode.baseNode.multChainFirst, fnCtrl: fnCtrl + [.force], &steps)
            return
        }
        
        // Mark and explain
        steps.lastMarked = multNode.flatSKsNoTerms(multNode.baseNode.next.isDivide ? .dropOp : .onlyTimes) + divNode.baseNode.flatSKs
        steps.lastExplanation = "Divide the \(multNode.isBrackets ? "parenthesis" : "terms") with the same base by subtracting their exponents"
        
        // Init substeps
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastMarked.removeAll()
        steps.lastStepSubsteps.lastNote.removeAll()

        // Set power to one
        for node in [multNode,divNode] {
            if !node.isPowered {
                // Mark and explain
                steps.lastStepSubsteps.lastExplanation = setExponentToOneExplanation
                // set power to one
                node.power = [.newOneNode]
                steps.lastStepSubsteps.lastMarked = node.flatSKs(.dropOp)
                // append step
                appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
            }
        }
        
        // mark and explain
        steps.lastStepSubsteps.lastMarked.append(contentsOf: multNode.power.flatSKs + divNode.power.flatSKs)
        steps.lastStepSubsteps.lastExplanation = "Divide the \(multNode.isBrackets ? "parenthesis" : "terms") with the same base by subtracting their exponents" // determineMarkedNodes() is depending on this string
        
        // move exponent
        multNode.power.append(divNode.power.first!.withOp(.minus))
        divNode.baseNode.remove()
        
        // append step
        steps.lastStepSubsteps.lastMarked.append(multNode.power.last!.op)
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        // Substract
        if multNode.power.isSimplestForm {
            willHaveNotPosSingle = true
        }
        evaluateAddition(node: multNode.power.first!, fnCtrl: fnCtrl + [.force, .forcePowerAddition], &steps.lastStepSubsteps)
        
        // Remove Power 1
        if multNode.isPoweredByOne {
            removeHighOpOne(node: multNode, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // Append main steps
        if multNode.isPowered && multNode.power.first!.valueSK.contains(where: {divNode.power.valuesSK.contains($0)}) {
            multNode.power.first!.changeIDs()
        }
        steps.lastMarked.append(contentsOf: multNode.power.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl + (willHaveNotPosSingle ? [.forceFlatSubsteps] : []))
    }
}

extension CalcBrain {
    func cancelDivWithMultAllowed(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeClone = node.clone(changeID: false, withParent: true)
        let multChain = nodeClone.multChain(forward: false)
        if multChain.isEmpty {return false}
        let multChainFirst = multChain.first!
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        nodeClone.pinRootExpr()
        cancelDividerWithMultiplier(node: multChainFirst, fnCtrl: fnCtrl + [.force, .skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeClone.pinnedRootDidChange
    }
}
