//
//  BuildNodes.swift
//  Hulul
//
//  Created by Ahmad on 14/08/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func buildStepNodes(flatSKs: [StepKey], isLeft: Bool, typedEqualID: Int32? = nil, inputFromImg: Bool = false) -> StepNode {
        var flatSKs = flatSKs.dropFirstIfPlus
        if flatSKs.isEmpty {return StepNode()}
        if flatSKs.first!.isFirstHiddenBracket {
            flatSKs.removeFirst()
        }
        addTimesBeforeBracketsNoSteps(exprSKs: &flatSKs)
        let node = StepNode()
        if !isLeft {
            node.isLeft = false
            node.valueSK = [Key.typedEqual.withID(typedEqualID ?? Int32.random)]
        }
        var i = 0
        inBuild(flatSKs: flatSKs, parent: node, i: &i, inputFromImg: inputFromImg)
        if i == -1 {return StepNode()}
        removeTimesFromTermsFromOutNoStep(nodeL: node, nodeR: StepNode())
        return node
    }
    
    func inBuild(flatSKs: [StepKey], parent: StepNode, i: inout Int, inputFromImg: Bool) {
        
        // Initializations
        var nodes: [StepNode] {
            get {parent.children}
            set {parent.children = newValue}
        }
        var node: StepNode {nodes.last!}
        if i > flatSKs.count-1 {return}
        var stepKey: StepKey {i < flatSKs.count ? flatSKs[i] : .comma}
        if !nodes.isEmpty {
            node.isLeft = parent.isLeft
        }
        
        // Node Building
        if stepKey.key.isCustom || inputFromImg && stepKey.key.isSymb {
            if nodes.isEmpty || !node.isEmpty {
                nodes.append(StepNode(op: .plus))
                nodes.last?.op.idIsZero = true
            }
            node.valueSK.append(stepKey)
        } else if stepKey.key.isOpenCurlyBrkt {
            
            // Init Fraction Node
            let fractionNode = StepNode()
            fractionNode.isLeft = parent.isLeft
            
            // Set Num Node
            let numNode = nodes.isEmpty ? StepNode() : node.clone(changeID: false, withParent: false)
            if !nodes.isEmpty {
                node.remove()
            }
            numNode.valueSK.append(stepKey)
            numNode.isLeft = parent.isLeft
            i += 1
            inBuild(flatSKs: flatSKs, parent: numNode, i: &i, inputFromImg: inputFromImg)
            if i == -1 {return}
            if !stepKey.key.isHiddenCloseBrkt {i = -1; return}
            numNode.valueSK.append(stepKey)
            
            // Append it into fraction
            fractionNode.children.append(numNode)
            fractionNode.op = numNode.op
            numNode.op = .plus
            
            // Insert fraction key
            i += 1
            if !stepKey.key.isFraction {i = -1; return}
            fractionNode.valueSK = [stepKey]
            
            // Set denNode
            i += 1
            if !stepKey.key.isOpenCurlyBrkt {i = -1; return}
            let denNode = StepNode(valueSK: [stepKey])
            denNode.isLeft = parent.isLeft
            i += 1
            inBuild(flatSKs: flatSKs, parent: denNode, i: &i, inputFromImg: inputFromImg)
            if i == -1 {return}
            if !stepKey.key.isHiddenCloseBrkt {i = -1; return}
            denNode.valueSK.append(stepKey)
            
            // append it into fraction
            fractionNode.children.append(denNode)
            
            // append fraction node
            nodes.append(fractionNode)
            
        }
        
        else if stepKey.key == .pow { // DUPLICATE: Building Power
            if nodes.isEmpty {
                i += 2
                return
            }
            let poweredParent = StepNode(op: stepKey, valueSK: [flatSKs[i+1]])
            poweredParent.parent = node.hasAfterSymbsRadical ? node.radicalParent : node.hasDirectSymbs ? node.directSymbs.last! : node.hasDirectRadical ? node.radicalParent : node
            poweredParent.isLeft = parent.isLeft
            if !flatSKs[i+1].key.isOpenSquareBrkt {i = -1; return}
            i += 2
            inBuild(flatSKs: flatSKs, parent: poweredParent, i: &i, inputFromImg: inputFromImg)
            if i == -1 {return}
            if !stepKey.key.isCloseSquareBrkt {i = -1; return}
            poweredParent.valueSK.append(stepKey)
            if let radicalParent = node.radicalParent, radicalParent.isAfterSymbs {
                radicalParent.powerParent = poweredParent
            } else if node.hasDirectSymbs {
                node.directSymbs.last!.powerParent = poweredParent
            } else if let radicalParent = node.radicalParent {
                radicalParent.powerParent = poweredParent
            } else {
                node.powerParent = poweredParent
            }
        }
        
        else if stepKey.key == .sqrt {
            var sqrtValueSK = [flatSKs[i+1],flatSKs[i+2]]
            let sqrtOp = stepKey
            if flatSKs[i+2].key.isNumber {
                sqrtValueSK.append(flatSKs[i+3])
                i += 1
            }
            if !flatSKs[i+2].key.isOpenSquareBrkt {i = -1; return}
            let radicalParent = StepNode(op: sqrtOp, valueSK: sqrtValueSK)
            if nodes.isEmpty {
                nodes.append(StepNode(op: .plus))
            }
            var valueIsOne = false
            if node.valueSK.isEmpty || node.valueKeys == [.minus] {
                node.valueSK.append(.one)
            }
            else if node.hasDirectSymbs {radicalParent.isAfterSymbs = true}
            else if node.valueIsOne {valueIsOne = true}
            radicalParent.parent = node
            radicalParent.isLeft = parent.isLeft
            i += 3
            inBuild(flatSKs: flatSKs, parent: radicalParent, i: &i, inputFromImg: inputFromImg)
            if i == -1 {return}
            if !stepKey.key.isCloseSquareBrkt {i = -1; return}
            radicalParent.valueSK.append(stepKey)
            node.radicalParent = radicalParent
            if valueIsOne {
                node.showOneTerm = true
            }
        }
        
        else if (nodes.isEmpty || node.isSemiEmpty) && stepKey.key == .times && i < flatSKs.count-1 && flatSKs[i+1].key == .sqrt {
            if nodes.isEmpty {
                nodes.append(StepNode(op: .plus))
            } 
        }
        
        else if stepKey.key == .minus {
            if !nodes.isEmpty && node.valueSK.isEmpty {
                node.valueSK.append(stepKey)
            } else {
                nodes.append(StepNode(op: stepKey))
            }
        }
        
        else if stepKey.key.isOp {
            nodes.append(StepNode(op: stepKey))
        }
        
        else {
            
            if nodes.isEmpty && !stepKey.key.isHiddenCloseBrkt {
                nodes.append(StepNode(op: .plus))
            }
            
            if stepKey.key.isNumberOrDot {
                node.valueSK.append(stepKey)
            }
            
            else if !inputFromImg && stepKey.key.isSymb {
                guard nodes.appendSymb(newSK: stepKey) else {i = -1; return}
            }
            
            else if stepKey.key.isOpenBracket {
                node.valueSK.append(stepKey)
                i += 1
                inBuild(flatSKs: flatSKs, parent: node, i: &i, inputFromImg: inputFromImg)
                if i == -1 {return}
                if stepKey.key.isCloseBracket && !stepKey.isHiddenBracket {
                    node.valueSK.append(stepKey)
                } else if stepKey.key.isHiddenCloseBrkt {return}
            }
            
            else if stepKey.key.isCloseBracket {return}
            
            else if inputFromImg {
                if nodes.isEmpty || !node.isEmpty {
                    nodes.append(StepNode(op: .plus))
                    nodes.last?.op.idIsZero = true
                }
                node.valueSK.append(stepKey)
            }
                        
            else {i = -1; return}
        }
        
        // Next StepKey
        i += 1
        inBuild(flatSKs: flatSKs, parent: parent, i: &i, inputFromImg: inputFromImg)
    }
}

func addTimesBeforeBracketsNoSteps(exprSKs: inout [StepKey]) {
    var i = 0
    while i < exprSKs.count {
        if i != 0 {
            if exprSKs[i].key.isOpenBracket && !exprSKs[i].key.isOpenSquareBrkt && (exprSKs[i-1].key.isOperand || exprSKs[i-1].key.isCloseBracket) {
//                var timesOp = StepKey.times
//                if !exprSKs[i-1].key.isCloseBracket && !exprSKs[i].isHiddenBracket {
//                    timesOp.setIsHiddenTimes(flag: true)
//                }
//                exprSKs.insert(timesOp , at: i)
                var timesSK = StepKey.times
                if exprSKs[i-1].key.isCustom {
                    timesSK.idIsZero = true
                }
                exprSKs.insert(timesSK , at: i)
            }
        }
        i += 1
    }
}
