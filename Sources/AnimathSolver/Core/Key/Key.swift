//
//  KeyTypeModel.swift
//  Hulul
//
//  Created by Ahmad on 10/08/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

import Foundation

enum Key: Equatable, Hashable {
    // Keypads
    case mainKeypad, secondKeypad, lettersKeypad, keyboard, keypad
    // Main Keypad
    case showStepsKey, practiceMode, rightArrow, leftArrow, camera, importImg, capture, flashLight
    case ac, del, undo, openBracket, closeBracket, fraction, mixedFrac, shift, home
    case x, notVarX, y, z, seven, eight, nine, divide
    case squared, cubed, pow, four, five, six, times
    case sqrt, cbrt, root, one, two, three, plus
    case pi, euler, imaginary, zero, dot, typedEqual, notEqual, approximately, minus, plusMinus
    case openSquareBrkt, closeSquareBrkt, openCurlyBrkt, closeCurlyBrkt
    case comma, space, superTimes, temp, questionMark, infinity
    case custom(String)
    case lessThan, greaterThan, lessThanOrEqual, greaterThanOrEqual
    case percentage
    // Second Keypad
    case parenthesis, curlyBrackets, squareBrackets
    case sin, csc, sinh, arcsin
    case cos, sec, cosh, arccos
    case tan, cot, tanh, arctan
    case log, logBase, logBase2, ln
    case piHalf, piThird, eulerPow
    case factorial
    case absoluteValue
    case lim, limToPlus, limToMinus
    case functionX, functionXY
    case derivative, generalDerivative, partialDerivative
    case integral, integralBounded
    case degree, degreeMinute, degreeMinuteSecond
    case base
    case base2, base8, base10, base16
    case dotProduct
    case variations, permutations, combinations, combinationsAlt
    case prime, doublePrime, triplePrime
    case sum, prod
    // Letters
    case a, b, c, d, e, f, g, h, j, k, l, m, n, o, p, q, r, s, t, u, v, w
    case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W
    case alpha, beta, gamma, delta, epsilon, phi, eta, kappa, lambda, mu, nu, omega, rho, sigma, theta
    case Gamma, Delta, Phi, Lambda, Omega, Pi, Sigma, Theta
}

//
extension Key {
    var title: String {
        switch self {
        case .mainKeypad: return "numbers"
        case .secondKeypad: return "function"
        case .lettersKeypad: return "abc"
        case .keyboard: return "keyboard"
        case .keypad: return "keypad"
        case .ac: return "C"
        case .del: return "delete.left.fill"
        case .openBracket: return "("
        case .closeBracket: return ")"
        case .openSquareBrkt: return "["
        case .closeSquareBrkt: return "]"
        case .openCurlyBrkt: return "{"
        case .closeCurlyBrkt: return "}"
        case .parenthesis: return "()"
        case .curlyBrackets: return "{}"
        case .squareBrackets: return "[]"
        case .absoluteValue: return "|"
        case .divide: return "÷"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .times: return "×"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .plus: return "+"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .minus: return "−"
        case .zero: return "0"
        case .dot: return "."
        case .pow: return "^"
        case .sqrt: return "√"
        case .euler, .e: return "e"
        case .pi: return "π"
        case .cbrt: return "∛"
        case .root: return "x√"
        case .comma: return ","
        case .superTimes: return "*"
        case .typedEqual: return "="
        case .notEqual: return "≠"
        case .approximately: return "≈"
        case .showStepsKey: return "Step"
        case .practiceMode: return "Quiz"
        case .x, .notVarX: return "𝒙"
        case .y: return "y"
        case .z: return "z"
        case .squared: return "𝒙²"
        case .cubed: return "𝒙³"
        case .temp: fatalError()
        case .fraction, .mixedFrac: return "/"
        case .rightArrow: return "arrow.right"
        case .leftArrow: return "arrow.left"
        case .camera: return "camera.fill"
        case .importImg: return "photo.fill"
        case .capture: return "inset.filled.circle"
        case .flashLight: return "bolt.fill"
        case .questionMark: return "?"
        case .plusMinus: return "±"
        case .imaginary: return "i"
        case .infinity: return "∞"
        case .space: return " "
        case .custom(let customString): return customString
        case .lessThan: return "<"
        case .greaterThan: return ">"
        case .lessThanOrEqual: return "≤"
        case .greaterThanOrEqual: return "≥"
        case .percentage: return "%"
        case .sin: return "sin"
        case .csc: return "csc"
        case .sinh: return "sinh"
        case .arcsin: return "arcsin"
        case .cos: return "cos"
        case .sec: return "sec"
        case .cosh: return "cosh"
        case .arccos: return "arccos"
        case .tan: return "tan"
        case .cot: return "cot"
        case .tanh: return "tanh"
        case .arctan: return "arctan"
        case .log: return "log"
        case .logBase: return "log_"
        case .logBase2: return "log₂"
        case .ln: return "ln"
        case .piHalf: return "π/2"
        case .piThird: return "π/3"
        case .eulerPow: return "e^"
        case .factorial: return "!"
        case .lim: return "lim"
        case .a: return "a"
        case .b: return "b"
        case .c: return "c"
        case .d: return "d"
        case .f: return "f"
        case .g: return "g"
        case .h: return "h"
        case .j: return "j"
        case .k: return "k"
        case .l: return "l"
        case .m: return "m"
        case .n: return "n"
        case .o: return "o"
        case .p: return "p"
        case .q: return "q"
        case .r: return "r"
        case .s: return "s"
        case .t: return "t"
        case .u: return "u"
        case .v: return "v"
        case .w: return "w"
        case .A: return "A"
        case .B: return "B"
        case .C: return "C"
        case .D: return "D"
        case .E: return "E"
        case .F: return "F"
        case .G: return "G"
        case .H: return "H"
        case .I: return "I"
        case .J: return "J"
        case .K: return "K"
        case .L: return "L"
        case .M: return "M"
        case .N: return "N"
        case .O: return "O"
        case .P: return "P"
        case .Q: return "Q"
        case .R: return "R"
        case .S: return "S"
        case .T: return "T"
        case .U: return "U"
        case .V: return "V"
        case .W: return "W"
        case .alpha: return "α"
        case .beta: return "β"
        case .gamma: return "γ"
        case .delta: return "δ"
        case .epsilon: return "ε"
        case .theta: return "θ"
        case .lambda: return "λ"
        case .mu: return "μ"
        case .sigma: return "σ"
        case .phi: return "φ"
        case .omega: return "ω"
        case .eta: return "η"
        case .kappa: return "κ"
        case .nu: return "ν"
        case .rho: return "ρ"
        case .Gamma: return "Γ"
        case .Delta: return "Δ"
        case .Phi: return "Φ"
        case .Lambda: return "Λ"
        case .Omega: return "Ω"
        case .Pi: return "Π"
        case .Sigma: return "Σ"
        case .Theta: return "Θ"
        case .shift: return "shift"
        case .functionX: return "f(x)"
        case .functionXY: return "f(x,y)"
        case .derivative: return "d/dx"
        case .generalDerivative: return "d/d[]"
        case .integral: return "∫"
        case .degree: return "°"
        case .degreeMinute: return "'"
        case .degreeMinuteSecond: return "\""
        case .base: return "[]_"
        case .base2: return "₂"
        case .base8: return "₈"
        case .base10: return "₁₀"
        case .base16: return "₁₆"
        case .dotProduct: return "·"
        case .variations: return "V"
        case .permutations: return "P"
        case .combinations: return "C"
        case .combinationsAlt: return "C"
        case .prime: return "′"
        case .doublePrime: return "″"
        case .triplePrime: return "‴"
        case .sum: return "∑"
        case .prod: return "∏"
        case .partialDerivative: return "∂/∂x"
        case .undo: return "arrow.uturn.backward"
        case .home: return "list.dash"
        default: return ""
        }
    }
}
//
extension Key {
    var homeKeypadID: Key {
        switch self {
        case .keypad:
            return .home
        default:
            return self
        }
    }
    var keypadID: Key {
        switch self {
        case .keypad:
            return .home
        case .importImg:
            return .one
        case .capture:
            return .two
        case .flashLight:
            return .three
        default:
            return self
        }
    }
    var hasImage: Bool {
        switch self {
        case .del, .leftArrow, .rightArrow, .fraction, .camera, .importImg, .capture, .flashLight, .parenthesis, .shift, .mainKeypad, .secondKeypad, .keyboard, .undo, .home: return true
        default: return false
        }
    }
    var hasThinHeight: Bool {
        switch self {
        case .showStepsKey, .practiceMode, .leftArrow, .rightArrow, .keyboard, .camera, .importImg, .home: //, .del, .ac:
            return true
        default:
            return false
        }
    }
    var hasSpecialView: Bool {
        switch self {
        case .variations, .permutations, .combinations, .combinationsAlt,
                .integral, .integralBounded, .fraction, .mixedFrac, .squared, .cubed, .pow, .root, .logBase, .logBase2, .piHalf, .piThird, .eulerPow, .absoluteValue, .lim, .limToPlus, .limToMinus, .parenthesis, .curlyBrackets, .squareBrackets, .derivative, .generalDerivative, .partialDerivative, .sum, .prod, .degree, .degreeMinute, .degreeMinuteSecond, .base, .base2, .base8, .base10, .base16:
            return true
        default:
            return false
        }
    }
    var doesEdit: Bool {
        switch self {
        case .showStepsKey, .practiceMode, .leftArrow, .rightArrow, .camera, .importImg, .shift, .mainKeypad, .secondKeypad, .lettersKeypad, .undo, .capture, .flashLight, .keyboard, .keypad, .home:
            return false
        default:
            return true
        }
    }
    var specialTitle: String? {
        switch self {
        case .permutations:
            return "P"
        case .combinations:
            return "C"
        case .variations:
            return "V"
        case .squared:
            return "2"
        case .cubed:
            return "3"
        case .piHalf:
            return "2"
        case .piThird:
            return "3"
        case .base2:
            return "2"
        case .base8:
            return "8"
        case .base10:
            return "10"
        case .base16:
            return "16"
        case .limToPlus:
            return "+"
        case .limToMinus:
            return "-"
        default:
            return nil
        }
    }
    var greekLetterName: String? {
        if !isGreekLetter { return nil }
        switch self {
        case .alpha: return "alpha"
        case .beta: return "beta" 
        case .gamma: return "gamma"
        case .delta: return "delta"
        case .epsilon: return "epsilon"
        case .phi: return "phi"
        case .eta: return "eta"
        case .kappa: return "kappa"
        case .lambda: return "lambda"
        case .mu: return "mu"
        case .nu: return "nu"
        case .omega: return "omega"
        case .rho: return "rho"
        case .sigma: return "sigma"
        case .theta: return "theta"
        case .Gamma: return "Gamma"
        case .Delta: return "Delta"
        case .Phi: return "Phi"
        case .Lambda: return "Lambda"
        case .Omega: return "Omega"
        case .pi: return "pi"
        case .Pi: return "Pi"
        case .Sigma: return "Sigma"
        case .Theta: return "Theta"
        default: return nil
        }
    }
}
//
extension Key {
    var charWidth: Double {
        switch self {
        case .openCurlyBrkt, .closeCurlyBrkt, .comma: return 0
        case .openBracket: return 0.74
        case .closeBracket: return 0.74
        case .seven: return 0.915
        case .eight: return 1.03
        case .nine: return 1.02
        case .four: return 1.02
        case .five: return 0.982
        case .six: return 1.02
        case .one, .imaginary, .questionMark, .factorial, .absoluteValue: return 0.775
        case .two: return 0.959
        case .three: return 1
        case .zero: return 1.03
        case .dot: return 0.5
        case .sqrt: return 1.15
        case .euler, .e: return 0.9
        case .pi: return 1.13
        case .typedEqual, .notEqual: return 1.2
        case .divide: return 1.2
        case .times: return 1.2
        case .plus: return 1.2
        case .minus: return 1.2
        case .plusMinus: return 1.2
        case .x, .notVarX: return 0.88
        case .y: return 0.85
        case .z: return 0.82
        case .custom(let customTitle): return customTitle.charsWidth
        case .lessThan, .greaterThan: return 1.2
        case .lessThanOrEqual, .greaterThanOrEqual: return 1.2
        case .percentage: return 1.2
        case .parenthesis, .curlyBrackets, .squareBrackets: return 1.48
        case .sin, .cos, .tan, .cot, .sec, .csc: return 3.0
        case .sinh, .cosh, .tanh: return 4.0
        case .arcsin, .arccos, .arctan: return 6.0
        case .log, .logBase, .logBase2: return 4.0
        case .ln: return 2.0
        case .piHalf, .piThird: return 2.0
        case .eulerPow: return 2.0
        case .lim, .limToPlus, .limToMinus: return 4.0
        case .derivative: return 3.5
        case .generalDerivative: return 4.0
        case .integral, .integralBounded: return 1.2
        case .base: return 1.5
        case .base2: return 0.5
        case .base8: return 0.5
        case .base10: return 1.0
        case .base16: return 1.0
        case .dotProduct: return 0.5
        case .variations, .permutations, .combinations, .combinationsAlt: return 1.5
        case .prime, .doublePrime, .triplePrime: return 0.5
        case .sum, .prod: return 1.5
        case .partialDerivative: return 3.5
        default: return title.charsWidth
        }
    }
}
// fontSizeForKey(_ viewSize: CGSize) removed (SwiftUI rendering helper)

// Minimal String.charsWidth approximation used for layout heuristics.
// The iOS app has a more precise per-character width table in its views layer;
// this is a reasonable stand-in.
extension String {
    var charsWidth: Double {
        Double(count)
    }
}
//
extension String {
    var key: Key? {
        if count == 1 {
            return first!.key
        } else {
            switch self {
            case "lim":
                return .lim
            default:
                return nil
            }
        }
    }
}
extension Character {
    var key: Key? {
        switch self {
        case "0":
            return .zero
        case "1":
            return .one
        case "2":
            return .two
        case "3":
            return .three
        case "4":
            return .four
        case "5":
            return .five
        case "6":
            return .six
        case "7":
            return .seven
        case "8":
            return .eight
        case "9":
            return .nine
        case ".":
            return .dot
        case "-","−":
            return .minus
        case "+":
            return .plus
        case "*","×":
            return .times
        case "÷":
            return .divide
        case "=":
            return .typedEqual
        case "≠":
            return .notEqual
        case "(":
            return .openBracket
        case ")":
            return .closeBracket
        case "∞":
            return .infinity
        case " ":
            return .space
        case ",":
            return .comma
        case "!":
            return .factorial
        case "x", "X", "𝒙":
            return .x
        case "y":
            return .y
        case "z":
            return .z
        case "e":
            return .euler
        case "π":
            return .pi
        case "^":
            return .pow
        case "√":
            return .sqrt
        case "[":
            return .openSquareBrkt
        case "]":
            return .closeSquareBrkt
        case "{":
            return .openCurlyBrkt
        case "}":
            return .closeCurlyBrkt
        case "/":
            return .fraction
        case "?":
            return .questionMark
        case "±":
            return .plusMinus
        case "%":
            return .percentage
        case "<":
            return .lessThan
        case ">":
            return .greaterThan
        case "≤":
            return .lessThanOrEqual
        case "≥":
            return .greaterThanOrEqual
//        case "|":
//            return .absoluteValue
        case "a":
            return .a
        case "b":
            return .b
        case "c":
            return .c
        case "d":
            return .d
        case "f":
            return .f
        case "g":
            return .g
        case "h":
            return .h
        case "j":
            return .j
        case "k":
            return .k
        case "l":
            return .l
        case "m":
            return .m
        case "n":
            return .n
        case "o":
            return .o
        case "p":
            return .p
        case "q":
            return .q
        case "r":
            return .r
        case "s":
            return .s
        case "t":
            return .t
        case "u":
            return .u
        case "v":
            return .v
        case "w":
            return .w
        case "A":
            return .A
        case "B":
            return .B
        case "C":
            return .C
        case "D":
            return .D
        case "E":
            return .E
        case "F":
            return .F
        case "G":
            return .G
        case "H":
            return .H
        case "I":
            return .I
        case "J":
            return .J
        case "K":
            return .K
        case "L":
            return .L
        case "M":
            return .M
        case "N":
            return .N
        case "O":
            return .O
        case "P":
            return .P
        case "Q":
            return .Q
        case "R":
            return .R
        case "S":
            return .S
        case "T":
            return .T
        case "U":
            return .U
        case "V":
            return .V
        case "W":
            return .W
        case "α":
            return .alpha
        case "β":
            return .beta
        case "γ":
            return .gamma
        case "δ":
            return .delta
        case "ε":
            return .epsilon
        case "φ":
            return .phi
        case "η":
            return .eta
        case "κ":
            return .kappa
        case "λ":
            return .lambda
        case "μ":
            return .mu
        case "ν":
            return .nu
        case "ω":
            return .omega
        case "ρ":
            return .rho
        case "σ":
            return .sigma
        case "θ":
            return .theta
        case "Γ":
            return .Gamma
        case "Δ":
            return .Delta
        case "Φ":
            return .Phi
        case "Λ":
            return .Lambda
        case "Ω":
            return .Omega
        case "Π":
            return .Pi
        case "Σ":
            return .Sigma
        case "Θ":
            return .Theta
        case "∫":
            return .integral
        case "°":
            return .degree
        case "·":
            return .dotProduct
        case "′":
            return .prime
        case "″":
            return .doublePrime
        case "‴":
            return .triplePrime
        case "∑":
            return .sum
        case "∏":
            return .prod
        default:
            return nil
        }
    }
}
//
extension Key {
    var powTitle: String? {
        switch self {
        case .openBracket: return "⁽"
        case .closeBracket: return "⁾"
        case .seven: return "⁷"
        case .eight: return "⁸"
        case .nine: return "⁹"
        case .four: return "⁴"
        case .five: return "⁵"
        case .six: return "⁶"
        case .plus: return "⁺"
        case .one: return "¹"
        case .two: return "²"
        case .three: return "³"
        case .minus: return "⁻"
        case .zero: return "⁰"
        case .fraction: return "ᐟ"
        case .x, .notVarX: return "ˣ"
        case .y: return "ʸ"
        case .z: return "ᶻ"
        case .euler, .e: return "ᵉ"
        case .space: return " "
        default: return nil
        }
    }
}
//
extension Key {
    var titleForSympy: String? {
        if isNumberOrDot {
            return self.title
        }
        switch self {
        case .openBracket, .openSquareBrkt, .openCurlyBrkt: return "("
        case .closeBracket, .closeSquareBrkt, .closeCurlyBrkt: return ")"
        case .divide, .fraction, .mixedFrac: return "/"
        case .times: return "*"
        case .plus: return "+"
        case .minus: return "-"
        case .pow: return "**"
        case .sqrt: return "sqrt"
        case .euler, .e: return "E"
        case .pi: return "pi"
            //        case .cbrt: return "∛"
            //        case .root: return "x√"
        case .typedEqual: return "="
        case .x, .notVarX: return "x"
        case .y: return "y"
        case .z: return "z"
        case .imaginary: return "I"
        case .infinity: return "oo"
        case .comma: return ","
        case .space: return " "
        case .lessThan: return "<"
        case .greaterThan: return ">"
        case .lessThanOrEqual: return "<="
        case .greaterThanOrEqual: return ">="
        case .percentage: return "/100"
        case .sin: return "sin"
        case .csc: return "csc"
        case .sinh: return "sinh"
        case .arcsin: return "asin"
        case .cos: return "cos"
        case .sec: return "sec"
        case .cosh: return "cosh"
        case .arccos: return "acos"
        case .tan: return "tan"
        case .cot: return "cot"
        case .tanh: return "tanh"
        case .arctan: return "atan"
        case .piHalf: return "pi/2"
        case .piThird: return "pi/3"
        case .eulerPow: return "exp"
        case .factorial: return "factorial"
        case .absoluteValue: return "Abs"
        case .lim: return "limit"
        case .derivative: return "diff"
        case .generalDerivative: return "diff"
        case .integral: return "integrate"
        case .degree: return "deg"
        case .dotProduct: return "*"
        case .sum: return "Sum"
        case .prod: return "Product"
        case .partialDerivative: return "diff"
        default: return nil
        }
    }
}
//
extension Character {
    var sympyToKey: Key? {
        switch self {
        case "(": return .openBracket
        case ")": return .closeBracket
        case "/": return .fraction
        case "*": return .times
        case "+": return .plus
        case "-","−": return .minus
        case "^": return .pow
        case "√": return .sqrt
        case "E": return .euler
        case "π": return .pi
        case "=": return .typedEqual
        case "x": return .x
        case "y": return .y
        case "z": return .z
        case "I": return .imaginary
        case "∞": return .infinity
        case "0": return .zero
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case ".": return .dot
        case ",": return .comma
        case " ": return .space
        case "°": return .degree
        case "′": return .prime
        case "″": return .doublePrime
        case "‴": return .triplePrime
        case "∑": return .sum
        case "∏": return .prod
        default: return nil
        }
    }
}
