//
//  newReduce.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func reduceFirstCommonFactoredPolynomials(brktNode: StepNode, divChain: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if divChain.isEmpty {return}
        if brktNode.isBrackets({$0.count > 1}) {} else {return}
        
        //
        var brktExtraFnCtrls = [FnCtrl]()
        var divExtraFnCtrls = [FnCtrl]()
        
        //
        var fakeSteps = [StepModel(dynamicExprs: [Expression()])]
        fakeSteps[0].dynamicExprs.nodeL = brktNode.children.clone(changeID: false, withParent: false)
        let brktClone = fakeSteps.first!.dynamicNodeL
        factorPolynomial(parent: brktClone, fnCtrl: fnCtrl.drop(.checkAllowed) + [.skipPrintStep, .skipDistribute], &fakeSteps)
        let brktWithExtractedCF = brktNode.children.withCommonFactorExtracted?.parent ?? brktNode
        let brktCloneFctrdChain = brktClone.children.hasBrackets ? brktClone.children.onlyBrackets : brktClone.isRoot ? [brktClone] : brktClone.multChain(forward: false).onlyBrackets
        
        // Set Divider
        guard let divBrkt = divChain.onlyBrackets.first(where: {tmpDivBrkt in
            let tmpDivBrktIsMultChainOrSimplestForm = tmpDivBrkt.children.isMultChainOrSimplestForm
            if tmpDivBrktIsMultChainOrSimplestForm && tmpDivBrkt.children.isEqualToEitherNodes([brktWithExtractedCF.children, brktWithExtractedCF.children.withFlippedSigns]) {
                brktExtraFnCtrls.append(.skipAllExceptFctrBrkt)
                divExtraFnCtrls.append(.forceSkip)
                return true
            } else if tmpDivBrktIsMultChainOrSimplestForm && brktCloneFctrdChain.contains(where: {tmpDivBrkt.children.isEqualToEitherNodes([$0.children, $0.children.withFlippedSigns])}) {
                divExtraFnCtrls.append(.forceSkip)
                return true
            } else {
                if divChain.dropNode(node: tmpDivBrkt).contains(where: {tmpDivBrkt2 in brktCloneFctrdChain.contains(where: {tmpDivBrkt2.children.isEqualTo(nodes: $0.children)})}) {return false}
                var fakeSteps = [StepModel(dynamicExprs: [Expression()])]
                fakeSteps[0].dynamicExprs.nodeL = tmpDivBrkt.children.clone(changeID: false, withParent: false)
                let divBrktClone = fakeSteps.first!.dynamicNodeL
                divBrktClone.pinRootExpr()
                factorPolynomial(parent: divBrktClone, fnCtrl: fnCtrl.drop(.checkAllowed) + [.skipPrintStep, .skipDistribute], &fakeSteps)
                if divBrktClone.pinnedRootDidChange {
                    let divBrktWithExtractedCF = tmpDivBrkt.children.withCommonFactorExtracted?.parent
                    let divBrktCloneFctrdChain = divBrktClone.children.hasBrackets ? divBrktClone.children.onlyBrackets : divBrktClone.isRoot ? [divBrktClone] : divBrktClone.multChain(forward: false).onlyBrackets
                    if let divBrktWithExtractedCF = divBrktWithExtractedCF, divBrktWithExtractedCF.children.isEqualToEitherNodes([brktWithExtractedCF.children, brktWithExtractedCF.children.withFlippedSigns]) {
                        brktExtraFnCtrls.append(.skipAllExceptFctrBrkt)
                        divExtraFnCtrls.append(.skipAllExceptFctrBrkt)
                        return true
                    } else if divBrktCloneFctrdChain.contains(where: {fctrdBrkt in fctrdBrkt.children.isEqualToEitherNodes([brktWithExtractedCF.children, brktWithExtractedCF.children.withFlippedSigns])}) {
                        brktExtraFnCtrls.append(.skipAllExceptFctrBrkt)
                        return true
                    }
                    else if let divBrktWithExtractedCF = divBrktWithExtractedCF {
                        if divBrktWithExtractedCF.children.isEqualTo(nodes: brktNode.children) {
                            brktExtraFnCtrls.append(.forceSkip)
                            divExtraFnCtrls.append(.skipAllExceptFctrBrkt)
                            return true
                        } else if brktCloneFctrdChain.contains(where: {divBrktWithExtractedCF.children.isEqualToEitherNodes([$0.children, $0.children.withFlippedSigns])}) {
                            divExtraFnCtrls.append(.skipAllExceptFctrBrkt)
                            return true
                        }
                    }
                    return divBrktCloneFctrdChain.contains(where: {fctrdBrkt in brktCloneFctrdChain.contains(where: {fctrdBrkt.children.isEqualToEitherNodes([$0.children, $0.children.withFlippedSigns])})})
                }
            }
            return false
        }) else {return}
        if fnCtrl.isCheckAllowed {brktNode.root.changeContent(); return}
        
        // Factor
        if !brktNode.hasVarFlat || brktNode.children.getDegree >= divBrkt.children.getDegree {
            factorPolynomial(parent: brktNode, fnCtrl: fnCtrl + [.skipDistribute, .reduceAfterFctrPoly] + brktExtraFnCtrls, &steps)
            if !divBrkt.exist {return}
            factorPolynomial(parent: divBrkt, fnCtrl: fnCtrl + [.skipDistribute, .reduceAfterFctrPoly] + divExtraFnCtrls, &steps)
        } else {
            factorPolynomial(parent: divBrkt, fnCtrl: fnCtrl + [.skipDistribute, .reduceAfterFctrPoly] + divExtraFnCtrls, &steps)
            if !divBrkt.exist {return}
            factorPolynomial(parent: brktNode, fnCtrl: fnCtrl + [.skipDistribute, .reduceAfterFctrPoly] + brktExtraFnCtrls, &steps)
        }
        if brktNode.exist && divBrkt.exist {} else {return}
        
        // Reduce
        let brktFctrdChain = brktNode.children.hasBrackets ? brktNode.children.onlyBrackets : brktNode.multChain(forward: false).onlyBrackets
        for i in 0..<brktFctrdChain.count {
            var toReduceBrkt = brktFctrdChain[i]
            let divChain = divBrkt.children.hasBrackets(.any) ? divBrkt.children.onlyBrackets : [divBrkt]
            toReduceBrkt.pinRootExpr()
            if !toReduceBrkt.isPowered && !divChain.contains(where: {$0.children.isEqualToEitherNodes(brktFctrdChain.map({$0.children}))}) && toReduceBrkt.children.withFlippedSigns.isEqualToEitherNodes(divChain.map({$0.children})) {
                if toReduceBrkt.isBrackets && toReduceBrkt.children.count == 2 && !toReduceBrkt.children.withFlippedSigns.first!.isEqualTo(node: divBrkt.children.first!) {
                    flipPositionsOfTwoNodes(node1: toReduceBrkt.children.first!, node2: toReduceBrkt.children.last!, fnCtrl: fnCtrl, &steps)
                }
                var newBrktSKs = [StepKey]()
                if !toReduceBrkt.isPlus {
                    toReduceBrkt.setBracketsAndExtractOp()
                    newBrktSKs.append(contentsOf: toReduceBrkt.parent!.valueSK)
                }
                extractCommonFactor(nodes: toReduceBrkt.children, withOp: true, fnCtrl: fnCtrl + [.forceExtractMinus], &steps)
                steps.beforeLastStep.markedKeys.append(contentsOf: newBrktSKs)
                if let parentFraction = toReduceBrkt.parentFraction {
                    if parentFraction.isMinus {
                        determineChainSign(node: parentFraction, fnCtrl: fnCtrl, &steps)
                    }
                } else if let parentBrkts = toReduceBrkt.parent, parentBrkts.isMinus && toReduceBrkt.isMinus {
                    removeNegativeBrackets(node: toReduceBrkt, fnCtrl: fnCtrl + [.force], &steps)
                }
                toReduceBrkt = toReduceBrkt.children.hasBrackets ? toReduceBrkt.children.first! : toReduceBrkt
            }
            reduceFirstEqualNodes(numNode: &toReduceBrkt, denChain: divChain, fnCtrl: fnCtrl, sameFraction: false, &steps)
            if toReduceBrkt.exist {
                reduceFirstEqualBaseNodes(numNode: toReduceBrkt, denChain: divChain, fnCtrl: fnCtrl, sameFraction: false, &steps)
            }
            if toReduceBrkt.pinnedRootDidChange {return}
        }
    }
}
