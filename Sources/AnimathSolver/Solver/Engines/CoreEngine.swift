//
//  CoreEngine.swift
//  Hulul
//
//  Created by Ahmad on 11/06/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func coreEngine(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if steps.hasSplittedSteps {return}
      
        //
        determineSignOfPoweredBrackets(node: node, fnCtrl: fnCtrl, &steps)
        flipFraction(node: node, fnCtrl: fnCtrl, &steps)
        determineChainSignTillEnd(node: node, fnCtrl: fnCtrl, &steps)
        
        //
        evaluateRadicalPowerExpr(node: node, fnCtrl: fnCtrl, &steps)
        simplifyAndEvaluateRadicals(node: node, fnCtrl: fnCtrl, &steps)
        evaluateRadicalChildren(node: node, fnCtrl: fnCtrl, &steps)
        multRadicals(node: node, fnCtrl: fnCtrl, &steps)

        //
        multSameBase(node: node, fnCtrl: fnCtrl, &steps)
        reorderTermsFromIn(node: node, fnCtrl: fnCtrl, &steps)
       
        //
        convertNegativeExponent(node: node, fnCtrl: fnCtrl, &steps)
        for termNode in node.directTerms {
            convertNegativeExponent(node: termNode, fnCtrl: fnCtrl, &steps)
        }
        convertDecimalsInFraction(node: node, fnCtrl: fnCtrl, &steps)
        convertNestedFractionIntoMainFractions(node: node, fnCtrl: fnCtrl, &steps)
        reduceSubFractionDens(node: node, fnCtrl: fnCtrl, &steps)
        mergeRadicalsOfFraction(node: node, fnCtrl: fnCtrl, &steps)
        reduceFraction(node: node, fnCtrl: fnCtrl, &steps)
      
        //
        evaluateChildren(node: node, fnCtrl: fnCtrl, &steps)
        evaluatePowerExpr(node: node, fnCtrl: fnCtrl, &steps)
        
        //
        fractionPowerToRadical(node: node, fnCtrl: fnCtrl, &steps)
     
        //
        distributePowerIntoBrackets(node: node, fnCtrl: fnCtrl, &steps)
        cancelDividerWithMultiplier(node: node, fnCtrl: fnCtrl, &steps)
        convertDivisionToFraction(node: node, fnCtrl: fnCtrl, &steps)
       
        //
        evaluatePow(node: node, fnCtrl: fnCtrl, &steps)
        
        //
        evaluateSymbsPowerExpr(node: node, fnCtrl: fnCtrl, &steps)
        
        //
        distributePowerIntoFraction(node: node, fnCtrl: fnCtrl, &steps)
        mergeWithFraction(node: node, fnCtrl: fnCtrl + [.skipRemoveOneTimesBrkt], &steps)
        evaluateMult(node: node, fnCtrl: fnCtrl, &steps)
        removeBrackets(node: node, fnCtrl: fnCtrl, &steps)
       
        //
        evaluateAddition(node: node, fnCtrl: fnCtrl, &steps)
        fractionAddition(node: node, fnCtrl: fnCtrl, &steps)
        
        //
        rationalizeDenominator(node: node, fnCtrl: fnCtrl, &steps)
    }
}

extension CalcBrain {
    func evaluateChildren(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        
        // Evaluate Children
        if node.isBrackets(.complete) {
            surfAndEvaluate(parent: node, fnCtrl: fnCtrl, &steps)
        } else if node.isFraction {
            surfAndEvaluate(parent: node.children.first!, fnCtrl: fnCtrl, &steps)
            surfAndEvaluate(parent: node.children.last!, fnCtrl: fnCtrl, &steps)
        }
    }
    func evaluateRadicalChildren(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        
        // Evaluate Children
        if let radicalParent = node.radicalParent, !radicalParent.children.isEmpty {
            node.pinRootExpr()
            surfAndEvaluate(parent: radicalParent, fnCtrl: fnCtrl, &steps)
            if node.pinnedRootDidChange {
                radicalParent.isSurfed = true
            }
        }
    }
}

extension CalcBrain {
    func evaluatePowerExpr(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if node.isPowered && (node.power.count > 1 || !node.power.first!.isWholeNumber(mayBeCoeff: true) || !node.power.isSimplestForm) {} else {return}
        
        // Evaluate Expr
        node.pinRootExpr()
        surfAndEvaluate(parent: node.powerParent!, fnCtrl: fnCtrl, &steps)
        if node.pinnedRootDidChange {
            node.isSurfed = true
        }
    }
    private func evaluateSymbsPowerExpr(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isNumber(mayBePowered: true) {} else {return}
        
        // Evaluate Symb Power
        for symbNode in node.directSymbs {
            evaluatePowerExpr(node: symbNode, fnCtrl: fnCtrl, &steps)
        }
    }
    func evaluateRadicalPowerExpr(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        
        // Evaluate Symb Power
        if let radicalParent = node.radicalParent {
            evaluatePowerExpr(node: radicalParent, fnCtrl: fnCtrl, &steps)
            evaluatePow(node: radicalParent.coeffNode, fnCtrl: fnCtrl, &steps)
            evaluateNthRootToTheNthPower(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            simplifyNthRootToTheMthPower(radicalParent: radicalParent, fnCtrl: fnCtrl, &steps)
            radicalParent.coeffNode.setSurfedToFalse(keepTargets: fnCtrl.isKeepTargets)
        }
    }
}
