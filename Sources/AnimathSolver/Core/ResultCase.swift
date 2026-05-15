//
//  ResultCase.swift
//  AnimathSolver
//
//  Result classification for a solved expression/equation.
//  Extracted from ProblemSession.swift in the original iOS app.
//

import Foundation

enum ResultCase {
    case undefined, unableToSolve, falseForAnyX, trueForAllX, falseEq, trueEq, incomplete, none, loading

    var title: String {
        switch self {
        case .undefined:     return "undefined"
        case .unableToSolve: return "unableToSolve"
        case .falseForAnyX:  return "falseForAnyX"
        case .trueForAllX:   return "trueForAllX"
        case .falseEq:       return "falseEq"
        case .trueEq:        return "trueEq"
        case .none:          return "none"
        case .loading:       return "loading"
        case .incomplete:    return "incomplete"
        }
    }
}
