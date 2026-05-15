//
//  PoweredBrackets.swift
//  Hulul
//
//  Created by Ahmad on 29/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func evaluatePoweredBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if fnCtrl.contains(.skipDistribute) {return}
        let multChain = node.multChain(forward: false)
        if multChain.contains(where: {$0.isBrackets && $0.children.hasOnlyFractions && $0.children.denominatorsParents.nodesAreEqual}) {return}
        guard let poweredBrackets = multChain.first(where: {$0.isBrackets(.powered) && $0.isPoweredByWholeNumber && 2...3 ~= $0.powerValue && $0.children.isSimplestForm && 2...3 ~= $0.children.count}) else {return}
        if fnCtrl.contains(.skipPow) && (!fnCtrl.contains(.targetToSkipPowOnly) || poweredBrackets.flatTree.contains(where: {$0.isTarget})) {return}
        if multChain.dropNode(node: poweredBrackets).contains(where: {$0.nextNonMultBrkt?.nextNonMultBrkt != nil || $0.isBrackets(.notSimplest)}) {return}
        if poweredBrackets.isInDenominatorAndWillAddFractions {return}
        if poweredBrackets.isInDenominator && poweredBrackets.level!.isMultChain {return}
        if isReducibleAfterFactoring(node: poweredBrackets.parentFraction ?? poweredBrackets, fnCtrl: fnCtrl) {return}
        if !fnCtrl.contains(.semiForceEvalPow) && willRootBothSides(nodeL: node.root, nodeR: node.otherSide, targetNode: poweredBrackets, fnCtrl: fnCtrl + [.semiForceEvalPow, .targetToSkipPowOnly, .keepTargets]) {return}
        if !fnCtrl.contains(.forceDistribute) && willDivideBothSides(nodeL: node.root, nodeR: node.otherSide) {return}

        //
        let root = node.root
        rootBothSides(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl, &steps)
        solveNonLinearEq(nodeL: node.root, nodeR: node.otherSide, fnCtrl: fnCtrl, &steps)
        guard root.children.flatTree.hasBracketsNotHidden else {return}
        
        // extract minus
        if poweredBrackets.children.count == 2 && poweredBrackets.children.isMinus && poweredBrackets.children.last!.isPlus {
            swapTwoChildren(bracketsNode: poweredBrackets, fnCtrl: fnCtrl, &steps)
        }
        
        //
        let originalContent = poweredBrackets.children.clone(changeID: false, withParent: true).children

        //
        steps.lastMarked = poweredBrackets.flatSKs(.dropOp)
        
        //
        let newContent = getNewContent(poweredBrackets: poweredBrackets, fnCtrl: fnCtrl, &steps)
        
        //
        poweredBrackets.removePower()
        poweredBrackets.children = newContent
        steps.lastStepSubsteps.lastMarked.append(contentsOf: newContent.flatSKs)
        
        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl + [.skipRemoveUslessBrktsWithMultiChild])
                
        //
        poweredBrackets.nodeProduct = .commaNode
        surfAndEvaluateAndApplyFnTillEnd(parent: poweredBrackets, fnCtrl: fnCtrl + [.skipAddition, .skipFlattenning, .skipRemoveUslessBrktsWithMultiChild, .skipRadicalSimplifying], &steps.lastStepSubsteps)
        poweredBrackets.nodeProduct = nil
        
        //
        let originalStepExprNoPowNoOps = originalContent.flatSKsNoPow.dropOps
        let originalDenStepExprNoPow = originalContent.denominatorChain.flatSKsNoPow
        let originalStepExprOnlyPow = originalContent.flatSKsOnlyPow
        let originalDenStepExprOnlyPow = originalContent.denominatorChain.flatSKsOnlyPow
        
        //
        poweredBrackets.children.replaceSimilarKeys(with: originalStepExprNoPowNoOps, denStepExpr: originalDenStepExprNoPow, withPow: false)
        poweredBrackets.children.allpowersFlattened.replaceSimilarKeys(with: originalStepExprOnlyPow, denStepExpr: originalDenStepExprOnlyPow, withPow: true)
        if originalContent.count == 2 && steps.lastStepSubsteps.count > 2 {
            if originalContent.parent!.powerValue == 2 {
                steps.lastStep.appendCloneIDs(originalKeysIDs: [originalContent.last!.op.id], clonesKeysIDs: poweredBrackets.children.getOps.dropFirst.dropLast.map({[$0.id]}))
                if !poweredBrackets.flatSKs.overlaps(with: originalContent.parent!.power.first!.valueSK) {
                    if let firstPoweredSymb = (poweredBrackets.children.first!.allSymbs + poweredBrackets.children.last!.allSymbs).first(where: {$0.isPoweredByPosWholeNumber && $0.powerValue == 2}) {
                        firstPoweredSymb.power.first!.valueSK = originalContent.parent!.power.first!.valueSK
                    }
                }
                steps.lastStep.appendCloneIDs(originalKeysIDs: originalContent.parent!.power.first!.valueSK.ids, clonesKeysIDs: (poweredBrackets.children.first!.allSymbs + poweredBrackets.children.last!.allSymbs).filter({$0.isPoweredByPosWholeNumber && $0.powerValue == 2 && $0.power.first!.valueSK.first!.id != originalContent.parent!.power.first!.valueSK.first!.id}).map({$0.power.first!.valueSK.ids}))

            }
            steps.lastStep.appendCloneIDs(originalKeysIDs: originalContent.allSymbs.types.ids, clonesKeysIDs: poweredBrackets.children.dropFirst.dropLast.map({$0.allSymbs.types.ids}))
        }
    
        //
        steps.lastMarked.append(contentsOf: poweredBrackets.children.flatSKs)

        //
        if !poweredBrackets.isMinus && !poweredBrackets.isMultipliedOrDivided {
            for step in steps.lastStepSubsteps.dropFirst() {
                step.markedSide(parentStep: steps.lastStep).flatTree.first(where: {$0.staticID == poweredBrackets.staticID})!.justRemoveBrackets()
                for substep in step.subSteps {
                    if let toRemoveBrktsNode = substep.markedSide(parentStep: steps.lastStep).flatTree.first(where: {$0.staticID == poweredBrackets.staticID}) {
                        toRemoveBrktsNode.justRemoveBrackets()
                    }
                }
            }
            poweredBrackets.justRemoveBrackets()
        }
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func getNewContent(poweredBrackets: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) -> [StepNode] {
        switch (poweredBrackets.children.count, poweredBrackets.powerValue) {
        case (2,2):
            return twoPowTwoBrackets(poweredBrackets: poweredBrackets, fnCtrl: fnCtrl, &steps)
        case (2,3):
            return twoPowThreeBrackets(poweredBrackets: poweredBrackets, fnCtrl: fnCtrl, &steps)
        case (3,2):
            return threePowTwoBrackets(poweredBrackets: poweredBrackets, fnCtrl: fnCtrl, &steps)
        case (3,3):
            return threePowThreeBrackets(poweredBrackets: poweredBrackets, fnCtrl: fnCtrl, &steps)
        default:
            steps.setToUnableToSolve(nodeL: poweredBrackets.root, nodeR: poweredBrackets.otherSide)
            return []
        }
    }
}

extension CalcBrain {
    private func twoPowTwoBrackets(poweredBrackets: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) -> [StepNode] {
        
        //
        let opStr = poweredBrackets.children.last!.isMinus ? "-" : "+"
        steps.lastExplanation = "Use (a\(opStr)b)² = a²\(opStr)2ab+b² to expand the expression"
        steps.lastStepSubsteps = [steps.last!]
        let children = poweredBrackets.children
        
        // a²
        let aSqrd = children.first!.clone(changeID: false, withParent: false)
        if aSqrd.shouldSetBrktIfPowered {
            aSqrd.setSelfToBrackets()
        }
        aSqrd.baseOrTermNode.power = [[poweredBrackets.power.first!.valueSK.first!].newNode]
        
        // 2ab
        let aNode = children.first!.cloneWithChangedStaticIDs
        let bNode = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: children.flatSKs.dropOps.ids, clonesKeysIDs: [[aNode,bNode].flatSKs.dropOps.ids])
        let twoNode = 2.newNode
        if aNode.isMinus {
            aNode.setSelfToBrackets()
        }
        if bNode.isMinus {
            twoNode.op = bNode.op
        }
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.last!.op.id], clonesKeysIDs: [[twoNode.op.id]])
        aNode.op = .times
        bNode.op = .times
        let TwoAB: [StepNode] = [twoNode, aNode, bNode]

        // b²
        let bSqrd = children.last!.clone(changeID: false, withParent: false)
        if bSqrd.isMinus {
            bSqrd.op.key = .plus
        }
        if bSqrd.shouldSetBrktIfPowered {
            bSqrd.setSelfToBrackets(extractOp: true)
        }
        bSqrd.baseOrTermNode.power = [2.newNode]
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [poweredBrackets.power.first!.valueSK.first!.id], clonesKeysIDs: [[bSqrd.baseOrTermNode.power.first!.valueSK.first!.id]])
        
        //
        return [aSqrd] + TwoAB + [bSqrd]
    }
}

extension CalcBrain {
    private func twoPowThreeBrackets(poweredBrackets: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) -> [StepNode] {
        
        //
        let opStr = poweredBrackets.children.last!.isMinus ? "-" : "+"
        steps.lastExplanation = "Use (a\(opStr)b)³ = a³\(opStr)3a²b+3ab²\(opStr)b³ to expand the expression"
        steps.lastStepSubsteps = [steps.last!]
        let children = poweredBrackets.children
        
        // a³
        let aCubed = children.first!.clone(changeID: false, withParent: false)
        if aCubed.shouldSetBrktIfPowered {
            aCubed.setSelfToBrackets()
        }
        aCubed.baseOrTermNode.power = [[poweredBrackets.power.first!.valueSK.first!].newNode]
        
        // 3a²b
        let aSqrd = children.first!.cloneWithChangedStaticIDs
        let bNode = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: children.flatSKs.dropOps.ids, clonesKeysIDs: [[aSqrd,bNode].flatSKs.dropOps.ids])
        if aSqrd.shouldSetBrktIfPowered {
            aSqrd.setSelfToBrackets()
        }
        aSqrd.baseOrTermNode.power = [2.newNode]
        let threeNode1 = 3.newNode
        if bNode.isMinus {
            threeNode1.op = bNode.op
        }
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.last!.op.id], clonesKeysIDs: [[threeNode1.op.id]])
        aSqrd.op = .times
        bNode.op = .times
        let ThreeASqrdB: [StepNode] = [threeNode1, aSqrd, bNode]
        
        // 3ab²
        let aNode = children.first!.cloneWithChangedStaticIDs
        let bSqrd = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: children.flatSKs.dropOps.ids, clonesKeysIDs: [[aNode,bSqrd].flatSKs.dropOps.ids])
        if aNode.isMinus {
            aNode.setSelfToBrackets()
        }
        if bSqrd.isMinus {
            bSqrd.op = .plus
        }
        if bSqrd.shouldSetBrktIfPowered {
            bSqrd.setSelfToBrackets()
        }
        bSqrd.baseOrTermNode.power = [2.newNode]
        aNode.op = .times
        bSqrd.op = .times
        let ThreeABSqrd: [StepNode] = [3.newNode, aNode, bSqrd]
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.last!.op.id], clonesKeysIDs: [[ThreeABSqrd.op.id]])

        // b³
        let bCubed = children.last!.clone(changeID: false, withParent: false)
        if bCubed.shouldSetBrktIfPowered {
            bCubed.setSelfToBrackets(extractOp: true)
        }
        bCubed.baseOrTermNode.power = [3.newNode]
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [poweredBrackets.power.first!.valueSK.first!.id], clonesKeysIDs: [[bCubed.baseOrTermNode.power.first!.valueSK.first!.id]])
        
        //
        return [aCubed] + ThreeASqrdB + ThreeABSqrd + [bCubed]
    }
}

extension CalcBrain {
    private func threePowTwoBrackets(poweredBrackets: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) -> [StepNode] {
        
        //
        steps.lastExplanation = "Use (a+b+c)² = a²+b²+c²+2ab+2ac+2bc to expand the expression"
        steps.lastStepSubsteps = [steps.last!]
        let children = poweredBrackets.children
        
        // a²
        let aSqrd = children.first!.clone(changeID: false, withParent: false)
        if aSqrd.shouldSetBrktIfPowered {
            aSqrd.setSelfToBrackets()
        }
        aSqrd.baseOrTermNode.power = [[poweredBrackets.power.first!.valueSK.first!].newNode]
        
        // b²
        let bSqrd = children[1].clone(changeID: false, withParent: false)
        if bSqrd.shouldSetBrktIfPowered {
            bSqrd.setSelfToBrackets()
        }
        bSqrd.baseOrTermNode.power = [2.newNode]
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [poweredBrackets.power.first!.valueSK.first!.id], clonesKeysIDs: [[bSqrd.baseOrTermNode.power.first!.valueSK.first!.id]])
        
        // c²
        let cSqrd = children.last!.clone(changeID: false, withParent: false)
        if cSqrd.shouldSetBrktIfPowered {
            cSqrd.setSelfToBrackets()
        }
        cSqrd.baseOrTermNode.power = [2.newNode]
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [poweredBrackets.power.first!.valueSK.first!.id], clonesKeysIDs: [[cSqrd.baseOrTermNode.power.first!.valueSK.first!.id]])
        
        // 2ab
        let a1Node = children.first!.cloneWithChangedStaticIDs
        let b1Node = children[1].cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.first!, children[1]].flatSKs.ids, clonesKeysIDs: [[a1Node,b1Node].flatSKs.ids])
        for node in [a1Node, b1Node] {
            if node.isMinus {
                node.setSelfToBrackets()
            }
        }
        a1Node.op = .times
        b1Node.op = .times
        let TwoAB: [StepNode] = [2.newNode, a1Node, b1Node]
        
        // 2ac
        let a2Node = children.first!.cloneWithChangedStaticIDs
        let c1Node = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.first!, children.last!].flatSKs.ids, clonesKeysIDs: [[a2Node,c1Node].flatSKs.ids])
        for node in [a2Node, c1Node] {
            if node.isMinus {
                node.setSelfToBrackets()
            }
        }
        a2Node.op = .times
        c1Node.op = .times
        let TwoAC: [StepNode] = [2.newNode, a2Node, c1Node]
        
        // 2ac
        let b2Node = children[1].cloneWithChangedStaticIDs
        let c2Node = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children[1], children.last!].flatSKs.ids, clonesKeysIDs: [[b2Node,c2Node].flatSKs.ids])
        for node in [b2Node, c2Node] {
            if node.isMinus {
                node.setSelfToBrackets()
            }
        }
        b2Node.op = .times
        c2Node.op = .times
        let TwoBC: [StepNode] = [2.newNode, b2Node, c2Node]
        
        
        //
        return [aSqrd, bSqrd, cSqrd] + TwoAB + TwoAC + TwoBC
    }
}

extension CalcBrain {
    private func threePowThreeBrackets(poweredBrackets: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) -> [StepNode] {
        
        //
        steps.lastExplanation = "Use (a+b+c)³ = a³+b³+c³+3a²b+3a²c+3b²a+3b²c+3c²a+3c²b+6abc to expand the expression"
        steps.lastStepSubsteps = [steps.last!]
        let children = poweredBrackets.children
        
        // a³
        let aCubed = children.first!.clone(changeID: false, withParent: false)
        if aCubed.shouldSetBrktIfPowered {
            aCubed.setSelfToBrackets()
        }
        aCubed.baseOrTermNode.power = [[poweredBrackets.power.first!.valueSK.first!].newNode]
        
        // b³
        let bCubed = children[1].clone(changeID: false, withParent: false)
        if bCubed.shouldSetBrktIfPowered {
            bCubed.setSelfToBrackets()
        }
        bCubed.baseOrTermNode.power = [3.newNode]
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [poweredBrackets.power.first!.valueSK.first!.id], clonesKeysIDs: [[bCubed.baseOrTermNode.power.first!.valueSK.first!.id]])
        
        // c³
        let cCubed = children.last!.clone(changeID: false, withParent: false)
        if cCubed.shouldSetBrktIfPowered {
            cCubed.setSelfToBrackets()
        }
        cCubed.baseOrTermNode.power = [3.newNode]
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [poweredBrackets.power.first!.valueSK.first!.id], clonesKeysIDs: [[cCubed.baseOrTermNode.power.first!.valueSK.first!.id]])
        
        // 3a²b
        let aSqrd1 = children.first!.cloneWithChangedStaticIDs
        let b1Node = children[1].cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.first! ,children[1]].flatSKs.ids, clonesKeysIDs: [[aSqrd1,b1Node].flatSKs.ids])
        if aSqrd1.shouldSetBrktIfPowered {
            aSqrd1.setSelfToBrackets()
        }
        aSqrd1.baseOrTermNode.power = [2.newNode]
        if b1Node.isMinus {
            b1Node.setSelfToBrackets()
        }
        aSqrd1.op = .times
        b1Node.op = .times
        let ThreeASqrdB: [StepNode] = [3.newNode, aSqrd1, b1Node]
        
        // 3a²c
        let aSqrd2 = children.first!.cloneWithChangedStaticIDs
        let c1Node = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.first! ,children.last!].flatSKs.ids, clonesKeysIDs: [[aSqrd2,c1Node].flatSKs.ids])
        if aSqrd2.shouldSetBrktIfPowered {
            aSqrd2.setSelfToBrackets()
        }
        aSqrd2.baseOrTermNode.power = [2.newNode]
        if c1Node.isMinus {
            c1Node.setSelfToBrackets()
        }
        aSqrd2.op = .times
        c1Node.op = .times
        let ThreeASqrdC: [StepNode] = [3.newNode, aSqrd2, c1Node]
        
        // 3b²a
        let bSqrd1 = children[1].cloneWithChangedStaticIDs
        let a1Node = children.first!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children[1] ,children.first!].flatSKs.ids, clonesKeysIDs: [[bSqrd1,a1Node].flatSKs.ids])
        if bSqrd1.shouldSetBrktIfPowered {
            bSqrd1.setSelfToBrackets()
        }
        bSqrd1.baseOrTermNode.power = [2.newNode]
        if a1Node.isMinus {
            a1Node.setSelfToBrackets()
        }
        bSqrd1.op = .times
        a1Node.op = .times
        let ThreeBSqrdA: [StepNode] = [3.newNode, bSqrd1, a1Node]
        
        // 3b²c
        let bSqrd2 = children[1].cloneWithChangedStaticIDs
        let c2Node = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children[1] ,children.last!].flatSKs.ids, clonesKeysIDs: [[bSqrd2,c2Node].flatSKs.ids])
        if bSqrd2.shouldSetBrktIfPowered {
            bSqrd2.setSelfToBrackets()
        }
        bSqrd2.baseOrTermNode.power = [2.newNode]
        if c2Node.isMinus {
            c2Node.setSelfToBrackets()
        }
        bSqrd2.op = .times
        c2Node.op = .times
        let ThreeBSqrdC: [StepNode] = [3.newNode, bSqrd2, c2Node]
        
        // 3c²a
        let cSqrd1 = children.last!.cloneWithChangedStaticIDs
        let a2Node = children.first!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.last! ,children.first!].flatSKs.ids, clonesKeysIDs: [[cSqrd1,a2Node].flatSKs.ids])
        if cSqrd1.shouldSetBrktIfPowered {
            cSqrd1.setSelfToBrackets()
        }
        cSqrd1.baseOrTermNode.power = [2.newNode]
        if a2Node.isMinus {
            a2Node.setSelfToBrackets()
        }
        cSqrd1.op = .times
        a2Node.op = .times
        let ThreeCSqrdA: [StepNode] = [3.newNode, cSqrd1, a2Node]
        
        // 3c²b
        let cSqrd2 = children.last!.cloneWithChangedStaticIDs
        let b2Node = children[1].cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: [children.last! ,children[1]].flatSKs.ids, clonesKeysIDs: [[cSqrd2,b2Node].flatSKs.ids])
        if cSqrd2.shouldSetBrktIfPowered {
            cSqrd2.setSelfToBrackets()
        }
        cSqrd2.baseOrTermNode.power = [2.newNode]
        if b2Node.isMinus {
            b2Node.setSelfToBrackets()
        }
        cSqrd2.op = .times
        b2Node.op = .times
        let ThreeCSqrdB: [StepNode] = [3.newNode, cSqrd2, b2Node]

        // 6abc
        let a3Node = children.first!.cloneWithChangedStaticIDs
        let b3Node = children[1].cloneWithChangedStaticIDs
        let c3Node = children.last!.cloneWithChangedStaticIDs
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: children.flatSKs.ids, clonesKeysIDs: [[a3Node,b3Node, c3Node].flatSKs.ids])
        for node in [a3Node, b3Node, c3Node] {
            if node.isMinus {
                node.setSelfToBrackets()
            }
        }
        a3Node.op = .times
        b3Node.op = .times
        c3Node.op = .times
        let sixABC: [StepNode] = [6.newNode, a3Node, b3Node, c3Node]
        
        //
        let threesWithABCs = ThreeASqrdB + ThreeASqrdC + ThreeBSqrdA + ThreeBSqrdC + ThreeCSqrdA + ThreeCSqrdB
        return [aCubed, bCubed, cCubed] + threesWithABCs + sixABC
    }
}

extension CalcBrain {
    func mergeAndEvaluateEqualBrackets(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        if !node.exist {return}
        if node.isSurfed && !fnCtrl.isForced {return}
        if fnCtrl.contains(.skipDistribute) {return}
        let multChain = node.multChain(forward: false)
        if multChain.count > 1 {} else {return}
        if multChain.onlyBrackets.contains(where: {$0.children.hasOnlyFractions && $0.children.denominatorsParents.nodesAreEqual}) {return}
        let willRootSides = node.otherSide.children.isZero && node.parent!.isRoot && node.hasVarFlat && node.level!.isMultChain
        guard let equalBaseBrktsNotFltrd = (willRootSides ? multChain : multChain.onlyTwoToThreeSimplestBrkts).firstEqualBases else {return}
        var equalBaseBrackets = [StepNode]()
        for brktsNode in equalBaseBrktsNotFltrd {
            if willRootSides || equalBaseBrackets.powerSum + brktsNode.powerValue <= 3 {
                equalBaseBrackets.append(brktsNode)
            }
        }
        
        //
        steps.lastMarked = equalBaseBrackets.flatSKs(.dropOp)
        steps.lastExplanation = "Write the expression in exponential form"
        
        //
        let brktsNotPowered = equalBaseBrackets.filter({!$0.isPowered})
        let firstBrackets = equalBaseBrackets.first!

        // Mark and explain
        steps.lastStepSubsteps = [steps.last!]
        
        // Reorder
        for node in equalBaseBrackets.dropFirst {
            if node.children.flatKeys != firstBrackets.children.flatKeys {
                matchChildrenOrderWith(BrktNode: node, withNodes: firstBrackets.children, fnCtrl: fnCtrl, &steps.lastStepSubsteps)
            }
        }
        
        //
        steps.lastStepSubsteps.lastMarked = brktsNotPowered.flatSKs(.dropOp).dropOps
        steps.lastStepSubsteps.lastExplanation = setExponentToOneExplanation
 
        // Set power to one
        if !brktsNotPowered.isEmpty {
            for node in brktsNotPowered {
                node.power = [.newOneNode]
            }
            steps.lastStepSubsteps.lastMarked.append(contentsOf: brktsNotPowered.flatSKs(.dropOp))
            appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        }
        
        // Mark and explain
        steps.lastStepSubsteps.lastMarked = equalBaseBrackets.flatSKs(.dropOp)
        steps.lastStepSubsteps.lastExplanation = multTermsWithSameBaseExpl
        
        // make all the powers in the first brackets
        let brktsPower = equalBaseBrackets.map({$0.power}).flatMap({$0})
        firstBrackets.power = brktsPower
        
        // Remove other brackets
        equalBaseBrackets.dropFirst.removeNodesFromParent()
        
        // mark and append step
        steps.lastStepSubsteps.lastMarked.append(contentsOf: firstBrackets.power.flatSKs)
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        steps.lastStepSubsteps.appendMergeIDs(originalKeysIDs: firstBrackets.flatSKsNoPow.dropFirstIfOp.ids, mergesKeysIDs: equalBaseBrackets.dropFirst.map({$0.flatSKsNoPow.dropFirstIfOp.ids}))
        
        // Evaluate Addition
        evaluateAddition(node: firstBrackets.power.first!, fnCtrl: fnCtrl + [.force, .forcePowerAddition], &steps.lastStepSubsteps)
        
        //
        steps.lastMarked.append(contentsOf: firstBrackets.power.flatSKs)
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.appendMergeIDs(originalKeysIDs: firstBrackets.flatSKsNoPow.dropFirstIfOp.ids, mergesKeysIDs: equalBaseBrackets.dropFirst.map({$0.flatSKsNoPow.dropFirstIfOp.ids}))

        //
        evaluatePoweredBrackets(node: firstBrackets, fnCtrl: fnCtrl + [.force], &steps)
    }
    
    private func matchChildrenOrderWith(BrktNode: StepNode, withNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        steps.lastMarked = []
        steps.lastExplanation = UseCommutativePropExplanation
        
        //
        var newContent = [StepNode]()
        for node in withNodes {
            newContent.append(BrktNode.children.first(where: {$0.isEqualTo(node: node)})!)
        }
        
        //
        for i in 0..<newContent.count {
            if !newContent[i].isEqualTo(node: BrktNode.children[i]) {
                steps.lastMarked.append(contentsOf: newContent[i].flatSKs)
            }
        }
        
        //
        BrktNode.children = newContent
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
