//
//  FactorByRRT.swift
//  Hulul
//
//  Created by Ahmad on 27/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func factorByRationalRootTheorem(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        
        // Conditions 1
        if fnCtrl.contains(.skipAllExceptFctrBrkt) {return}
        var nodes: [StepNode] {parent.children}
        if nodes.hasFraction(flat: true) || nodes.hasBrackets || nodes.hasRadicalFlat || nodes.hasConstSymb {return}
        if !nodes.hasVarFlat || nodes.hasMultiTypesVars {return}
        if 3...4 ~= nodes.count && nodes.isEqualTo(nodes: nodes.first!.level!) && nodes.isSimplestForm {} else {return}
        if nodes.getGCDWithTerms(withOp: false)?.hasVarFlat ?? false {return}
        if nodes.areDegreeOrdered {} else {return}
        if nodes.first!.directVar!.powerValue.isMultiple(of: 3) {} else {return}
        
        // Conditions 2
        let pFacotrs = nodes.last!.valueDouble.factors
        let qFacotrs = nodes.first!.valueDouble.factors
        let allRatios = pFacotrs.allRatios(with: qFacotrs)
        var rootsValues = [(num: Int, den: Int)]()
        let reducedPowersNodes = nodes.clone(changeID: false, withParent: false).children
        if reducedPowersNodes.first!.directVar!.powerValue > 3 {
            let divider = (reducedPowersNodes.first!.directVar!.powerValue/3).rounded
            for node in reducedPowersNodes {
                if let directVar = node.directVar {
                    directVar.power = [(directVar.powerValue/divider).rounded.newNode]
                }
            }
        }
        for ratioValue in allRatios {
            if reducedPowersNodes.getResult(subtitutes: [ratioValue.num.keys + [.divide, .openBracket] + ratioValue.den.keys + [.closeBracket]], allowNegEvenRoot: true) == 0 {
                rootsValues.append(ratioValue)
            }
        }
        if rootsValues.isEmpty {return}
        if rootsValues.count == 2 || rootsValues.count > 3 {return}
        
        // Init
        let varType = nodes.first!.directVar!.type!
        rootsValues = rootsValues.sorted(by: {abs($0.num) < abs($1.num)})
        
        //
        steps.lastMarked = nodes.flatSKs(.dropPlus)
        steps.lastExplanation = "Factor the polynomial using the Rational Root Theorem" // nextTapped() is depending on this string
        
        //
        if rootsValues.count == 3 {
            
            //
            let brktNode1 = StepNode.newBracketsNode
            let brktNode2 = StepNode.newBracketsNode
            let brktNode3 = StepNode.newBracketsNode
            
            //
            brktNode1.children = [StepNode.newOneNodeWithVar(type: varType.newSK), rootsValues[0].num.withFlippedSign.newNode]
            brktNode2.children = [StepNode.newOneNodeWithVar(type: varType.newSK), rootsValues[1].num.withFlippedSign.newNode]
            brktNode3.children = [StepNode.newOneNodeWithVar(type: varType.newSK), rootsValues[2].num.withFlippedSign.newNode]
            
            //
            if rootsValues[0].den != 1 {
                brktNode1.children.first!.valueSK = rootsValues[0].den.newSKs
            }
            if rootsValues[1].den != 1 {
                brktNode2.children.first!.valueSK = rootsValues[1].den.newSKs
            }
            if rootsValues[2].den != 1 {
                brktNode3.children.first!.valueSK = rootsValues[2].den.newSKs
            }
            
            //
            let varPowerValue = nodes.first!.directVar!.powerValue
            if varPowerValue > 3 {
                let newPowerValue = (varPowerValue/3).rounded
                brktNode1.children.first!.directVar!.power = [newPowerValue.newNode]
                brktNode2.children.first!.directVar!.power = [newPowerValue.newNode]
                brktNode3.children.first!.directVar!.power = [newPowerValue.newNode]
            }
            
            //
            brktNode2.op = .times
            brktNode3.op = .times
            
            //
            let newBrkts = [brktNode1,brktNode2,brktNode3]
            steps.lastMarked.append(contentsOf: newBrkts.flatSKs(.dropPlus))
            nodes.replace(with: newBrkts)
            
            //
            if parent.isBrackets {
                steps.lastStep.appendCloneIDs(originalKeysIDs: parent.valueSK.ids, clonesKeysIDs: newBrkts.map({$0.valueSK.ids}))
                steps.lastMarked.append(contentsOf: parent.valueSK)
            }
            
            //
            appendStep(&steps, fnCtrl: fnCtrl)
            
        } else if rootsValues.count == 1 {
            
            //
            let brktNode1 = StepNode.newBracketsNode
            brktNode1.children = [StepNode.newOneNodeWithVar(type: varType.newSK), rootsValues[0].num.withFlippedSign.newNode]
            if rootsValues[0].den != 1 {
                brktNode1.children.first!.valueSK = rootsValues[0].den.newSKs
            }
            let varPowerValue = nodes.first!.directVar!.powerValue
            if varPowerValue > 3 {
                let newPowerValue = (varPowerValue/3).rounded
                brktNode1.children.first!.directVar!.power = [newPowerValue.newNode]
            }
            
            //
            let rootValue = (rootsValues.first!.num.double/rootsValues.first!.den.double).rounded
            let subtituteValue = rootValue+1
            guard let originalPolyResult = nodes.getResult(subtitutes: [subtituteValue.keys!], allowNegEvenRoot: true),
                  let brkt1Result = brktNode1.children.getResult(subtitutes: [subtituteValue.keys!], allowNegEvenRoot: true)
            else {
                steps.setToUnableToSolve(nodeL: parent.root, nodeR: parent.otherSide)
                return
            }
            let brktNode2Result = (originalPolyResult/brkt1Result).rounded
            
            //
            let brkt2aNode = StepNode.newFractionNode
            let brkt2cNode = StepNode.newFractionNode
            let brktNode2 = StepNode.newBracketsNode
            brktNode2.children = [brkt2aNode, .newOneNodeWithVar(type: varType.newSK), brkt2cNode]
            
            //
            brkt2aNode.numerator = [nodes.first!.cloneWithChangedStaticIDs]
            brkt2aNode.denominator = [brktNode1.children.first!.cloneWithChangedStaticIDs]
            brkt2aNode.surfAndEvaluateAndApplyFnTillEnd()
            brkt2cNode.numerator = [nodes.last!.cloneWithChangedStaticIDs]
            brkt2cNode.denominator = [brktNode1.children.last!.cloneWithChangedStaticIDs]
            brkt2cNode.surfAndEvaluateAndApplyFnTillEnd()
            
            //
            if varPowerValue > 3 {
                let newPowerValue = (brkt2aNode.directVar!.powerValue/2).rounded
                brktNode2.children[1].directVar!.power = [newPowerValue.newNode]
            }

            //
            var brkt2bValue = 1
            while true {
                brktNode2.children[1].valueSK = brkt2bValue.newSKs
                if brktNode2.children.getResult(subtitutes: [subtituteValue.keys!], allowNegEvenRoot: true) == brktNode2Result {
                    break
                }
                brkt2bValue += 1
                if brkt2bValue > 99 {
                    steps.setToUnableToSolve(nodeL: nodes.root, nodeR: nodes.root.otherSide)
                    return
                }
            }
            
            //
            brktNode2.op = .times
            
            //
            let newBrkts = [brktNode1,brktNode2]
            steps.lastMarked.append(contentsOf: newBrkts.flatSKs(.dropPlus))
            nodes.replace(with: newBrkts)
            
            //
            if parent.isBrackets {
                steps.lastStep.appendCloneIDs(originalKeysIDs: parent.valueSK.ids, clonesKeysIDs: newBrkts.map({$0.valueSK.ids}))
                steps.lastMarked.append(contentsOf: parent.valueSK)
            }
            
            //
            appendStep(&steps, fnCtrl: fnCtrl)
        }
        
        //
        if nodes.hasOnlyBrackets(.any) {} else {return}
        for brktNode in nodes {
            factorByFormula(parent: brktNode, fnCtrl: fnCtrl, &steps)
        }
    }
}
