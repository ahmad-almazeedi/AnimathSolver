//
//  CGSizeShim.swift
//  AnimathSolver
//
//  Stubs for the iOS app's CGSize layout extension methods. The solver
//  uses these as heuristic thresholds when deciding when expressions
//  are "long" for animation/layout purposes. The values here are
//  reasonable defaults; the real iOS app computes them per-device.
//

import Foundation
import CoreGraphics

enum SolverDimKey {
    case exprMaxLength
}

extension CGSize {
    /// Heuristic threshold for "an expression is too long to animate in one piece"
    func forDim(_ key: SolverDimKey) -> CGFloat {
        // iOS app uses screen-derived dimensions; this is a reasonable fallback.
        switch key {
        case .exprMaxLength:
            return width > 0 ? width * 0.85 : 320
        }
    }

    /// Heuristic ratio for line-wrapping calculations
    var exprMaxLengthRatio: Double {
        width > 0 ? Double(width) / 320.0 : 1.0
    }
}
