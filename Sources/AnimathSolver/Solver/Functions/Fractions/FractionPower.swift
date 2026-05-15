//
//  FractionPower.swift
//  Hulul
//
//  Created by Ahmad on 18/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func distributePowerIntoFraction(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.power.count == 1 {} else {return}
        if node.isBrackets(.singleFraction(fractionCase: .simplestReducedNegletPowered)) {} else {return}
        if node.children.isMinus {return}
        if node.isInBrackets && willDistributePowerIntoBrackets(node: node.parent!, fnCtrl: fnCtrl) {return}
        let fractionNode = node.children.first!
                
        // Mark and explain
        steps.lastMarked = node.power.flatSKs(.any) + fractionNode.numerator.flatSKs(.any) + fractionNode.denominator.flatSKs(.any)
        steps.lastExplanation = "To raise a fraction to a power, raise the numerator and denominator to that power"
        steps.lastNote = node.children.isMinus ? "Beware that if the exponent was even we have to remove the minus before applying this step" : ""
        
        // parenthesize if appropriate
        for level in [fractionNode.numerator, fractionNode.denominator] {
            if level.isMulti {
                level.setBrackets()
                steps.lastMarked.append(contentsOf: level.parent!.valueSK)
            } else if level.hasTerm {
                level.first!.setBrackets()
                steps.lastMarked.append(contentsOf: level.parent!.valueSK)
            }
        }
        
        //
        if fractionNode.numerator.isBrackets {
            fractionNode.numerator.first!.valueSK = node.valueSK
            steps.lastMarked.append(contentsOf: fractionNode.numerator.first!.valueSK)
        }
        if fractionNode.denominator.isBrackets {
            if fractionNode.numerator.isBrackets {
                steps.lastStep.appendCloneIDs(originalKeysIDs: node.valueSK.ids, clonesKeysIDs: [fractionNode.denominator.first!.valueSK.ids])
            } else {
                fractionNode.denominator.first!.valueSK = node.valueSK
            }
            steps.lastMarked.append(contentsOf: fractionNode.denominator.first!.valueSK)
        }

        // distribute power
        for numOrDenFirst in fractionNode.numeratorAndDenominator.map({$0.baseOrTermNode}) {
            let isInDenominator = numOrDenFirst.isInDenominator
            let parentPowClone = node.power.first!.clone(changeID: isInDenominator, withParent: false).withOp(.times)
            if isInDenominator {
                parentPowClone.changeStaticIDWithChildren()
            }
            if !numOrDenFirst.isPowered {
                numOrDenFirst.power = [parentPowClone.withOp(.plus)]
            } else {
                numOrDenFirst.power.append(parentPowClone)
            }
            steps.lastMarked.append(contentsOf: parentPowClone.flatSKs(.any))
        }

        // remove original power
        node.removePower()
        
        // nextmark and append step
        steps.lastStep.appendCloneIDs(originalKeysIDs: fractionNode.numerator.first!.power.last!.valueSK.ids, clonesKeysIDs: [fractionNode.denominator.first!.power.last!.valueSK.ids])
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // evaluate powers checks
        let numIsBrkts = fractionNode.numerator.first!.isBrackets(.complete)
        let denIsBrkts = fractionNode.denominator.first!.isBrackets(.complete)
        
        // evaluate powers
        evaluateMult(node: fractionNode.numerator.first!.baseOrTermNode.power.first!, fnCtrl: fnCtrl + [.force], &steps)
        if numIsBrkts {
            distributePowerIntoBrackets(node: fractionNode.numerator.first!, fnCtrl: fnCtrl + [.force], &steps)
        }
        evaluateMult(node: fractionNode.denominator.first!.baseOrTermNode.power.first!, fnCtrl: fnCtrl + [.force], &steps)
        if denIsBrkts {
            distributePowerIntoBrackets(node: fractionNode.denominator.first!, fnCtrl: fnCtrl + [.force], &steps)
        }
        
        guard let parentFraction = fractionNode.numerator.first!.parentFraction else {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        let fractionMultChain = parentFraction.multChain(forward: false)
        if !(numIsBrkts && denIsBrkts) && !(parentFraction.isAlone && parentFraction.isInFraction) && !parentFraction.isDivide && !fractionMultChain.dropNode(node: parentFraction).hasBrackets && !isReducible(node: parentFraction, fnCtrl: fnCtrl) {
            if !(fractionNode.parent!.parent!.isSqrt && !fractionNode.parent!.parent!.isSimplestRadical) {
                if !numIsBrkts {
                    evaluatePow(node: fractionNode.numerator.first!, fnCtrl: fnCtrl + [.force], &steps)
                }
                if !denIsBrkts {
                    evaluatePow(node: fractionNode.denominator.first!, fnCtrl: fnCtrl + [.force], &steps)
                }
            }
        }
    }
}
