//
//  RegulerTrinomial.swift
//  Hulul
//
//  Created by Ahmad on 15/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func factorTriReguler(parent: StepNode, aNode: StepNode, bNode: StepNode, cNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if parent.children.hasBrackets {return}
        if parent.children.count == 3 {} else {return}
        if parent.children.allSymbs.hasConstSymb {return}
        if parent.children.allPowers.contains(where: {!($0.isWholeNumber(mayBeCoeff: false) && $0.first!.valueDouble > 0)}) {return}
        if aNode.isOneTerm {} else {return}
        guard let gcdNode = [aNode, bNode].getGCDWithTerms(withOp: false), !gcdNode.directSymbs.isEmpty else {return}
        guard aNode.hasGCDTermWithBNotC(bNode: bNode, cNode: cNode) else {return}
        guard cNode.hasGCDTermWithBNotC(bNode: bNode, cNode: aNode) else {return}
        if aNode.isMinus {
            [aNode,bNode,cNode].flipSigns()
        }
        guard let pqTuple = [bNode.opValueDouble, cNode.opValueDouble].addGetPMultGetQ else {return}
        
        //
        var newParent = parent
        if newParent.children.isMinus {
            extractCommonFactor(nodes: newParent.children, withOp: true, fnCtrl: [.forceExtractMinus], &steps)
            newParent = newParent.children.first(where: {$0.isBrackets}) ?? newParent
        }
        
        //
        steps.lastStep.setTitle(title: "Factoring: \(newParent.children.flatSKs(.dropPlus).strForExpl)", subtitle: "Using Reverse FOIL Method")
        
        //
        let firstBrkt = StepNode.newBracketsNode
        let secondBrkt = StepNode.newBracketsNode
        let aSymbs = aNode.directSymbs
        let firstBrktOneSymbs = StepNode.newOneNode.withSymb(symbs: aSymbs)
        let secondBrktOneSymbs = StepNode.newOneNode.withSymb(symbs: aSymbs.cloneWithChangedStaticIDs)
        for aSymb in aSymbs {
            let firstBrktSymb = firstBrktOneSymbs.directSymbs.first(where: {$0.isSymbType(type: aSymb.type?.key)})!
            let secondBrktSymb = secondBrktOneSymbs.directSymbs.first(where: {$0.isSymbType(type: aSymb.type?.key)})!
            let newPowerValue = aSymb.powerValue/2
            if newPowerValue == 1 {
                firstBrktSymb.removePower()
                secondBrktSymb.removePower()
            } else {
                firstBrktSymb.power = [newPowerValue.newNode]
                secondBrktSymb.power = [newPowerValue.newNode]
            }
        }
        firstBrkt.children = [firstBrktOneSymbs]
        secondBrkt.children = [secondBrktOneSymbs]
        secondBrkt.op = .times
        
        //
        steps.lastMarked = newParent.flatSKs(.dropOp)
        let varStr = firstBrktOneSymbs.flatSKs(.dropOp).strForExpl
        steps.lastExplanation = "To factor the trinomial, start by replacing it with:\n( \(varStr) + ? )( \(varStr) + ? )"
        
        //
        if newParent.isBracketsNotHidden && !newParent.isPowered {
            firstBrkt.valueSK[0] = newParent.valueSK.first!
            firstBrkt.valueSK[1] = newParent.valueSK.last!
        }
        
        //
        let pNode = StepNode(valueKeys: [.questionMark])
        let qNode = StepNode(valueKeys: [.questionMark])
        firstBrkt.children.append(pNode)
        secondBrkt.children.append(qNode)
        
        //
        newParent.children = [firstBrkt,secondBrkt]
        if newParent.isBrktAloneInPoweredBrkt {
            newParent.justRemoveBrackets()
        }
        
        //
        steps.lastMarked.append(contentsOf: [firstBrkt,secondBrkt].flatSKs)
        steps.lastStep.appendCloneIDs(originalKeysIDs: firstBrkt.children.first!.directSymbs.flatSKsNoPow.dropOps.ids, clonesKeysIDs: [secondBrkt.children.first!.directSymbs.flatSKsNoPow.dropOps.ids])
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        let bNodeStrNoASymbs = bNode.withSymb(symbs: bNode.directSymbs.filter({bSymb in cNode.directSymbs.contains(where: {$0.isSymbType(type: bSymb.type?.key)})})).flatSKs(.dropPlus).strForExpl
        steps.lastMarked = pNode.flatSKs + qNode.flatSKs
        steps.lastExplanation = "To fill out the blanks, we need to find two numbers:\nmultiplying them equals \(cNode.flatSKs(.dropPlus).strForExpl)\nadding them equals \(bNodeStrNoASymbs)"
        
        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        steps.lastMarked = pNode.flatSKs + qNode.flatSKs
        
        //
        pNode.opValueSK = pqTuple.p.newNode.opValueSK
        qNode.opValueSK = pqTuple.q.newNode.opValueSK
        
        //
        let cSymbsSqrted = cNode.directSymbs.cloneWithChangedStaticIDs
        for cSymb in cSymbsSqrted {
            let newPowerValue = cSymb.powerValue/2
            if newPowerValue == 1 {
                cSymb.removePower()
            } else {
                cSymb.power = [newPowerValue.newNode]
            }
        }
        pNode.directSymbs = cSymbsSqrted.cloneWithChangedStaticIDs
        qNode.directSymbs = cSymbsSqrted.cloneWithChangedStaticIDs
        
        //
        let pNodeStr = pNode.flatSKs(.dropPlus).strForExpl
        var qNodeStr = qNode.flatSKs(.dropPlus).strForExpl
        if pqTuple.q < 0 {
            qNodeStr = "(" + qNodeStr + ")"
        }
        let eq1Str = "\(pNodeStr) × \(qNodeStr) = \(cNode.flatSKs(.dropPlus).strForExpl)"
        let eq2Str = "\(pNodeStr) + \(qNodeStr) = \(bNodeStrNoASymbs)"
        steps.lastExplanation = "The numbers are \(pNodeStr) and \(qNodeStr.filter({$0 != "(" && $0 != ")"})) :\n\(eq1Str)\n\(eq2Str)"

        //
        steps.lastMarked.append(contentsOf: pNode.flatSKs + qNode.flatSKs)
        
        //
        appendStep(&steps, fnCtrl: fnCtrl + [.skipCopyStepTitle])
        
        //
        factorByFormula(parent: firstBrkt, fnCtrl: fnCtrl, &steps)
        factorByFormula(parent: secondBrkt, fnCtrl: fnCtrl, &steps)
    }
}
