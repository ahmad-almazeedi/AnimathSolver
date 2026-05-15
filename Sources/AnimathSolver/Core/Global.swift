//
//  Global.swift
//  AnimathSolver
//
//  Minimal shim for the iOS app's Global singleton. The solver itself
//  only depends on `answerReachedStr` and `printSteps`. The other
//  fields exist so the AI/localization helpers in KeyHelpers continue
//  to compile; they are no-ops in the solver context.
//
//  Replace this with your real Global if you embed the package into
//  the original app.
//

import Foundation

enum Global {
    // --- Solver-essential ---
    static let answerReachedStr = "Answer Reached"
    static var printSteps = false

    // --- App-only sentinel values (keep KeyHelpers compiling) ---
    static let titlePromptDiv = "\u{0001}TITLE_PROMPT_DIV\u{0001}"
    static let qsDiv          = "\u{0001}QS_DIV\u{0001}"
    static let cloudDataDiv   = "\u{0001}CLOUD_DATA_DIV\u{0001}"
    static let excludedFromAddingQ: [String] = []
    static let thickChevron: (left: String, right: String) = ("", "")

    static var getLanguage: Language { Language() }
    static func getLanguage(langCodePref: String) -> Language { Language() }
    static func getLanguage(langCodePref: String?) -> Language { Language() }
}

struct Language {
    var isArabic: Bool = false
    var replyInStr: String = ""
}
