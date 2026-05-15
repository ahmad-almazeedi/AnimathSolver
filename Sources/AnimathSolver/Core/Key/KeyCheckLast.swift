//
//  KeyTypeCheckLast.swift
//  Hulul
//
//  Created by Ahmad on 10/08/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

extension Key {
    
    var isCustom: Bool {
        if case .custom(_) = self {
            return true
        }
        return false
    }
    var isNumberOrDot: Bool {
        switch self {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .dot:
            return true
        default:
            return false
        }
    }
    var isNumber: Bool {
        switch self {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            return true
        default:
            return false
        }
    }
    var isLetter: Bool {
        switch self {
        case .a, .b, .c, .d, .euler, .e, .f, .g, .h, .imaginary, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z:
            return true
        case .A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W:
            return true
        case .alpha, .beta, .gamma, .delta, .epsilon, .theta, .lambda, .mu, .pi, .rho, .sigma, .omega:
            return true
        case .Gamma, .Delta, .Theta, .Lambda, .Pi, .Sigma, .Phi, .Omega:
            return true
        default:
            return false
        }
    }
    var isZero: Bool {self == .zero}
    
    var isOperand: Bool {
        if isLetter {return true}
        switch self {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .dot, .euler, .pi, .imaginary, .x, .notVarX, .y, .z:
            return true
        default:
            return false
        }
    }
            
    var isOp: Bool {
        switch self {
        case .divide, .times, .plus, .minus, .plusMinus, .pow, .sqrt, .superTimes, .fraction, .typedEqual, .notEqual, .approximately:
            return true
        default:
            return false
        }
    }
    
    var isNonWrappingOp: Bool {
        switch self {
        case .divide, .times, .plus, .minus, .plusMinus, .superTimes, .typedEqual, .notEqual, .approximately:
            return true
        case .custom(let str):
            guard str.count == 1 else {return false}
            return String.allOperators.contains(str.first!)
        default:
            return false
        }
    }
    
    var isPrime: Bool {
        switch self {
        case .prime, .doublePrime, .triplePrime:
            return true
        default:
            return false
        }
    }
    
    var isMinus: Bool {self == .minus}
    var isPlus: Bool {self == .plus || self == .plusMinus}
    var isTimes: Bool {self == .times}
    var isDivide: Bool {self == .divide}
    var isPowOrSqrt: Bool {self == .pow || self == .sqrt}
    var isPowOrRoot: Bool {self == .pow || self.isRoot}
    var isPlusNotPlusMinus: Bool {self == .plus}

    var isPlusOrMinus: Bool {self == .plus || self == .minus || self == .plusMinus}
    var isTimesOrPow: Bool {self == .times || self == .pow}
    var isTimesOrDivide: Bool {self == .times || isDivide}
    
    var isSquared: Bool {self == .squared}
    var isCubed: Bool {self == .cubed}
    var isPowOfValue: Bool {self == .squared || self == .cubed}
    
    var isOpenBracket: Bool {self == .openBracket || self == .openSquareBrkt || self == .openCurlyBrkt}
    var isCloseBracket: Bool {self == .closeBracket || self == .closeSquareBrkt || self == .closeCurlyBrkt}
    var isOpenSquareBrkt: Bool {self == .openSquareBrkt}
    var isCloseSquareBrkt: Bool {self == .closeSquareBrkt}
    var isOpenCurlyBrkt: Bool {self == .openCurlyBrkt}
    var isCloseCurlyBrkt: Bool {self == .closeCurlyBrkt}
    var isSquareBrkt: Bool {self == .openSquareBrkt || self == .closeSquareBrkt}
    var isCurlyBrkt: Bool {self == .openCurlyBrkt || self == .closeCurlyBrkt}
    var isBracket: Bool {self == .openBracket || self == .closeBracket || self == .openSquareBrkt || self == .closeSquareBrkt || self == .openCurlyBrkt || self == .closeCurlyBrkt}
    var isParenthesis: Bool {self == .openBracket || self == .closeBracket}
    var isOpenParenthesis: Bool {self == .openBracket}
    var isClosedParenthesis: Bool {self == .closeBracket}
    var isHiddenOpenBrkt: Bool {self == .openSquareBrkt || self == .openCurlyBrkt}
    var isHiddenCloseBrkt: Bool {self == .closeSquareBrkt || self == .closeCurlyBrkt}

    var isRightArrow: Bool {self == .rightArrow}
    var isLeftArrow: Bool {self == .leftArrow}
    var isArrow: Bool {isLeftArrow || isRightArrow}
    
    var isFraction: Bool {self == .fraction}
    var isRoot: Bool {self == .sqrt || self == .cbrt || self == .root}
            
    // Solver
    var isSymb: Bool {
        if isLetter {return true}
        switch self {
        case .x, .notVarX, .y, .z, .euler, .pi, .imaginary, .temp:
            return true
        default:
            return false
        }
    }
    var isTerm: Bool {
        if isLetter {return true}
        switch self {
        case .x, .notVarX, .sqrt, .y, .z, .euler, .pi, .imaginary, .temp:
            return true
        default:
            return false
        }
    }
    var isConstant: Bool {
        switch self {
        case .pi, .euler, .e:
            return true
        default:
            return false
        }
    }
    var isVar: Bool {
        switch self {
        case .x, .y, .z, .a, .b, .c, .j, .m, .n, .p, .q, .s, .t, .A, .B, .C, .J, .M, .N, .P, .Q, .S, .T, .alpha, .beta, .delta, .lambda, .kappa, .mu, .nu, .sigma:
            return true
        default:
            return false
        }
    }
    var isVarNotXYZ: Bool {
        isVar && ![.x, .y, .z].contains(self)
    }
    var isXYZ: Bool {
        [.x, .y, .z].contains(self)
    }
    var isVarOrNotVarX: Bool {
        isVar || self == .notVarX
    }
    var isVarOrI: Bool {
        isVar || self == .imaginary
    }
    var isVarOrNotVarXOrI: Bool {
        isVarOrI || self == .imaginary || self == .notVarX
    }
    var isHighOp: Bool {
        switch self {
        case .divide, .pow, .times:
            return true
        default:
            return false
        }
    }
    var powValue: Int {
        isSquared ? 2 : 3
    }
    var noNudge: Bool {
        switch self {
        case .ac, .leftArrow, .rightArrow, .showStepsKey, .practiceMode, .camera, .importImg, .keyboard, .home:
            return true
        default:
            return false
        }
    }
    var isComma: Bool {self == .comma}
    var isCommaOrDot: Bool {self == .comma || self == .dot}
    var isTemp: Bool {self == .temp}
    var isInputOrCloseBrkt: Bool {
        switch self {
        case .showStepsKey, .practiceMode, .leftArrow, .rightArrow, .camera, .importImg, .ac, .del, .closeBracket, .home:
            return false
        default:
            return true
        }
    }
    var needOffset: Bool {
        switch self {
        case .divide, .times, .plus, .minus, .typedEqual, .notEqual, .x, .y, .z, .pi, .euler, .sqrt, .cbrt, .root:
            return true
        default:
            return false
        }
    }
    
    var isFractionOrDivide: Bool {
        self == .fraction || self == .divide
    }
    
    var isCameraOrImportImg: Bool {
        self == .camera || self == .importImg
    }
    
    var isAltKeyRightToLeft: Bool {
        self == .camera || self == .fraction
    }
    var isKeypadType: Bool {
        switch self {
        case .mainKeypad, .secondKeypad, .lettersKeypad:
            return true
        default:
            return false
        }
    }
    var isFunction: Bool {
        switch self {
        case .log, .ln, .sin, .cos, .tan, .csc, .sec, .cot, .sinh, .cosh, .tanh, .arcsin, .arccos, .arctan:
            return true
        default:
            return false
        }
    }
    var isGreekLetter: Bool {
        switch self {
        case .alpha, .beta, .gamma, .delta, .epsilon, .phi, .eta, .kappa, .lambda, .mu, .nu, .omega, .pi, .rho, .sigma, .theta,
             .Gamma, .Delta, .Phi, .Lambda, .Omega, .Pi, .Sigma, .Theta:
            return true
        default:
            return false
        }
    }
//    var hasDoubleWidth: Bool {
//        switch self {
//        case  :
//            return false
//        default:
//            return false
//        }
//    }
}
