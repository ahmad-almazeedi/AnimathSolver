//
//  FractionAddition.swift
//  Hulul
//
//  Created by Ahmad on 04/10/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func fractionAddition(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        fractionToFractionAddition(node: node, fromFracToNumAdd: false, fnCtrl: fnCtrl, &steps)
        fractionToNumberAddition(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func fractionToFractionAddition(node: StepNode, fromFracToNumAdd: Bool, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if !fnCtrl.contains(.forcePowerAddition) && fnCtrl.contains(.skipAddition) {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isFraction(.simplest(for: .numerator)) && node.isFraction(part: .denominator, {$0.isSimplestFormNegletTimesBracket}) {} else {return}
        guard let nodeLevel = node.level else {return}
        let filteredLevel = nodeLevel.dropMultipliedBracketChain.dropNumbers(mayBePowered: false)
        if !filteredLevel.hasHighOp && !filteredLevel.hasBrackets(.any) {} else {return}
        if filteredLevel.hasFraction(.notSimplest(for: .numerator)) || filteredLevel.hasFraction(part: .denominator, {$0.hasRadicalFlat || !$0.isSimplestFormNegletTimesBracket}) {return}
        let tmpTermNodes = node.fractionNodesCommonTerm(in: filteredLevel)
        let hasMultiDen = nodeLevel.hasFraction(part: .denominator, {$0.isMulti})
        var fractionTermNodes = [StepNode]()
        if tmpTermNodes.count <= 1 {
            if nodeLevel.dropFractions.isSimplestForm {} else {return}
            let denominatorParents = nodeLevel.onlyFractions.map({$0.denominator.parent!})
            if fromFracToNumAdd || filteredLevel.count == nodeLevel.count || !node.isEquation && denominatorParents.hasVarFlat {} else {return}
            if hasMultiDen || fnCtrl.isForced {} else {
                if node.isEquation && !node.isInBrackets && nodeLevel.hasVar {return}
                if node.isInFraction || denominatorParents.nodesAreEqual || !node.isEquation && denominatorParents.hasVarFlat {} else {return}
            }
            fractionTermNodes = nodeLevel.onlyFractions
        } else {
            let multipleTermFraction = tmpTermNodes.first(where: {$0.numerator.count > 1}) ?? tmpTermNodes.first!
            fractionTermNodes = multipleTermFraction.fractionNodesCommonTerm(in: filteredLevel)
        }
        if fractionTermNodes.contains(where: {$0.op.key == .plusMinus}) {return}
        if fractionTermNodes.count > 1 {} else {return}
        if fnCtrl.contains(.forceFractionAddition) || node.id == fractionTermNodes.first!.id {} else {return}
        if fractionTermNodes.contains(where: {!$0.isPlusOrMinus || $0.isMultipliedOrDivided}) {return}
        if fractionTermNodes.contains(where: {$0.isReducibleFraction}) {return}
        if fractionTermNodes.contains(where: {$0.numerator.hasDecimal || $0.denominator.hasDecimal}) {return}
        if !fnCtrl.contains(.forceFractionAddition) && fractionTermNodes.numeratorsParents.hasVarFlat && node.isEquation {
            if node.otherSide.children.dropBrackets.contains(where: {$0.hasCommonTerm(with: fractionTermNodes.first!)}) {return}
            if !hasMultiDen && node.parentIsRoot && !fractionTermNodes.map({$0.denominator.parent!}).nodesAreEqual {
                if willMultBothSidesByFraction(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl + [.forceFractionAddition]) {} else {return}
            }
        }
        if fnCtrl.isCheckAllowed {node.changeContent(); return}
        
        //
        for fracionNode in fractionTermNodes {
            determineChainSign(node: fracionNode, fnCtrl: fnCtrl, &steps)
        }
        
        // Set
        let uniqueDenValueCount = fractionTermNodes.contains(where: {$0.denominator.count > 1}) ? 1 : Set(fractionTermNodes.denominatorsFirsts.valuesDouble).count
        let removedSomeFractions = uniqueDenValueCount != 1 && uniqueDenValueCount != fractionTermNodes.count
        if removedSomeFractions {
            if let firstEqualDenFraction = fractionTermNodes.first(where: {fractionTermNodes.dropNode(node: $0).denominatorsFirsts.valuesDouble.contains($0.denominator.first!.valueDouble)}) {
                fractionTermNodes.removeAll(where: {$0.denominator.first!.valueDouble != firstEqualDenFraction.denominator.first!.valueDouble})
            }
        }
        let firstNode = fractionTermNodes.first!
        let areAloneInParenthesis = fractionTermNodes.count == firstNode.level!.count && firstNode.isInBrackets
        
        //
        if fractionTermNodes.denominatorsParents.nodesAreEqual {
            combineAndAddTheFractions(node: firstNode, fractionTermNodes: fractionTermNodes, combinedFromOutside: true, removedSomeFractions: removedSomeFractions, fnCtrl: fnCtrl, &steps)
        } else {
            fractionToFractionAdditionInSubsteps(node: firstNode, fractionTermNodes: fractionTermNodes, areAloneInParenthesis: areAloneInParenthesis, fromFracToNumAdd: fromFracToNumAdd, fnCtrl: fnCtrl, &steps)
        }
    }
    private func fractionToFractionAdditionInSubsteps(node: StepNode, fractionTermNodes: [StepNode], areAloneInParenthesis: Bool, fromFracToNumAdd: Bool, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Set
        let mainFractionNode = node.denominator.isOne(opCase: .any) ? fractionTermNodes.last! : node
        let originalSKs = fractionTermNodes.map({$0.numerator}).flatMap({$0}).flatSKs
        let originalFractions = fractionTermNodes.clone(changeID: false, withParent: false).children
        let denominatorIsMulti = fractionTermNodes.contains(where: {$0.denominator.count > 1 || node.denominator.isBrackets})
        let minusOrEmpty = (node.isMinus || node.numerator.isMinus ? [node.flatKeys.first(where: {$0.isMinus})!] : [])

        // Initials
        if !fromFracToNumAdd {
            
            // Explain
            steps.lastMarked = denominatorIsMulti ? [] : fractionTermNodes.flatSKs.dropHiddens
            steps.lastExplanation = fractionAdditionExplanation(ops: minusOrEmpty + fractionTermNodes.getOps.keys.dropFirst(), fromFracToNumAdd: false, hasVar: false, hasConst: false, forTitleStep: false)
            
            // set substeps
            steps.lastStepSubsteps = [steps.last!]
        }
        
        // Factor if needed
        extractMinusAndDetermineSignIfNeeded(fractionTermNodes: fractionTermNodes, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        factorIfNeeded(fractionTermNodes: fractionTermNodes, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        if !fromFracToNumAdd {
            steps.lastStepSubsteps.lastStep.setTitle(title: fractionAdditionExplanation(ops: minusOrEmpty + fractionTermNodes.getOps.keys.dropFirst(), fromFracToNumAdd: false, hasVar: false, hasConst: false, forTitleStep: true), subtitle: "#"+fractionTermNodes.flatSKs(.dropPlus).str)
        }
        
        //
        steps.lastStepSubsteps.lastMarked = fractionTermNodes.denominatorChain.flatSKs
        var addSubtStr: String {
            if fractionTermNodes.count == 2 {
                return fractionTermNodes.last!.isPlus ? "add" : "subtract"
            } else {
                let ops = fractionTermNodes.map({$0.op}).keys.dropFirst()
                if ops.count == ops.filter({$0.isPlus}).count {
                    return "add"
                } else if ops.count == ops.filter({$0.isMinus}).count {
                    return "subtract"
                } else {
                    return "add or subtract"
                }
            }
        }
        steps.lastStepSubsteps.lastExplanation = "To \(addSubtStr) fractions, first make sure their denominators are equal"
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        if fractionTermNodes.contains(where: {tmpFraction in fractionTermNodes.dropNode(node: tmpFraction).contains(where: {!tmpFraction.denominator.isEqualTo(nodes: $0.denominator)})}) {
            multNumDenToReachLCM(fractionTermNodes: fractionTermNodes, fnCtrl: fnCtrl, &steps)
            if node.root.resultCase == .unableToSolve {
                return
            }
        }
        
        // Combine and add the fractions
        combineAndAddTheFractions(node: node, fractionTermNodes: fractionTermNodes, combinedFromOutside: false, removedSomeFractions: false, fnCtrl: fnCtrl + [.skipRemoveUslessBrackets], &steps.lastStepSubsteps)
        
        // reduce
        reduceForCase(.divisibleNumToDen, node: node, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        reduceForCase(.divisibleDenToNum, node: node, fnCtrl: fnCtrl + [.force], &steps.lastStepSubsteps)
        reduceForCase(.simplify, node: node, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps.lastStepSubsteps)
        
        //
        steps.lastStepSubsteps.lastStep.removeTitleStep()

        // Append to main step
        if !denominatorIsMulti {
            if node.isFraction {
                let newMainFraction = fromFracToNumAdd ? mainFractionNode : fractionTermNodes.first!
                node.valueSK = newMainFraction.valueSK
                node.denominator.first!.content = originalFractions.first(where: {$0.denominator.isEqualTo(nodes: node.denominator)})?.denominator.first!.content ?? newMainFraction.denominator.first!.content
                if !fromFracToNumAdd {
                    node.numerator.replaceSimilarKeys(with: originalSKs, withPow: false)
                }
            } else {
                node.valueSK.replaceSimilarKeys(similarKeys: originalSKs)
            }
            steps.lastMarked.append(contentsOf: node.flatSKs(.dropOp).dropHiddens)
            if steps.lastMarked.first!.key.isPlus && node.isPlus {
                steps.lastMarked.removeFirst()
            } else if !areAloneInParenthesis {
                steps.lastMarked.append(node.op)
            }
            
            //
            if node.isFraction && !node.numerator.isSimplestForm {
                steps.lastExplanation = "Write all numerators above the least common denominator \(node.denominator.first!.flatSKs(.dropOp).strForExpl)"
            }
        }
                
        //
        appendStep(&steps, fnCtrl: fnCtrl + (denominatorIsMulti ? [.forceFlatSubsteps] : []))
    }
    
    private func combineAndAddTheFractions(node: StepNode, fractionTermNodes: [StepNode], combinedFromOutside: Bool, removedSomeFractions: Bool, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {

        //
        moveNegativeSignToNumerator(node: node, fnCtrl: fnCtrl, &steps)
        for denominatorNode in fractionTermNodes.map({$0.denominator}).flatMap({$0}) {
            reorderTermsFromIn(node: denominatorNode, fnCtrl: fnCtrl, &steps)
        }
        reorderAllToMatchFirstOrPos(nestedNodes: fractionTermNodes.map({$0.denominator}), fnCtrl: fnCtrl, &steps)
        
        // Mark and append
        steps.lastMarked = fractionTermNodes.flatSKs(.dropPlus)
        steps.lastExplanation = combinedFromOutside ? "Since \(removedSomeFractions ? "the" : "all") denominators are equal, write \(removedSomeFractions ? "the" : "all") numerators above the common denominator" : "Now that all denominators are equal, write all numerators above the common denominator"
        
        // Merge fractions
        mergeFractions(node: node, fractionTermNodes: fractionTermNodes, fnCtrl: fnCtrl, &steps)
        
        // Change IDs for better animations
        let fltrdFractionTermNodes = fractionTermNodes.filter({$0.nodeProduct == nil || !($0.nodeProduct!.isCommaNode && $0.nodeProduct!.op.key == .comma)})
        fractionTermNodes.removeNodesProducts()
        let innerMainFraction = fltrdFractionTermNodes[(fltrdFractionTermNodes.count+(fltrdFractionTermNodes.count.isMultiple(of: 2) ? 0 : 1))/2-1]
        let originalFractionTermNodes = fractionTermNodes.dropNode(node: innerMainFraction).clone(changeID: false, withParent: false).children
        node.valueSK = innerMainFraction.valueSK
        node.children.last!.content = innerMainFraction.children.last!.content

        //
        fractionTermNodes.dropNode(node: innerMainFraction).changeStaticIDsForStepIncrement()
        
        // Append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Merge Denominators
        for i in 0..<innerMainFraction.denominator.count {
            
            let denNode = innerMainFraction.denominator[i]
            let otherDenNodes = originalFractionTermNodes.map({$0.denominator[i]})
            
            steps.appendMergeIDs(originalKeysIDs: denNode.opValueSK.ids, mergesKeysIDs: otherDenNodes.map({$0.opValueSK.ids}))
            if denNode.isBrackets {
                steps.appendMergeIDs(originalKeysIDs: denNode.children.flatSKs.ids, mergesKeysIDs: otherDenNodes.map({$0.children.flatSKs.ids}))
                if let brktPowerParent = denNode.powerParent {
                    steps.appendMergeIDs(originalKeysIDs: brktPowerParent.children.flatSKs.ids, mergesKeysIDs: otherDenNodes.map({$0.powerParent!.children.flatSKs.ids}))
                }
            }
            for j in 0..<denNode.directSymbs.count {
                let denSymb = denNode.directSymbs[j]
                for otherSymbs in originalFractionTermNodes.map({$0.denominator[i].directSymbs[j]}).compactMap({$0}).map({$0.flatSKs.ids}) {
                    steps.appendMergeIDs(originalKeysIDs: denSymb.flatSKs.ids, mergesKeysIDs: [otherSymbs])
                }
            }
            if let denNodeRadicalParent = denNode.radicalParent {
                steps.appendMergeIDs(originalKeysIDs: denNodeRadicalParent.flatSKs.ids, mergesKeysIDs: otherDenNodes.map({$0.radicalParent!.flatSKs.ids}))

            }
        }
        
        // evaluate numerators
        surfAndEvaluateAndApplyFnTillEnd(parent: node.children.first!, fnCtrl: fnCtrl + [.skipFlattenning, .skipDistribute, .justRemoveBrktInRmvUslsBrkt], &steps)
        
        // move minus out
        determineChainSign(node: node, fnCtrl: fnCtrl + [.force], &steps)
    }
}

extension CalcBrain {
    func extractMinusAndDetermineSignIfNeeded(fractionTermNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        guard fractionTermNodes.count == 2 && !fractionTermNodes.contains(where: {!$0.children.isMulti}) else {return}
        let fraction1 = fractionTermNodes.first!
        let fraction2 = fractionTermNodes.last!
        if fraction1.denominator.isEqualTo(nodes: fraction2.denominator.withFlippedSigns) {
            let selectedFraction = fractionTermNodes.first(where: {!$0.denominator.first!.isCoeff}) ?? fraction1
            var selectedDenominator = selectedFraction.denominator
            extractMinusFromExpr(nodes: &selectedDenominator, fnCtrl: fnCtrl + [.forceExtractMinus], &steps)
            determineChainSign(node: selectedFraction, fnCtrl: fnCtrl + [.force], &steps)
        }
    }
    func factorIfNeeded(fractionTermNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        for fractionNode in fractionTermNodes {
            var fakeSteps = [StepModel()]
            let fractionClone = fractionNode.cloneWithChangedStaticIDs
            let otherFractionsClones = fractionTermNodes.dropNode(node: fractionNode).cloneWithChangedStaticIDs
            for tmpFractionClone in ([fractionClone] + otherFractionsClones) {
                if tmpFractionClone.denominator.hasBrackets {
                    for brktNode in tmpFractionClone.denominator.onlyBrackets {
                        factorPolynomial(parent: brktNode, fnCtrl: [.force, .skipPrintStep], &fakeSteps)
                    }
                } else {
                    factorPolynomial(parent: tmpFractionClone.children.last!, fnCtrl: [.force, .skipPrintStep], &fakeSteps)
                    removeUselessBracketsNoSteps(nodeL: tmpFractionClone, nodeR: StepNode(), fnCtrl: [])
                }
            }
            if fractionClone.denominator.contains(where: {denNode in otherFractionsClones.contains(where: {otherFractionNode in [otherFractionNode].denominatorChain.contains(where: {$0.baseOrTermNode.hasEqualBase(with: denNode.baseOrTermNode)})})}) {
                if fractionNode.denominator.hasBrackets {
                    for brktNode in fractionNode.denominator.onlyBrackets {
                        factorPolynomial(parent: brktNode, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps)
                    }
                } else {
                    factorPolynomial(parent: fractionNode.children.last!, fnCtrl: fnCtrl + [.force, .skipFlattenning], &steps)
                    removeUselessBracketsNoSteps(nodeL: fractionNode, nodeR: StepNode(), fnCtrl: fnCtrl)
                }
                for node in fractionNode.denominator.onlyBrackets {
                    mergeAndEvaluateEqualBrackets(node: node, fnCtrl: fnCtrl + [.skipPow, .skipFlattenning], &steps)
                }
            } else if fractionClone.denominator.isMultChain && fractionClone.denominator.onlyNumbers.contains(where: {denNode in otherFractionsClones.filter({$0.denominator.isMultChain}).contains(where: {otherFractionNode in otherFractionNode.denominator.contains(where: {[$0,denNode].getGCD != nil})})}) {
                if fractionNode.denominator.hasBrackets {
                    for brktNode in fractionNode.denominator.onlyBrackets {
                        extractCommonFactor(brktNode: brktNode, fnCtrl: fnCtrl + [.force], &steps)                    }
                } else {
                    extractCommonFactor(nodes: fractionNode.denominator, withOp: false, fnCtrl: fnCtrl + [.force], &steps)
                    removeUselessBracketsNoSteps(nodeL: fractionNode, nodeR: StepNode(), fnCtrl: fnCtrl)
                }
            }
        }
    }
    func multNumDenToReachLCM(fractionTermNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Extract LCD
        let lcmNodes = fractionTermNodes.getLCMNodes
        
        // multiply nums and dens
        var expantionHasVar = false
        var fractionsToChangeDen = [StepNode]()
        for fractionNode in fractionTermNodes {
            
            // get multiplier
            let newFractionNode = StepNode.newFractionNode
            let lcmClones = lcmNodes.clone(changeID: true, withParent: false).children
            let tmpRoot = StepNode()
            newFractionNode.numerator = lcmClones
            newFractionNode.denominator = fractionNode.denominator.clone(changeID: true, withParent: false).children
            tmpRoot.children = [newFractionNode]
            newFractionNode.reduceFraction()
            var fakeSteps = [StepModel()]
            surfAndApplyFn(mainNode: tmpRoot, otherNode: nil, fnCtrl: [.skipPrintStep], surfFnCases: .removeHighOpOne, &fakeSteps)
            if tmpRoot.children.hasFraction(flat: true) {
                steps.setToUnableToSolve(nodeL: fractionNode.root, nodeR: fractionNode.otherSide)
                return
            }
            
            //
            if tmpRoot.children.count == 1 && tmpRoot.children.first!.valueIsOne && !tmpRoot.children.first!.isCoeff {continue}
            if tmpRoot.children.isMultiNotHighOpChain {
                tmpRoot.children.setBrackets()
            }
            tmpRoot.children.first!.op = .times
            
            //
            fractionsToChangeDen.append(fractionNode)
            
            //
            if tmpRoot.children.hasVarFlat {
                expantionHasVar = true
            }
            
            // Multiply
            insertMultFractionNumDen(fractionNode: fractionNode, lcmNodes: tmpRoot.children, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        }
        
        // Reorder
        if !fractionTermNodes.contains(where: {$0.denominator.count < 2 || !$0.denominator.hasBrackets}) {
            fractionTermNodes.map({$0.children.last!}).reorderChildrensToBeTheSame()
            for nodes in fractionTermNodes.map({$0.denominator}) {
                nodes.setAllOpsToTimesAndFirstToPlus()
            }
        }
        
        //
        steps.lastStepSubsteps.lastExplanation = "Since the denominators are not equal, expand the fraction\(fractionsToChangeDen.count == 1 ? "" : "s") to get the least common denominator (LCD)"
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        // Merge same base
        for fractionNode in fractionTermNodes {
            for node in fractionNode.denominator.onlyBrackets {
                mergeAndEvaluateEqualBrackets(node: node, fnCtrl: [.force, .skipPow, .skipFlattenning], &steps.lastStepSubsteps)
            }
        }
        
        //
        fractionTermNodes.first!.pinRootExpr()
        for fractionNode in fractionTermNodes {
            calculateMultFractionNumDen(fractionNode: fractionNode, fnCtrl: fnCtrl + [.skipAppendStep], &steps.lastStepSubsteps)
        }
        if fractionTermNodes.first!.pinnedRootDidChange {
            steps.lastStepSubsteps.lastExplanation = expantionHasVar ? "Calculate the expressions" : "Multiply the numbers"
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        }
    }
    func insertMultFractionNumDen(fractionNode: StepNode, lcmNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
       
        // insert mult
        for numOrDen in [fractionNode.numerator, fractionNode.denominator] {
            let lcmNodesClone = lcmNodes.cloneWithChangedStaticIDs
            if numOrDen.isMultiNotHighOpChain {
                numOrDen.setBrackets()
                numOrDen.first!.parent!.op = .times
                numOrDen.first!.parent!.insertBefore(contentsOf: lcmNodesClone.withOp(.plus))
                steps.lastMarked.append(contentsOf: numOrDen.parent!.opValueSK)
            } else {
                if lcmNodesClone.hasOnlyBrackets(.any) || lcmNodesClone.first!.isBrackets {
                    if let brktInNumOrDen = numOrDen.last(where: {$0.isBrackets}) {
                        brktInNumOrDen.insertAfter(contentsOf: lcmNodesClone)
                    } else {
                        numOrDen.last!.insertAfter(contentsOf: lcmNodesClone)
                    }
                } else if lcmNodesClone.last!.isBrackets {
                    if let brktInNumOrDen = numOrDen.first(where: {$0.isBrackets}) {
                        brktInNumOrDen.insertBefore(contentsOf: lcmNodesClone)
                    } else {
                        numOrDen.last!.insertAfter(contentsOf: lcmNodesClone)
                    }
                } else {
                    numOrDen.last!.insertAfter(contentsOf: lcmNodesClone)
                }
            }
            steps.lastMarked.append(contentsOf: lcmNodesClone.flatSKs)
        }
    }
    func calculateMultFractionNumDen(fractionNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        var fakeSteps = [StepModel()]
        for numOrDen in [fractionNode.numerator, fractionNode.denominator] {
            let markedKeysBeforeMult = numOrDen.flatSKs
            for node in numOrDen {
                evaluateMult(node: node, fnCtrl: fnCtrl + [.force], &fakeSteps)
            }
            removeHighOpOne(node: numOrDen.first!, fnCtrl: fnCtrl + [.force], &fakeSteps)
            if numOrDen.flatKeys != markedKeysBeforeMult.keys {
                steps.lastMarked.append(contentsOf: numOrDen.flatSKs + markedKeysBeforeMult)
            }
        }
    }
}

extension CalcBrain {
    func moveNegativeSignToNumerator(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        if node.isMinus {
            
            // Mark and append
            steps.lastMarked = [node.op]
            steps.lastExplanation = "Move the negative sign to the numerator"
            
            // set brackets and move minus
            if node.numerator.count > 1 && !node.numerator.isMultChain {
                node.numerator.setBrackets()
                steps.lastMarked.append(contentsOf:  node.numerator.first!.valueSK)
            }
            node.numerator.op = node.op
            node.op = .plus
            
            // mark new plus
            steps.lastMarked.append(node.op)
            
            // append step
            appendStep(&steps, fnCtrl: fnCtrl)
        }
    }
    
    func mergeFractions(node: StepNode, fractionTermNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        for node in fractionTermNodes {
            if !node.isFirstIn(in: fractionTermNodes) && (node.numerator.isMinus || node.isMinus && !node.numerator.isMultChain) {
                node.numerator.setBrackets()
                steps.lastMarked.append(contentsOf: node.numerator.first!.valueSK)
            }
        }
        node.numerator.append(contentsOf: fractionTermNodes.dropFirst.map({$0.numerator}).flatMap({$0}).map({$0.withOp($0.isFirst ? $0.parentFraction!.op : $0.op)}).clone(changeID: false, withParent: false).children)
        fractionTermNodes.dropFirst.removeNodesFromParent()
    }
}

extension CalcBrain {
    func fractionToNumberAddition(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if !fnCtrl.contains(.forcePowerAddition) && fnCtrl.contains(.skipAddition) {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isWholeNumber(mayBeCoeff: true) || node.isDecimal {} else {return}
        if !node.isPlusOrMinus || node.isMultipliedOrDivideOrDivided {return}
        guard let filteredLevel = node.level?.dropMultipliedBracketChain else {return}
        if !filteredLevel.hasFraction(flat: false) {return}
        if filteredLevel.hasHighOp || filteredLevel.hasBrackets(.any) || filteredLevel.hasFraction(part: .denominator, { nodes in nodes.hasRadicalFlat}) {return}
        if node.nodesSameTerm(in: filteredLevel.dropFractions).count == 1 {} else {return}
        var termNodes = node.fractionNodesCommonTerm(in: filteredLevel)
        if termNodes.isEmpty {
            if filteredLevel.onlyFractions.count == 1 {} else {return}
            termNodes = [filteredLevel.first(where: {$0.isFraction})!]
            if node.isInSimplestFraction || node.parentIsRadical && node.parent!.isSimplestRadical || node.level!.dropFractions.isSimplestForm && (fnCtrl.isForced && node.isInBrackets || (fnCtrl.isForced || !node.isEquation) && termNodes.first!.denominator.hasVarFlat) {} else {return}
        }
        else if termNodes.count == 1 {} else {return}
        let fractionNode = termNodes.first!
        if !fractionNode.isPlusOrMinus || fractionNode.isMultipliedOrDivideOrDivided {return}
        if fractionNode.isFraction(.notSimplest(for: .numerator)) || fractionNode.isFraction(part: .denominator, {$0.hasRadicalFlat || !$0.isSimplestFormNegletTimesBracket}) || fractionNode.isFraction(.hasFraction) {return}
        if fractionNode.numerator.hasDecimal || fractionNode.denominator.hasDecimal {return}
        if fractionNode.denominator.isOne(opCase: .any) {return}
        if !fnCtrl.isForced && fractionNode.numerator.hasVarFlat && node.isEquation {return}
        
        //
        if node.isDecimal {
            node.pinRootExpr()
            convertDecimalToFraction(node: node, fnCtrl: fnCtrl + [.force, .forceConvertDecimalToFraction, .moreCertainForceConvertDecimalToFraction], &steps)
            if node.pinnedRootDidChange {return}
        }
        
        // determine fraction sign
        determineChainSign(node: termNodes.filter({$0.isFraction}).first!, fnCtrl: fnCtrl + [.force], &steps)
        
        // Explain
        let hasVar = node.hasVar
        let hasConst = !hasVar && node.hasConstSymbOrRad
        let toBeAddedNodes = node.idx! > fractionNode.idx! ? [fractionNode, node] : [node, fractionNode]
        steps.lastMarked = toBeAddedNodes.flatSKs.dropHiddens
        let minusOrEmpty: [Key] = toBeAddedNodes.isMinus ? [toBeAddedNodes.op.key]: (toBeAddedNodes.first!.isFraction && (fractionNode.isMinus || fractionNode.numerator.isMinus) ? [fractionNode.flatKeys.first(where: {$0.isMinus})!] : [])
        steps.lastExplanation = fractionAdditionExplanation(ops: minusOrEmpty + toBeAddedNodes.getOps.keys.dropFirst(), fromFracToNumAdd: true, hasVar: hasVar, hasConst: hasConst, forTitleStep: false)
        
        // set substeps
        steps.lastStepSubsteps = [steps.last!]
        steps.lastStepSubsteps.lastMarked.removeAll()
        
        //
        steps.lastStepSubsteps.lastStep.setTitle(title: fractionAdditionExplanation(ops: minusOrEmpty + toBeAddedNodes.getOps.keys.dropFirst(), fromFracToNumAdd: true, hasVar: hasVar, hasConst: hasConst, forTitleStep: true), subtitle: "#"+toBeAddedNodes.flatSKs(.dropPlus).str)
        
        // Convert to fraction
        if node.isFraction {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        convertNodeToFractionAndSetDenominatorToOne(node: node, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
        
        // Add fractions
        node.pinRootExpr()
        node.nodeProduct = .commaNode.withOp(.comma)
        fractionToFractionAddition(node: [node, fractionNode].sorted(by: {$0.idx! < $1.idx!}).first!, fromFracToNumAdd: true, fnCtrl: fnCtrl + [.force, .forceFractionAddition], &steps)
        if !node.pinnedRootDidChange {
            steps.lastStepLastSubsteps.removeAll()
            steps.lastMarked.removeAll()
            steps.lastExplanation = ""
            node.removeDenominator()
        }
    }
}

extension CalcBrain {
    func fractionAdditionExplanation(ops: [Key], fromFracToNumAdd: Bool, hasVar: Bool, hasConst: Bool, forTitleStep: Bool) -> String {
        if ops.isEmpty || ops.contains(where: {!$0.isPlusOrMinus}) {return ""}
        enum ExplType {
            case add, sum, subtract, difference, calculate
        }
        let plusCount = ops.filter({$0 == .plus}).count
        let minusCount = ops.filter({$0 == .minus}).count
        
        var explType: ExplType {
            if plusCount == 1 && minusCount == 0 {
                return fromFracToNumAdd ? .sum : .add
            } else if plusCount > 1 && minusCount == 0 {
                return .sum
            } else if minusCount == 1 && plusCount == 0 {
                return fromFracToNumAdd ? .difference : .subtract
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
            return forTitleStep ? "Adding Fractions" : "Add the fractions"
        case .sum:
            return forTitleStep ? fromFracToNumAdd ? "Adding Fraction & \(hasVar ? "Variable" : "\(hasConst ? "" : "Whole ")Number")" : "Adding Fractions" : "Calculate the sum"
        case .subtract:
            return forTitleStep ? "Subtracting Fractions" : "Subtract the fractions"
        case .difference:
            return forTitleStep ? fromFracToNumAdd ? "Subtracting Fraction & \(hasVar ? "Variable" : "\(hasConst ? "" : "Whole ")Number")" : "Subtracting Fractions" : "Calculate the difference"
        case .calculate:
            return forTitleStep ? fromFracToNumAdd ? "Combining Fraction & \(hasVar ? "Variable" : "\(hasConst ? "" : "Whole ")Number")" : "Combining Fractions" : "Calculate the expression"
        }
    }
}

extension CalcBrain {
    func reorderAllToMatchFirstOrPos(nestedNodes: [[StepNode]], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        guard nestedNodes.dropFirst().contains(where: {!nestedNodes.first!.isEqualAndSameOrderTo(nodes: $0)}) else {return}
        
        //
        let referenceNodes = nestedNodes.first!.isPlus ? nestedNodes.first! : nestedNodes.first(where: {$0.isPlus}) ?? nestedNodes.first!
        
        //
        for nodes in nestedNodes.filter({!referenceNodes.isEqualAndSameOrderTo(nodes: $0)}) {
            let newOrder = nodes.orderedToMatch(nodes: referenceNodes)
            reorderTermsTo(nodes: newOrder, fnCtrl: fnCtrl, &steps)
        }
    }
}

extension CalcBrain {
    func fractionAdditionAllowed(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeClone = node.clone(changeID: false, withParent: true)
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        if !fnCtrl.isSkipAppendStep {
            appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        }
        fractionAddition(node: nodeClone, fnCtrl: fnCtrl + [.skipPrintStep, .forceFractionAddition, .checkAllowed], &tmpSteps)
        return nodeClone.pinnedRootDidChange
    }
}
