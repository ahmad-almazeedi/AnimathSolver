//
//  fnsAtEnd.swift
//  Hulul
//
//  Created by Ahmad on 09/11/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

extension CalcBrain {
    func convertToCommonFactorOrAddFractions(nodes: [StepNode], _ steps: inout [StepModel]) {
        
        // Conditions
        if nodes.root.forceStop {return}
        if nodes.first!.isEquation {return}
        if nodes.count == 1 {return}
        
        //
        let root = nodes.root
        root.pinRootExpr()
        
        //
        factorPolynomial(parent: nodes.parent!, fnCtrl: [], &steps)
        if root.pinnedRootDidChange {return}

        //
        addFractionsAtEnd(nodes: nodes, &steps)
    }
    
    private func addFractionsAtEnd(nodes: [StepNode], _ steps: inout [StepModel]) {
        
        // Extract LCM
        if steps.count == 1 {} else {return}
        let newNodes = nodes.parent!.children
        if newNodes.hasFraction(flat: false) && !newNodes.hasFractionFlat(part: .denominator, { nodes in
            nodes.count > 1
        }) {} else {return}
        if newNodes.hasVarFlat {} else {return}
        
        //
        fractionAddition(node: newNodes.first!, fnCtrl: [.force], &steps)
    }
}

