//
//  FactorTriWithCoeff.swift
//  Hulul
//
//  Created by Ahmad on 21/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func factorTriWithCoeff(parent: StepNode, aNode: StepNode, bNode: StepNode, cNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if parent.children.hasBrackets {return}
        if parent.children.count == 3 {} else {return}
        if parent.children.allSymbs.hasConstSymb || aNode.directVars.isEmpty {return}
        if parent.children.allPowers.contains(where: {!($0.isWholeNumber(mayBeCoeff: false) && $0.first!.valueDouble > 0)}) {return}
        if aNode.valueIsOne {return}
        guard [aNode, bNode].getGCDWithTerms(withOp: false) != nil else {return}
        guard aNode.hasGCDTermWithBNotC(bNode: bNode, cNode: cNode) else {return}
        guard cNode.hasGCDTermWithBNotC(bNode: bNode, cNode: aNode) else {return}
        if aNode.isMinus {
            [aNode,bNode,cNode].flipSigns()
        }
        let acValue = aNode.opValueDouble*cNode.opValueDouble
        guard let pqTuple = [bNode.opValueDouble, acValue].addGetPMultGetQ else {return}
        
        //
        var newParent = parent
        if newParent.children.isMinus {
            extractCommonFactor(nodes: newParent.children, withOp: true, fnCtrl: [.forceExtractMinus], &steps)
            newParent = newParent.children.first(where: {$0.isBrackets}) ?? newParent
        }
        var nodes: [StepNode] {newParent.children}
        
        //
        steps.lastStepSubsteps = [steps.last!]

        //
        steps.lastStep.setTitle(title: "Factoring: \(newParent.children.flatSKs(.dropPlus).strForExpl)", subtitle: "Using AC Method and Grouping")
        
        //
        steps.lastStepSubsteps.lastMarked = nodes.flatSKs
        steps.lastStepSubsteps.lastExplanation = "To use the ac method, first identify the coefficients a, b, and c"
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        steps.lastStepSubsteps.lastMarked = nodes.opValuesSK(.any)
        steps.lastStepSubsteps.lastExplanation = "a = \(aNode.valueSK.strForExpl), b = \(bNode.opValueSK(.dropPlus).strForExpl), c = \(cNode.opValueSK(.dropPlus).strForExpl)"
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        guard let acValueStr = acValue.str else {
            steps.setToUnableToSolve(nodeL: parent.root, nodeR: parent.otherSide)
            return
        }
        steps.lastStepSubsteps.lastExplanation = "Now we need to find two numbers:\nmultiplying them = ac = \(aNode.valueSK.strForExpl)×\(cNode.opValueDouble.strWithParenthesisIfNeg) = \(acValueStr)\nadding them = b = \(bNode.opValueSK(.dropPlus).strForExpl)"
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        let eq1Str = "\(pqTuple.p.str) × \(pqTuple.q.strWithParenthesisIfNeg) = \(acValueStr)"
        let eq2Str = "\(pqTuple.p.str) + \(pqTuple.q.strWithParenthesisIfNeg) = \(bNode.opValueSK(.dropPlus).strForExpl)"
        steps.lastStepSubsteps.lastExplanation = "The numbers are \(pqTuple.p.str) and \(pqTuple.q.str) :\n\(eq1Str)\n\(eq2Str)"
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)

        //
        let toReplaceNode = nodes[1]
        let bNodeDirectSymbs = bNode.directSymbs
        var newNodes = [pqTuple.p.newNode.withSymb(symbs: bNodeDirectSymbs.cloneWithChangedStaticIDs), pqTuple.q.newNode.withSymb(symbs: bNodeDirectSymbs.cloneWithChangedStaticIDs)]
        if toReplaceNode.isPlus && newNodes.isMinus && newNodes.last!.isPlus {
            newNodes.swapAt(0, 1)
        }
        for i in 0..<newNodes.first!.directSymbs.count {
            newNodes.first!.directSymbs[i].valueSK = bNodeDirectSymbs[i].valueSK
            if newNodes.first!.directSymbs[i].isPowered {
                newNodes.first!.directSymbs[i].power.first!.valueSK = bNodeDirectSymbs[i].power.first!.valueSK
            }
        }
        steps.lastStepSubsteps.lastStep.appendCloneIDs(originalKeysIDs: newNodes.first!.directSymbs.flatSKsNoOps.ids, clonesKeysIDs: [newNodes.last!.directSymbs.flatSKsNoOps.ids])

        //
        steps.lastStepSubsteps.lastMarked = toReplaceNode.flatSKs(pqTuple.p < 0 ? .any : .dropPlus) + newNodes.flatSKs(toReplaceNode.isMinus ? .any : .dropPlus)
        steps.lastStepSubsteps.lastExplanation = "Now rewrite \(bNode.flatSKs(.dropPlus).strForExpl) as \(newNodes.flatSKs(.dropPlus).strForExpl)"
        
        //
        toReplaceNode.replace(with: newNodes, withOp: false)

        //
        appendStep(&steps.lastStepSubsteps, fnCtrl: fnCtrl)
        
        //
        steps.lastStep.markedKeys = steps.lastStepSubsteps.beforeLastStep.markedKeys
        steps.lastStep.explanation = "Rewrite \(bNode.flatSKs(.dropPlus).strForExpl) as \(newNodes.flatSKs(.dropPlus).strForExpl)"
        steps.lastStep.appendCloneIDs(originalKeysIDs: newNodes.first!.directSymbs.flatSKsNoOps.ids, clonesKeysIDs: [newNodes.last!.directSymbs.flatSKsNoOps.ids])
        appendStep(&steps, fnCtrl: fnCtrl)

        //
        let toGroupNodes = nodes
        groupAndExtractFactor(nodes: toGroupNodes, fnCtrl: fnCtrl, &steps)
        factorOutBrkts(node: toGroupNodes.parent!, fnCtrl: fnCtrl, &steps)
        
        //
        for brktNode in parent.children.onlyBrackets {
            factorByFormula(parent: brktNode, fnCtrl: fnCtrl, &steps)
        }
    }
}
