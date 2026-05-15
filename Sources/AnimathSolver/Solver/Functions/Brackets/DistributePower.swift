//
//  MultiplyPowers.swift
//  Hulul
//
//  Created by Ahmad on 26/07/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func distributePowerIntoBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if !fnCtrl.isForced && (node.isSurfed || node.children.contains(where: {$0.isSurfed})) {return}
        if node.isBrktsNotSqrt && node.isPowered {} else {return}
        evaluatePowerExpr(node: node, fnCtrl: fnCtrl + [.skipPow], &steps)
        if node.power.count == 1 && (node.power.isPlus || node.power.isMinus && node.children.isSingleNode) && !node.power.hasPoweredFlat && !node.power.isZero && node.children.isSingle(mayBeFraction: false, fractionCase: .any, mayBePowered: true, mayBeBrackets: true) {} else {return}
        if node.children.isMinus {return}
        let childNode = node.children.first!
        if node.power.isFraction && !node.isInMultChain && (childNode.hasDirectRadical || !node.children.isSingleNode && node.power.first!.numerator.isOne(opCase: .plus) && !childNode.termMix.hasPoweredByFraction) {return}
        if fnCtrl.isCheckAllowed {node.changeContent(); return}
        
        //
        node.pinRootExpr()
        multiplySameBaseWithFractionAsPower(node: node.children.first!, fnCtrl: fnCtrl, &steps)
        if node.pinnedRootDidChange {return}
        
        //
        if let parent = node.parent, parent.isBrktsNotSqrt {
            node.pinRootExpr()
            distributePowerIntoBrackets(node: parent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        surfAndEvaluateAndApplyFnTillEnd(parent: node.powerParent!, fnCtrl: fnCtrl + [.skipPow], &steps)
        if !node.children.isSingleNode {
            convertNegativeExponent(node: node, fnCtrl: fnCtrl + [.force], &steps)
            if node.power.hasMinusFlatNoPow {return}
        }
        
        //
        if node.parentIsRadical {
            node.pinRootExpr()
            evaluateNthPowerInNthRoot(radicalParent: node.parent!, fnCtrl: fnCtrl + [.forceEvaluateNthPowerInNthRoot], &steps)
            if node.pinnedRootDidChange {return}
        }
        
        //
        node.isSurfed = true
        
        // Mark and explain
        let isMultiplyingPowers = !childNode.isCoeff || childNode.isOneSingleTerm
        steps.lastMarked = node.power.flatSKs + (isMultiplyingPowers ? childNode.flatSKsOnlyPow : [])
        steps.lastExplanation = isMultiplyingPowers ? "To raise a power to another power, multiply the exponents" : "Distribute the exponent over the multiplication"
        
        //
        if node.power.isMinus {
            node.power.first!.setBrackets()
        }
        
        // multiply
        if !childNode.valueIsOne {
            let parentPowClone = node.power.first!.clone(changeID: false, withParent: false).withOp(.times)
            if !childNode.isPowered {
                childNode.power = [parentPowClone.withOp(.plus)]
            } else {
                childNode.power.append(parentPowClone)
            }
            steps.lastMarked.append(contentsOf: parentPowClone.flatSKs(.any))
        }
        
        // term power
        for termNode in childNode.directTerms {
            let termPowClone = node.power.first!.clone(changeID: !childNode.isOneTerm || !termNode.isFirstTerm, withParent: false).withOp(.times)
            if !childNode.isOneTerm || !termNode.isFirstTerm {
                termPowClone.changeStaticIDWithChildren()
            }
            if !termNode.isPowered {
                termNode.power = [termPowClone.withOp(.plus)]
            } else {
                termNode.power.append(termPowClone)
            }
            steps.lastMarked.append(contentsOf: termPowClone.flatSKs(.any))
        }
        
        //
        steps.lastStep.appendCloneIDs(originalKeysIDs: node.power.flatSKs(.dropOp).ids, clonesKeysIDs: childNode.directTerms.dropFirst(childNode.isOneTerm).map({$0.power.last!}).map({$0.flatSKs(.dropOp).ids}))
        
        // remove parent power
        node.removePower()
        if childNode.isMinus && !node.isPlus {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        node.removeBracketsGeneral()
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if !node.valueIsOne {
            if let nodePowerParent = node.powerParent {
                surfAndEvaluateTillEnd(parent: nodePowerParent, fnCtrl: fnCtrl + [.force, .skipSymbMultOrOrder, .skipPow], &steps)
                removePowerOne(node: node, fnCtrl: fnCtrl + [.force], &steps)
            }
        }
        for termNode in node.directTerms {
            if termNode.isSqrt {
                evaluateRadicalPowerExpr(node: node, fnCtrl: fnCtrl + [.force], &steps)
            } else if let symbNodePowerParent = termNode.powerParent {
                surfAndEvaluateTillEnd(parent: symbNodePowerParent, fnCtrl: fnCtrl + [.force, .skipSymbMultOrOrder, .skipPow], &steps)
                removePowerOne(node: termNode, fnCtrl: fnCtrl + [.force], &steps)
            }
        }
        if !node.valueIsOne {
            let multChain = node.multChain(forward: false)
            if multChain.hasFraction(flat: false) {
                reduceFraction(node: multChain.first!, fnCtrl: fnCtrl + [.force], &steps)
            }
            if node.level!.isMultiNotHighOpChain || !node.isInFractionGeneral && !node.isInSqrtGeneral && !node.isInDividedMultChain && !willMultSameBase(node: node) {
                evaluatePow(node: node, fnCtrl: fnCtrl + [.force], &steps)
            }
        }
    }
}

extension CalcBrain {
    func willDistributePowerIntoBrackets(node: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        let nodeClone = node.clone(changeID: false, withParent: true)
        nodeClone.pinRootExpr()
        var tmpSteps = [StepModel()]
        tmpSteps[0].dynamicNodeL = nodeClone.root
        tmpSteps[0].nodeL = nodeClone.root
        appendStep(&tmpSteps, fnCtrl: [.skipPrintStep])
        distributePowerIntoBrackets(node: nodeClone, fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed], &tmpSteps)
        return nodeClone.pinnedRootDidChange
    }
}
