//
//  FactorPolynomial.swift
//  Hulul
//
//  Created by Ahmad on 03/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func factor4TermsByGrouping(nodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if fnCtrl.contains(.skipAllExceptFctrBrkt) {return}
        if nodes.isEqualTo(nodes: nodes.first!.level!) && nodes.count == 4 && nodes.isSimplestForm {} else {return}
        if nodes.getGCDWithTerms(withOp: false) != nil {return}
        if willHaveCommonBrkts(nodes: nodes, fnCtrl: fnCtrl) {} else {return}
        
        //
        steps.lastStep.setTitle(title: "Factoring: \(nodes.flatSKs(.dropPlus).strForExpl)", subtitle: "By Grouping")
                
        //
        groupAndExtractFactor(nodes: nodes, fnCtrl: fnCtrl, &steps)
        factorOutBrkts(node: nodes.parent!, fnCtrl: fnCtrl, &steps)
    }
    
    func groupAndExtractFactor(nodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
      
        //
        group4TermsIntoTwoPairs(nodes: nodes, fnCtrl: fnCtrl, &steps)
     
        //
        let brktNode1 = nodes.parent!.level!.first!
        let brktNode2 = nodes.parent!.level!.last!
        var extractMinus1 = false
        var extractMinus2 = false
        if brktNode1.children.minusCount == 1 && brktNode2.children.minusCount == 1 {
            let minusNode1IsHigh = brktNode1.children.degreeReordered.first!.isMinus
            let minusNode2IsHigh = brktNode2.children.degreeReordered.first!.isMinus
            if minusNode1IsHigh == minusNode2IsHigh {
                if brktNode1.children.isMinus  {
                    extractMinus1 = true
                    extractMinus2 = true
                }
            } else {
                if brktNode1.children.isMinus  {
                    extractMinus1 = true
                } else {
                    extractMinus2 = true
                }
            }
        }
        
        //
        extractCommonFactor(brktNode: brktNode1, fnCtrl: fnCtrl + (extractMinus1 ? [.forceExtractMinus] : []), &steps)
        extractCommonFactor(brktNode: brktNode2, fnCtrl: fnCtrl + (extractMinus2 ? [.forceExtractMinus] : []), &steps)
    }
    
    private func group4TermsIntoTwoPairs(nodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        let firstPair = nodes.firstNodes(2)
        let secondPair = nodes.lastNodes(2)
        
        //
        let firstExprStr = firstPair.flatSKs(.dropPlus).strForExpl
        let secondExprStr = secondPair.flatSKs(.dropPlus).strForExpl
        steps.lastExplanation = "Group \(firstExprStr) together and \(secondExprStr) together"
        
        //
        firstPair.setBrackets(extrctOp: true)
        secondPair.setBrackets(extrctOp: true)
        
        //
        steps.lastMarked = firstPair.parent!.opValueSK(firstPair.isMinus ? .any : .dropPlus) + secondPair.parent!.opValueSK(secondPair.isMinus ? .any : .dropPlus)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
