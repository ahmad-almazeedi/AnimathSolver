//
//  ReorderHighDeg.swift
//  Hulul
//
//  Created by Ahmad on 06/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func reorderVarTerms(parentNode: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions
        guard parentNode.isRoot || parentNode.exist else {return}
        if steps.first!.inMainSteps || fnCtrl.isForced {} else {return}
        if !parentNode.isEquation && parentNode.children.count > 2 && !parentNode.children.allTerms.contains(where: {$0.isSqrt || !$0.isVar}) || nodeR.children.isZero {} else {return}
        if fnCtrl.isForced || !parentNode.isChild || parentNode.root.children.count == 1 && parentNode.root.children.isSimplestForm {} else {return}
        if parentNode.children.hasFraction(flat: true) {return}
        if (parentNode.children+nodeR.children).hasMultiTypesVars {return}
        if parentNode.children.isSimplestForm || parentNode.children.isSimplestFormWithVarTimesBrkts {} else {return}
        if !parentNode.children.allSymbs.isHighDegree {return}
        if parentNode.children.dropBrktsAndNextTimes.isSimplestForm && parentNode.children.dropBrktsAndNextTimes.areDegreeOrdered {return}
        let originalOrder = parentNode.children
        
        //
        steps.lastExplanation = "Rewrite the polynomial in standard form"
        
        // Sort
        bubbleSortDegrees(parent: parentNode)
        
        // Mark
        for i in 0..<originalOrder.count {
            if originalOrder[i].id != parentNode.children[i].id {
                steps.lastMarked.append(contentsOf: parentNode.children[i].flatSKs(.any))
            }
        }
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
    
    func bubbleSortDegrees(parent: StepNode) {
        var changed = false
        repeat {
            changed = false
            for node in parent.children.dropBrackets {
                var nextNode = node.next
                if node.deg == nil || nextNode.deg == nil {
                    parent.root.resultCase = .unableToSolve
                    parent.otherSide.resultCase = .unableToSolve
                    return
                }
                if node.next.isBrackets {
                    nextNode = node.next.next
                }
                if nextNode.deg! > node.deg! {
                    if node.isTimes {
                        let brktNode = node.prev
                        let idx = brktNode.idx
                        brktNode.remove()
                        node.remove()
                        parent.children.insert(contentsOf: [brktNode, node], at: idx!+(nextNode.isTimes ? 2 : 1))
                    } else {
                        let idx = node.idx
                        node.remove()
                        parent.children.insert(node, at: idx!+(nextNode.isTimes ? 2 : 1))
                    }
                    changed = true
                }
            }
        } while changed
    }
    
    func reorderTermsTo(nodes: [StepNode], fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        let parent = nodes.parent!
        let originalOrder = parent.children.dropNodes(nodes: parent.children.dropNodes(nodes: nodes))
        if nodes.map({$0.idx}) == originalOrder.map({$0.idx}) {return}
        
        //
        steps.lastExplanation = UseCommutativePropExplanation
        
        // Sort
        parent.children = nodes
        
        // Mark
        for i in 0..<originalOrder.count {
            if originalOrder[i].id != parent.children[i].id {
                steps.lastMarked.append(contentsOf: parent.children[i].flatSKs(.any))
            }
        }
        
        // append step
        appendStep(&steps, fnCtrl: fnCtrl)
    }
}
