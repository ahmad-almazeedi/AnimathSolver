# AnimathSolver

A symbolic algebra solver that produces **step-by-step solutions with natural-language explanations**, extracted from the [Animath iOS app](https://apps.apple.com/us/app/animath-ai-tutor-solver/id1615638274) and released under Apache 2.0.

The algorithm has shipped in production for three years across iOS App Store users. The code is the real thing, warts and all, not a from-scratch clean-room rewrite.

→ Get the app: [Animath on the App Store](https://apps.apple.com/us/app/animath-ai-tutor-solver/id1615638274)

## What it does

Given an equation like `2x² + 5x - 3 = 0`, the solver produces an ordered list of steps:

1. *"Identify the coefficients a, b and c of the quadratic equation"* → `a = 2, b = 5, c = -3`
2. *"Substitute into the quadratic formula"* → `x = (-5 ± √(25 + 24)) / 4`
3. *"Calculate the expression under the radical"* → `x = (-5 ± √49) / 4`
4. *"Take the square root"* → `x = (-5 ± 7) / 4`
5. *"Separate into two cases"* → `x = ½` or `x = -3`

Each step is a full `(prevExpr, explanation, nextExpr)` triple, with token-level identity preserved across transformations so a UI layer can animate which symbol became which.

## Why this exists

I built this between 2019 and 2025 for the [Animath iOS app](https://apps.apple.com/us/app/animath-ai-tutor-solver/id1615638274). It's the kind of thing that's commercially valuable, but I've gotten what I needed out of the app and would rather it live in the open than rot on a disk. The patterns inside (animation-aware token identity, co-located explanations, fixed-point + diff loops) are non-obvious and took a long time to figure out; if they help one other developer building math tutoring software, that's the goal.

## Status

**Not actively maintained.** This is an artifact, not a project. I'm releasing it as a reference and a starting point. Pull requests are welcome but I make no commitment to review or merge them.

The code has known issues that I'm aware of and don't intend to fix here:

- ~80 flags in `FnCtrl`: the "every corner case became a new flag" smell
- `StepNode` is a ~3,900-line class that has accumulated too many responsibilities
- `fatalError()` is used as a runtime check in many places (would crash on user input in production; the original app catches these at a higher layer)
- Some duplicate code across variants (`distributePrevMult` / `distributeNextMult`, `simplifyPoweredRoot` / `simplifyNonPoweredRoot`, etc.)

These are real architectural smells. They are also the reason the thing actually works on real student input across three years. A clean rewrite would re-discover the same edge cases one bug report at a time. Caveat emptor.

## Building

```bash
swift build
```

Works on Swift 5.9+ for iOS 15+ and macOS 12+. Pure Swift, no external dependencies.

## Symbol visibility

For minimum diff against the original code, **all symbols are `internal`**. The package compiles cleanly but cannot be used as a `swift package add` dependency without modification. To consume it as a library, fork and add `public` modifiers to:

- `CalcBrain` and `CalcBrain.solveForX(nodeL:nodeR:fnCtrl:shouldCheckEquality:)`
- `StepNode`, `StepKey`, `Key`, `StepModel`, `Expression`, `ResultCase`
- Probably 30-50 method/property declarations in those types

For reading and learning, no modification needed.

## Architecture in one paragraph

The solver represents math as a tree (`StepNode`) of tokens (`StepKey`). Each token carries a stable `Int32` ID that survives transformations; this is what enables UI animation of "the 2 moved from one side to the other." A top-level orchestrator (`CalcBrain.solveForX`) runs concentric fixed-point loops: an `iterationEngine` for cheap cleanups, a `coreEngine` of ~25 ordered transform passes, and an `EquationEngine` for both-sides operations. Each transform reads the tree, mutates it, and writes a natural-language explanation co-located with the change. The whole thing is wrapped in a "pin / check did-it-change" idiom that drives the outer convergence loop.

## Source layout

```
Sources/AnimathSolver/
├── Core/                  ← Data model
│   ├── StepNode/          ← AST (StepNode, StepLevel), the math tree
│   ├── Key/               ← Tokens (Key, StepKey) and rendering metadata
│   ├── Expression.swift   ← An (LHS, RHS) pair
│   ├── StepModel.swift    ← A single step in the solution
│   ├── ResultCase.swift   ← Solved / Unable / Undefined / etc.
│   ├── OtherModels.swift  ← FnCtrl flag bag + Int/Double/Array helpers
│   └── Global.swift       ← Minimal config shim
│
└── Solver/                ← Algorithm
    ├── SolverMain/        ← solveForX orchestrator + AppendStep
    ├── Engines/           ← coreEngine, iterationEngine, EquationEngine
    ├── Surfs/             ← Tree traversal (surfAndApplyFn, surfAndEvaluate)
    ├── CalcBrain/         ← Tokenize / build / execute (pure-numeric eval)
    └── Functions/         ← The actual transforms
        ├── Brackets/        ← Distribute, conjugate, etc.
        ├── CancelAndRemove/ ← Cancel opposite/equal terms
        ├── CommonFactor/    ← Extract GCD, factor polynomials, RRT
        ├── EquationFns/     ← Both-sides ops + quadratic formula
        ├── EvaluateDefault/ ← Add, multiply, exponent
        ├── Fractions/       ← Add, multiply, simplify, decimal↔fraction
        ├── Reduce/          ← Simplify equal bases, divisible terms
        ├── Sqrt/            ← Radical handling
        └── ...
```

## What's NOT in this package

This is the **solver only**. Not included from the original app:

- SwiftUI views and the per-step animation renderer (Views/, Steps/StepsViews/)
- LaTeX preview rendering pipeline
- OCR pipeline for camera input
- AI integrations (OpenAI WebRTC tutor, AI step explanations)
- Cloud sync, RevenueCat, analytics
- Keypad / input UI
- Localization (Arabic, Indonesian, etc.)

If you want to see how the animation layer consumes the solver's output, the iOS app's `Views/` and `Steps/StepsViews/` directories are where that logic lives. They're not open-sourced here, but the design ideas are in the blog post (link below).

## Reading order

If you're trying to understand the architecture, read in this order:

1. `Core/StepNode/StepNode.swift`: the AST (it's a lot; skim for the `init`s and the main computed properties).
2. `Core/Key/StepKey.swift`: see how tokens carry stable IDs.
3. `Solver/SolverMain/SolverMain.swift`: the top-level entry point.
4. `Solver/Engines/CoreEngine.swift`: the ordered list of transforms.
5. `Solver/Functions/EvaluateDefault/EvaluateAddition.swift`: a representative transform with explanation generation and substep tracking.
6. `Solver/Functions/EquationFns/SolveNonLinearEq/QuadraticFormula.swift`: see how a complex multi-step procedure is composed.
7. `Solver/SolverMain/AppendStep.swift`: how steps are recorded and animation IDs propagated.

## License

Apache 2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

## Acknowledgment

If you build something on top of this or learn something from it, I'd love to hear about it, but you don't owe me anything. That's the point of open source.
