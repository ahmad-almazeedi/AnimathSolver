//
//  ExtractCommonFactor.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func extractCommonFactorFromBrackets(node: StepNode, factorNode: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        if fnCtrl.contains(.skipExtractCommonFactor) {return}
        if node.isPowered {
            steps.setToUnableToSolve(nodeL: node.root, nodeR: node.otherSide)
            return
        }
        
        // Mark and explain
        factorNode.changeIDs()
        let isOnlyTerms = factorNode.isOneTerm
        let factorIsOnlyMinus = factorNode.isMinus && factorNode.valueIsOne
        if factorIsOnlyMinus {
            steps.lastMarked.append(contentsOf: factorNode.flatSKs + node.children.getOps)
        } else {
            steps.lastMarked.append(contentsOf: (isOnlyTerms ? (node.valueSK + node.children.allSymbs.filter({factorNode.directSymbs.map({$0.type?.key}).contains($0.type?.key)}).flatSKs + node.children.allRadicals.filter({$0.hasEqualBase(with: factorNode.radicalParent ?? .commaNode)}).flatSKs) : node.flatSKs(.dropOp)) + factorNode.flatSKs(.onlyMinus))
        }
        steps.lastExplanation = "Factor out \(factorNode.isOne(opCase: .minus) ? "the negative sign" : factorNode.flatSKs(.onlyMinus).strForExpl) from the expression"
        
        // Preserve Minus
        var origMinus = Key.comma.newSK
        if factorNode.isMinus {
            origMinus = factorNode.op
            if node.isPlusOrMinus {
                steps.lastMarked.append(node.op)
            }
        }
        
        // insert common factor
        factorNode.op = node.op
        node.op = .times
        node.insertBefore(factorNode)
        
        // Preserve original brackets content
        let originalBrktsContent = node.children.clone(changeID: false, withParent: false).children
        let prioritizeLast = !fnCtrl.contains(.extractCmnFctrFromRight) && node.children.first!.isOneSingleSymb && node.children.last!.isOneSingleSymb && factorNode.directVars.count == 1 && node.children.last!.directVars.first(where: {$0.isSymbType(type: factorNode.directVar!.type?.key)})!.powerValue < node.children.first!.directVars.first(where: {$0.isSymbType(type: factorNode.directVar!.type?.key)})!.powerValue
        let originalFirstInNode = (fnCtrl.contains(.extractCmnFctrFromRight) || prioritizeLast ? node.children.last! : node.children.first!)
        var originalFirstInNodeStepExprs = [[StepKey]]()
        originalFirstInNodeStepExprs.append(originalFirstInNode.valueSK)
        let fltrdSymbs = originalFirstInNode.directSymbs.filter({factorNode.hasSymbType(type: $0.type?.key)})
        originalFirstInNodeStepExprs.append(contentsOf: fltrdSymbs.map({$0.valueSK}))
        originalFirstInNodeStepExprs.append(contentsOf: fltrdSymbs.map({$0.power.first?.valueSK ?? []}))
        
        // Divide in brackets
        steps.lastStepSubsteps = [steps.last!]
        for inNode in node.children {
            let divNode = factorNode.clone(changeID: true, withParent: false).withOp(.plus)
            inNode.insertAfter(divNode)
            divNode.setBrackets()
            divNode.parent!.op = .divide
            convertDivisionToFraction(node: inNode, fnCtrl: fnCtrl + [.force, .skipAppendStep], &steps.lastStepSubsteps)
            convertDivisionToFraction(node: divNode.parent!, fnCtrl: fnCtrl + [.force, .skipAppendStep], &steps.lastStepSubsteps)
        }
        for inNode in node.children {
            reduceFraction(node: inNode, fnCtrl: fnCtrl + [.force, .forceReduce, .skipAppendStep], &steps.lastStepSubsteps)
        }
        surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl + [.skipAppendStep], surfFnCases: .removeHighOpOne, &steps.lastStepSubsteps)
        steps.lastStepSubsteps.removeAll()
        
        // Replace Similer Keys
        let similerKeys = originalFirstInNodeStepExprs.first!.filter({!node.children.flatSKs.contains($0)})
        factorNode.valueSK.replaceSimilarKeys(similarKeys: similerKeys)
        let symbsCount = factorNode.directSymbs.count
        for i in 0..<symbsCount {
            if node.children.allSymbs.hasStaticIDsOverlap(staticIDs: factorNode.directSymbs[i].staticIDs) || i+1 >= originalFirstInNodeStepExprs.count {continue}
            factorNode.directSymbs[i].valueSK.replaceSimilarKeys(similarKeys: originalFirstInNodeStepExprs[i+1])
            factorNode.directSymbs[i].power.first?.valueSK.replaceSimilarKeys(similarKeys: originalFirstInNodeStepExprs[(i+1)+symbsCount])
        }
        
        // Flip signs
        if origMinus.key == .minus {
            if !factorNode.isPlus {
                [factorNode, node].setBrackets(extrctOp: true)
                steps.lastMarked.append(contentsOf: factorNode.parent!.valueSK)
            }
            if node.children.isMinus {
                factorNode.op = node.children.op
                node.children.op.changeID()
            } else {
                factorNode.op = origMinus
            }
            node.children.flipSigns()
            if factorNode.isOne {
                var fakeSteps = [StepModel()]
                removeHighOpOne(node: factorNode, fnCtrl: fnCtrl + [.skipAppendStep], &fakeSteps)
            }
            steps.lastMarked.append(contentsOf: (factorIsOnlyMinus ? [] : node.flatSKs) + [factorNode.op])
        }
        
        // Mark and append main step
        if factorIsOnlyMinus {
            steps.lastMarked.append(contentsOf: factorNode.flatSKs + node.children.getOps)
        } else {
            steps.lastMarked.append(contentsOf: isOnlyTerms ? node.children.allSymbs.filter({factorNode.directSymbs.map({$0.type?.key}).contains($0.type?.key)}).flatSKs + node.children.allRadicals.filter({$0.hasEqualBase(with: factorNode.radicalParent ?? .commaNode)}).flatSKs + node.children.filter({$0.isOne}).flatSKs(.dropOp) : node.flatSKs(.dropOp))
        }
        appendStep(&steps, fnCtrl: fnCtrl)
        
        // Merge
        if factorNode.allowMerging(with: originalBrktsContent) {
            steps.appendMergeIDs(originalNode: factorNode, mergeNodes: fnCtrl.contains(.extractCmnFctrFromRight) ? [StepNode](originalBrktsContent.dropLast()) : [StepNode](originalBrktsContent.dropFirst()), withOp: true)
            if similerKeys.isEmpty && !fnCtrl.contains(.extractCmnFctrFromRight) {
                steps.appendMergeIDs(originalNode: factorNode, mergeNodes: [originalBrktsContent.first!], withOp: true)
            }
        }
    }
}
