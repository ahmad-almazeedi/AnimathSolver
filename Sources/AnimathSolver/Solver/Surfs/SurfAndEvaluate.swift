//
//  surfAndEvaluate.swift
//  Hulul
//
//  Created by Ahmad on 06/01/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//


extension CalcBrain {
    func surfAndEvaluateAndApplyFnTillEnd(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        iterationEngine(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        repeat {
            nodeL.pinRootExpr()
            nodeR.pinRootExpr()
            surfAndEvaluateBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
            iterationEngine(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
        } while !nodeL.forceStop && (nodeL.pinnedRootDidChange || nodeR.pinnedRootDidChange)
    }
}

extension CalcBrain {
    
    func surfAndEvaluateBothSides(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        surfAndEvaluate(parent: nodeL, fnCtrl: fnCtrl, &steps)
        surfAndApplyFn(mainNode: nodeL, otherNode: nodeR, fnCtrl: fnCtrl + [.skipCancelIfWillRemain], surfFnCases: .cancelEqualTermsBothSides, &steps)
        surfAndEvaluate(parent: nodeR, fnCtrl: fnCtrl, &steps)
    }
    
    func surfAndEvaluate(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        parent.setSurfedToFalse(keepTargets: fnCtrl.isKeepTargets)
        for node in parent.children {
            if !node.isSurfed {
                coreEngine(node: node, fnCtrl: fnCtrl, &steps)
            }
        }
        if !parent.isEquation && !parent.isRoot && parent.root.children.isSimplestForm {
            reorderVarTerms(parentNode: parent, nodeR: StepNode(), fnCtrl: fnCtrl, &steps)
        }
    }
}

extension CalcBrain {
    func surfAndEvaluateAndApplyFnTillEnd(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        repeat {
            parent.pinRootExpr()
            iterationEngine(nodeL: parent, nodeR: StepNode(), fnCtrl: fnCtrl, &steps)
            surfAndEvaluate(parent: parent, fnCtrl: fnCtrl, &steps)
        } while parent.pinnedRootDidChange
        iterationEngine(nodeL: parent, nodeR: StepNode(), fnCtrl: fnCtrl, &steps)
    }
    func surfAndEvaluateTillEnd(parent: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        repeat {
            parent.pinRootExpr()
            surfAndEvaluate(parent: parent, fnCtrl: fnCtrl, &steps)
        } while parent.pinnedRootDidChange
    }
    func surfAndApplyFnTillEnd(parent: StepNode, surfFnCases: SurfFnCases, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
        repeat {
            parent.pinRootExpr()
            surfAndApplyFn(mainNode: parent, otherNode: nil, fnCtrl: fnCtrl, surfFnCases: surfFnCases, &steps)
        } while parent.pinnedRootDidChange
    }

}

extension CalcBrain {
    func willDivideBothSides(nodeL: StepNode, nodeR: StepNode) -> Bool {
        if nodeR.isEmpty {return false}
        let nodeTuple = surfAndEvaluateOutput(nodeL: nodeL, nodeR: nodeR, fnCtrl: [])
        return divideBothSidesAllowed(nodeL: nodeTuple.nodeL, nodeR: nodeTuple.nodeR, fnCtrl: [])
    }
    func willMultBothSidesByFraction(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
        if nodeR.isEmpty {return false}
        let nodeTuple = surfAndEvaluateOutput(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl)
        return multBothSidesByFractionAllowed(nodeL: nodeTuple.nodeL, nodeR: nodeTuple.nodeR, fnCtrl: [])
    }

    func surfAndEvaluateAndApplyFnTillEndOutput(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> (nodeL: StepNode, nodeR: StepNode) {
        var tempSteps = [StepModel()]
        let nodeLClone = nodeL.clone(changeID: false, withParent: false)
        let nodeRClone = nodeR.clone(changeID: false, withParent: false)
        surfAndEvaluateAndApplyFnTillEnd(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipPrintStep], &tempSteps)
        return (nodeLClone,nodeRClone)
    }
    func surfAndEvaluateOutput(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> (nodeL: StepNode, nodeR: StepNode) {
        var tempSteps = [StepModel()]
        let nodeLClone = nodeL.clone(changeID: false, withParent: false)
        let nodeRClone = nodeR.clone(changeID: false, withParent: false)
        surfAndEvaluateBothSides(nodeL: nodeLClone, nodeR: nodeRClone, fnCtrl: fnCtrl + [.skipDistribute, .skipPrintStep], &tempSteps)
        return (nodeLClone,nodeRClone)
    }
    
}
