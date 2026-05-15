//
//  SurfAndApplyFn.swift
//  Hulul
//
//  Created by Ahmad on 07/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    
    enum SurfFnCases {
        case cancelOppositeTermsSameSide, cancelEqualTermsBothSides, removeHighOpOne, reduce, determineSign, decimalTofraction, removeZero, convertNegativeExponent, determineSignOfPoweredBrackets
    }
    
    func surfAndApplyFnBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], surfFnCases: SurfFnCases, _ steps: inout [StepModel]) {
        if !nodeL.isEmpty {
            surfAndApplyFn(mainNode: nodeL, otherNode: nodeR, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
        }
        if !nodeR.isEmpty {
            surfAndApplyFn(mainNode: nodeR, otherNode: nodeL, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
        }
    }
    
    func surfAndApplyFn(mainNode: StepNode, otherNode: StepNode?, fnCtrl: [FnCtrl], surfFnCases: SurfFnCases, _ steps: inout [StepModel]) {
        for node in mainNode.children + (mainNode.op.key == .sqrt ? [mainNode] : []) {
            
            if !node.exist {continue}
            if surfFnCases != .cancelEqualTermsBothSides {
                if node.isBrackets(.complete) && node.op.key != .sqrt {
                    surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
                } else if node.isFraction {
                    surfAndApplyFn(mainNode: node.numerator.parent!, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
                    if !node.isFraction {continue}
                    surfAndApplyFn(mainNode: node.denominator.parent!, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
                }
            }
            
            if !node.exist {continue}
            switch surfFnCases {
            case .removeZero:
                removeZero(node: node, fnCtrl: fnCtrl, &steps)
            case .cancelOppositeTermsSameSide:
                cancelOppositeTerms(node: node, fnCtrl: fnCtrl, &steps)
            case .cancelEqualTermsBothSides:
                cancelEqualTerms(mainNode: node, otherParent: otherNode!, fnCtrl: fnCtrl, &steps)
            case .removeHighOpOne:
                removeHighOpOne(node: node, fnCtrl: fnCtrl, &steps)
            case .convertNegativeExponent:
                if node.baseNode.isInMultChain {
                    convertNegativeExponent(node: node, fnCtrl: fnCtrl + [.forceConvNegExp], &steps)
                }
            case .determineSignOfPoweredBrackets:
                determineSignOfPoweredBrackets(node: node, fnCtrl: fnCtrl + [.force], &steps)
            case .determineSign:
                determineChainSign(node: node, fnCtrl: fnCtrl + [.force], &steps)
            case .decimalTofraction:
                convertNestedFractionIntoMainFractions(node: node, fnCtrl: fnCtrl + [.force], &steps)
                convertDecimalsInFraction(node: node, fnCtrl: fnCtrl + [.force], &steps)
                convertDecimalToFraction(node: node, fnCtrl: fnCtrl, &steps)
            case .reduce:
                determineChainSignTillEnd(node: node, fnCtrl: fnCtrl + [.force], &steps)
                reduceSubFractionDens(node: node, fnCtrl: fnCtrl + [.force], &steps)
                if !node.exist {continue}
                reduceDividedFraction(node: node, fnCtrl: fnCtrl + [.force], &steps)
                if !node.exist {continue}
                reduceFraction(node: node, fnCtrl: fnCtrl + [.force], &steps)
            }
            
            if !node.exist {continue}
            if surfFnCases != .cancelEqualTermsBothSides {
                if node.exist && node.isPowered {
                    surfAndApplyFn(mainNode: node.powerParent!, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
                }
                if let radicalParent = node.radicalParent, node.exist {
                    surfAndApplyFn(mainNode: radicalParent, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
                }
                if node.exist && node.hasDirectSymbs {
                    surfAndApplyFn(mainNode: node, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
                }
            }
        }
    }
}
