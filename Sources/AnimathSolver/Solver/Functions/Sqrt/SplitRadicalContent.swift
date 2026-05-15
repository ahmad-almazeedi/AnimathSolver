//
//  SplitRadicalContent.swift
//  Hulul
//
//  Created by Ahmad on 17/06/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension CalcBrain {
    func splitRadicalContent(rootableNodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        //
        if rootableNodes.isEmpty {return}
        let radicalParent = rootableNodes.first!.baseNode.parent!
        if radicalParent.isPowered {return}
        let firstRadicand = radicalParent.children.first!
        if radicalParent.children.count == 1 && (!firstRadicand.isCoeff || firstRadicand.isOneSingleTerm) || radicalParent.children.dropFirst.hasLowOp {return}
        
        //
        let isSquareRoot = radicalParent.indexInt == 2
        let nthStr = isSquareRoot ? "" : "ⁿ"
        steps.lastMarked = radicalParent.flatSKs
        steps.lastExplanation = "Apply the rule \(nthStr)√ab = \(nthStr)√a \(nthStr)√b"
        steps.lastNote = "where: a ≥ 0, b ≥ 0"

        //
        let originalSqrtOpID = radicalParent.op.id
        let originalSqrtIndexIDs = radicalParent.indexSK.ids
        var sqrtOpClonesIDs = [[Int32]]()
        var sqrtIndexClonesIDs = [[Int32]]()
        let radIsBeforeSymbs = radicalParent.isBeforeSymbs
        let radCoeffSymbs = radicalParent.coeffNode.directSymbs
        let originalRadContent = radicalParent.children.clone(changeID: false, withParent: false).children
        let nonRootables = radicalParent.children.termMix.dropNodes(nodes: rootableNodes)
        let toEvaluateRootNodes = originalRadContent.count == 2 && (rootableNodes.hasOnlyFractions || !nonRootables.isEmpty && nonRootables.hasOnlyFractions && !rootableNodes.contains(where: {!$0.isVar})) ? radicalParent.children : !rootableNodes.contains(where: {!$0.isVar}) && originalRadContent.count == 1 && originalRadContent.directSymbs.symbsAreInSimplestForm && radicalParent.children.termMix.filter({termOrBase in !rootableNodes.containsNode(termOrBase)}).count == 1 ? radicalParent.children.termMix : rootableNodes
        
        //
        for node in toEvaluateRootNodes {
            
            //
            if node.baseNode.parent!.children.isSingleNode {continue}
            
            //
            let origialRadicalParent = node.baseNode.parent!
            let coeffNode = node.baseNode
            if node.isTerm {
                if !coeffNode.isOneSingleTerm {
                    coeffNode.extractTerm(node)
                }
            } else {
                if node.isCoeff {
                    node.extractTerms()
                } else if node.isAlone {continue}
                if node.isTimes {
                    node.op = .plus
                }
            }
            
            //
            let newOneNodeWithSqrt = StepNode.newOneNodeWithSqrt(indexSK: radicalParent.indexSK.newSKs).withOp(.times)
            steps.lastMarked.append(contentsOf: newOneNodeWithSqrt.radicalParent!.opIndex)
            
            //
            let extractedNode = coeffNode.level!.dropNode(node: coeffNode).first!
            if extractedNode.isTimes {
                extractedNode.op = .plus
            }
            
            //
            let newCoeff = node.baseNode
            newCoeff.remove()
            newCoeff.op = newCoeff.isMinus ? newCoeff.op : .plus
            newOneNodeWithSqrt.radicalParent!.children = [newCoeff]
            origialRadicalParent.coeffNode.insertAfter(newOneNodeWithSqrt)
            
            // Swap
            if !fnCtrl.contains(.splitRadicalFromEnd) {
                let tmpContent = origialRadicalParent.children
                origialRadicalParent.children = newOneNodeWithSqrt.radicalParent!.children
                newOneNodeWithSqrt.radicalParent!.children = tmpContent
            }
            
            //
            sqrtOpClonesIDs.append([newOneNodeWithSqrt.radicalParent!.op.id])
            sqrtIndexClonesIDs.append(newOneNodeWithSqrt.radicalParent!.indexSK.ids)
        }
        
        //
        if radIsBeforeSymbs {
            radCoeffSymbs.removeNodesFromParent()
            radicalParent.coeffNode.level!.last(where: {$0.hasDirectRadical && $0.radicalParent!.children.hasStaticIDsOverlap(staticIDs: originalRadContent.staticIDs)})!.directSymbs = radCoeffSymbs
        }
        
        //
        steps.lastStep.appendCloneIDs(originalKeysIDs: [originalSqrtOpID], clonesKeysIDs: sqrtOpClonesIDs)
        steps.lastStep.appendCloneIDs(originalKeysIDs: originalSqrtIndexIDs, clonesKeysIDs: sqrtIndexClonesIDs)

        //
        appendStep(&steps, fnCtrl: fnCtrl)
        
        //
        if let firstRad = radicalParent.coeffNode.level?.first {
            firstRad.changeStaticIDForStepIncrement()
        }
    }
}
