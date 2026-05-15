//
//  ReduceExponentiable.swift
//  Hulul
//
//  Created by Ahmad on 07/11/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func reduceFirstExponentiable(numNode: StepNode, denChain: [StepNode], fnCtrl: [FnCtrl], sameFraction: Bool, _ steps: inout [StepModel]) {
        
        // Conditions
//        return
//        if !numNode.isNumber(mayBePowered: true) || numNode.isDecimal {fatalError()}
//        if numNode.isPoweredByWholeNumber {} else {return}
//        let tmpMultChainFirst = numNode.isInFraction ? numNode.parentFraction.multChain(forward: false).first! : numNode.multChain(forward: false).first!
//        if isReducible(node: tmpMultChainFirst, fnCtrl: fnCtrl + [.skipReduceExponentiable]) {return}
//
//        // Original NumNode
//        let firstSymbStaticID = numNode.hasDirectSymbs ? numNode.directSymbs.first!.staticID : Int32.random
//        let origNumNode = numNode.clone(changeID: false, withParent: true)
//
//        // Set new base and power
//        let exponentialForm = numNode.getExponentialForm
//        if exponentialForm.powerValue == 1 {
//                // Reduce
//                let cloneNumNode = numNode.clone(changeID: false, withParent: true)
//                var fakeSteps = [StepModel()]
//                let multChainFirst = cloneNumNode.isInFraction ? cloneNumNode.parentFraction.multChain(forward: false).first! : cloneNumNode.multChain(forward: false).first!
//                let numMultChain = cloneNumNode.isInDenominator ? multChainFirst.denominatorMultChain(termMix: false) : multChainFirst.numeratorMultChain(termMix: false)
//                numMultChain.dropNode(node: cloneNumNode).setNodesToTimesOne()
//                cloneNumNode.pinRootExpr()
//                reduceFraction(node: multChainFirst, fnCtrl: fnCtrl + [.force, .forceReduce, .skipReduceExponentiable, .skipCommonFactor, .skipReduceToSimplify, .skipAppendStep], &fakeSteps)
//                if cloneNumNode.pinnedRootDidChange {
//                    numNode.isReduced = true
//                    return
//                }
//        } else {
//
//            // Mark and Explain
//            steps.lastMarked = numNode.valueSK
//            steps.lastExplanation = "Write \(numNode.valueKeys.str) in exponential form with the base of \(exponentialForm.valueSK.strForExpl)"
//
//            // Convert
//            numNode.convertToExponentialForm()
//
//            // Mark and append
//            steps.lastMarked.append(contentsOf: numNode.flatSKs(.dropOp) + numNode.parent!.valueSK)
//            appendStep(&steps, fnCtrl: fnCtrl)
//
//            // Multiply powers
//            distributePowerIntoBrackets(node: numNode.parent!, fnCtrl: fnCtrl + [.force], &steps)
//
//            // Reduce
//            let cloneNumNode = numNode.parent!.clone(changeID: false, withParent: true)
//            var fakeSteps = [StepModel()]
//            let multChainFirst = cloneNumNode.isInFraction ? cloneNumNode.parentFraction.multChain(forward: false).first! : cloneNumNode.multChain(forward: false).first!
//            let numMultChain = cloneNumNode.isInDenominator ? multChainFirst.denominatorMultChain(termMix: false) : multChainFirst.numeratorMultChain(termMix: false)
//            numMultChain.dropNode(node: cloneNumNode).setNodesToTimesOne()
//            cloneNumNode.pinRootExpr()
//            reduceFraction(node: multChainFirst, fnCtrl: fnCtrl + [.force, .forceReduce, .skipReduceExponentiable, .skipCommonFactor, .skipReduceToSimplify, .skipAppendStep], &fakeSteps)
//            if cloneNumNode.pinnedRootDidChange {
//                numNode.parent!.isReduced = true
//                return
//            }
//        }
//
//        // reduce the exponentiable way
//        var denExponentialForm = StepNode()
//        guard let denNode = denChain.first(where: {
//            denExponentialForm = $0.getExponentialForm
//            return !denExponentialForm.isPoweredByOne && denExponentialForm.hasEqualBase(with: numNode)
//        }) else {
//            if exponentialForm.powerValue != 1 {
//                steps.removeLast()
//                steps.removeLast()
//                steps.removeLast()
//                let numNodeParent = numNode.parent!
//                if let extractedSymb = numNodeParent.level.first(where: {$0.hasDirectSymbs && $0.directSymbs.contains(where: {$0.staticID == firstSymbStaticID})}) {
//                    extractedSymb.remove()
//                }
//                numNodeParent.insertAfter(numNode)
//                numNodeParent.remove()
//                numNode.content = origNumNode.content
//            }
//            numNode.root.setSurfedToFalse()
//            return
//        }
//
//        // Write Divider in exponential form
//        writeDividerInExponentialForm(numNode: numNode, denNode: denNode, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    private func writeDividerInExponentialForm(numNode: StepNode, denNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
//        // isReduced
//        if numNode.exist {
//            numNode.isReduced = true
//        } else {
//            numNode.parent!.isReduced = true
//        }
//        denNode.isReduced = true
//        
//        // Mark and Explain
//        steps.lastMarked = denNode.valueSK
//        steps.lastExplanation = "Write \(denNode.valueKeys.str) in exponential form with the base of \(denNode.getExponentialForm.valueSK.strForExpl)"
//        
//        // Convert
//        denNode.convertToExponentialForm()
//        
//        // Mark and append
//        steps.lastMarked.append(contentsOf: denNode.flatSKs(.dropOp) + denNode.parent!.valueSK)
//        appendStep(&steps, fnCtrl: fnCtrl)
//        
//        // Multiply powers
//        distributePowerIntoBrackets(node: denNode.parent!, fnCtrl: fnCtrl + [.force], &steps)
    }
}
