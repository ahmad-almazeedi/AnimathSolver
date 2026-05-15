//
//  StepModelVarsForView.swift
//  Hulul
//
//  Created by Ahmad on 22/12/2022.
//  Copyright © 2022 Ahmad. All rights reserved.
//

import Foundation

extension Array where Element == StepModel {
    
    //
    func currentStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let firstIdx = stepIdxs.first, firstIdx >= 0 {
            let allStepsFlat = self
            if firstIdx < allStepsFlat.count {
                return allStepsFlat[firstIdx]
            }
        }
        return StepModel()
    }
    
    //
    func nextLiveStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let firstIdx = stepIdxs.first, firstIdx >= 0 {
            let allStepsFlat = self
            if firstIdx < allStepsFlat.count - 1 {
                return allStepsFlat[firstIdx + 1]
            }
        }
        return StepModel()
    }
    
    func realPrevLiveStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let firstIdx = stepIdxs.first, firstIdx > 0 && firstIdx < count - 1 {
            return self[firstIdx-1]
        }
        return StepModel()
    }
}

extension Array where Element == StepModel {
    
    //
    func currentParentStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let currentIdx = stepIdxs.first, currentIdx >= 0 {
            let currentStep = allStepsFlat[currentIdx]
            if let currentParentStep = first(where: { $0.splittedSteps?.flatForSplittedSteps.contains(where: { $0.id == currentStep.id }) ?? false }) {
                return currentParentStep
            } else {
                return first(where: { $0.id == currentStep.id }) ?? StepModel()
            }
        }
        return StepModel()
    }
  
    //
    func prevParentStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let firsIdx = stepIdxs.first, firsIdx > 0 {
            let prevStep = allStepsFlat[firsIdx-1]
            if let prevParentStep = first(where: {$0.splittedSteps?.flatForSplittedSteps.contains(where: {$0.id == prevStep.id}) ?? false}) {
                return prevParentStep
            } else if contains(where: {$0.id == prevStep.id}) {
                return prevStep
            }
        }
        return StepModel()
    }
    
    //
    func beforePrevParentStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let firsIdx = stepIdxs.first, firsIdx > 1 {
            let beforePrevStep = allStepsFlat[firsIdx-2]
            if let beforePrevParentStep = first(where: {$0.splittedSteps?.flatForSplittedSteps.contains(where: {$0.id == beforePrevStep.id}) ?? false}) {
                return beforePrevParentStep
            } else if contains(where: {$0.id == beforePrevStep.id}) {
                return beforePrevStep
            }
        }
        return StepModel()
    }
}

extension Array where Element == StepModel {
    func currentMoreStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let firstIdx = stepIdxs.first, firstIdx >= 0 && firstIdx < allStepsFlat.count {
            let prevStep = allStepsFlat[firstIdx]
            return prevStep.subSteps.isEmpty ? StepModel() : prevStep.subSteps[stepIdxs.last!]
        }
        return StepModel()
    }
    func explainHowNextLiveStep(_ stepIdxs: [Int]) -> StepModel {
        if !isEmpty, let firstIdx = stepIdxs.first, firstIdx >= 0 {
            let prevStep = allStepsFlat[firstIdx]
            if let explainHowStepIdx = stepIdxs.last {
                return prevStep.subSteps.count < 2 || explainHowStepIdx >= prevStep.subSteps.count-1 ? StepModel() : prevStep.subSteps[explainHowStepIdx+1]
            }
        }
        return StepModel()
    }
    func stepLevel(_ stepIdxs: [Int]) -> [StepModel] {
        stepIdxs.count > 1 ? currentStep(stepIdxs).subSteps : allStepsFlat
    }
    var allStepsFlat: [StepModel] {
        var tmpAllStepsFlat = [StepModel]()
        for step in self {
            if step.markedKeys.isEmpty, let splittedSteps = step.splittedSteps {
                let isLast = step.id == last!.id
                tmpAllStepsFlat.append(contentsOf: splittedSteps.flatForSplittedSteps.dropLast(!isLast))
            } else {
                tmpAllStepsFlat.append(step)
            }
        }
        return tmpAllStepsFlat
    }
    func str(includeNote: Bool = false) -> String {
        Array<Int>(0..<allStepsFlat.count).filter({!($0 == 0 && currentStep([$0]).nextIsEmpty)}).map({currentStep([$0]).str(includeNote: includeNote)}).joined(separator: "\n")
    }
    var hasSolutionStep: Bool {
        count > 1 && !last!.prevExprs.isEmptyOrNodesEmpty && last!.nextExprs.isEmptyOrNodesEmpty
    }
}

extension StepModel {
    func str(includeNote: Bool = false) -> String {
        var arrowAndNext = ""
        if !nextExprs.isEmptyOrNodesEmpty {
            arrowAndNext = " → \(nextExprs.latexOrAIStr)"
        }
        return prevExprs.latexOrAIStr + " → " + "\"\(explanation)\(includeNote && !note.isEmpty ? " (\(note))" : "")\"" + arrowAndNext
    }
}
