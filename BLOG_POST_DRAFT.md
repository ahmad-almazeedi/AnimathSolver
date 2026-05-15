# How I built a step-by-step algebra solver — and the four ideas that made it work

*Draft. Adjust voice and length to your preferred outlet (HN front-page essays read ~1,500 words; dev.to walkthroughs ~2,500; personal blog can be longer). Replace `[GH:filename.swift#Lxxx]` placeholders with permalinks to the GitHub repo before publishing.*

---

Three years ago I shipped [Animath](https://apps.apple.com/app/animath/), an iOS app that does what Photomath and Symbolab do: you type in an algebra problem and it walks you through the solution one step at a time, with animations showing exactly which symbol became which. Every step has a natural-language explanation: "Subtract 3 from both sides," "Distribute the multiplier," "Take the square root of both sides."

I spent over a year writing the solver. Today I'm open-sourcing it under Apache 2.0: [github.com/ahmad-almazeedi/AnimathSolver](https://github.com/ahmad-almazeedi/AnimathSolver).

The code is fine. The code is not the point. The point is **four design ideas** that took me longer to figure out than I want to admit, that aren't obvious from reading existing CAS systems, and that I think will save someone else a year of false starts if they're building anything in this space.

## The problem, made specific

Most computer algebra systems — SymPy, Mathematica, Maple, Math.js — are built to compute *answers*. They take an expression, transform it, and give you back a different expression. That's not what a tutoring app needs. A tutoring app needs **the path**, not the destination.

Concretely, given `2x + 3 = 11`, a CAS will return `x = 4`. But you want to render:

```
Step 1: 2x + 3 = 11      "Subtract 3 from both sides"
Step 2: 2x = 8           "Divide both sides by 2"
Step 3: x = 4            "Answer reached"
```

…and, harder, you want to *animate* the transitions. The `3` on the left side and the `3` on the right side that appeared in step 2 are the same conceptual `3` — the user should see it move. The `2` that was a coefficient and the `2` that becomes the divisor in step 3 are the same `2`. The `11` and the `8` are related: `11 - 3 = 8`. All of this needs to be visible to the renderer.

This is the part nobody talks about. The four ideas below are what make it work.

## Idea 1: Tokens carry stable identity

Most CAS systems represent `2x + 3` as a tree like `Add(Mul(2, x), 3)`. The leaves are values; there's no notion of "which 2 are we talking about."

Animath's representation is a tree, too, but each leaf is a `StepKey` — a token that pairs a `Key` (what it is — a digit, an operator, a variable) with a stable `Int32` ID (which specific instance):

```swift
struct StepKey: Equatable, Hashable {
    var id: Int32        // ← stable across transformations
    var key: Key         // ← .two, .plus, .x, .typedEqual, ...
    var repCount = 0
}
```

When a transformation moves a token to a new position in the tree, the ID stays. When a renderer compares step N to step N+1, it can match tokens by ID — *"this 2 in step 1 is the same 2 in step 2, it just lives somewhere else now"* — and animate them along the right vector.

The pattern is straightforward once you see it, but it's load-bearing for everything else. It's also surprisingly easy to get wrong: every transformation has to be careful never to *recreate* a token when it could *reuse* one. Half of the bugs I fixed in year one were "this step inexplicably has a fade-in and fade-out instead of a slide." Diagnosis was always the same: a transform threw away a token's ID when it shouldn't have.

→ [`Core/Key/StepKey.swift`](https://github.com/ahmad-almazeedi/AnimathSolver/blob/main/Sources/AnimathSolver/Core/Key/StepKey.swift)

## Idea 2: Clones and merges as first-class metadata

ID-preservation handles "this token moved." But two cases break it:

- **Distribution:** `a(b + c) → ab + ac`. There's one `a` on the left and two `a`s on the right. The renderer needs to draw two copies sliding out of one.
- **Collection:** `2x + 3x → 5x`. There were two coefficient slots, now there's one. The renderer needs to draw both originals merging into the result.

You can't solve these with IDs alone. You need to record the relationship: *this set of new IDs are clones of that original ID; this single new ID is the merge of those original IDs.*

Each step in Animath carries two arrays:

```swift
var cloneIDs: [(originalKeyID: Int32, cloneMergeID: Int32)]
var mergeIDs: [(originalKeyID: Int32, cloneMergeID: Int32)]
```

…populated by the transform that did the distribution or collection. The renderer reads these, draws a one-to-many or many-to-one animation, and the user sees `a(b+c)` smoothly become `ab + ac` with two copies of `a` clearly visible.

In the codebase, you'll see `appendCloneIDs(...)` and `appendMergeIDs(...)` calls peppered through every distribution-or-collection transform. They look like bookkeeping. They are the entire reason the animations work.

→ [`Core/StepModel.swift`](https://github.com/ahmad-almazeedi/AnimathSolver/blob/main/Sources/AnimathSolver/Core/StepModel.swift#L19), [`Solver/Functions/Brackets/DistributeMultiplier.swift`](https://github.com/ahmad-almazeedi/AnimathSolver/blob/main/Sources/AnimathSolver/Solver/Functions/Brackets/DistributeMultiplier.swift)

## Idea 3: Explanations are co-located with transforms, not reverse-engineered

There's a popular wrong way to generate step-by-step explanations: take a CAS, compute the final answer, then ask an LLM to "show your work." This produces plausible-sounding nonsense. The LLM doesn't know what the CAS actually did internally; it invents a reasonable-looking sequence of steps that happen to start at the input and end at the answer.

Animath's solver writes each explanation *as* the transform makes the change:

```swift
func evaluateAddition(node: StepNode, fnCtrl: [FnCtrl], _ steps: inout [StepModel]) {
    // ... guards and setup ...

    steps.lastMarked = termNodes.opValuesSK(.onlyPlusOrMinus)
    steps.lastExplanation = termNodes.hasTerm
        ? "Collect like terms"
        : additionExplanation(keys: termNodes.flatSKsNoTerms(.dropPlus).keys)

    // ... do the actual addition ...

    appendStep(&steps, fnCtrl: fnCtrl)
}
```

The transform that does "add these numbers" is the same transform that writes "Add the numbers" (or "Calculate the sum" or "Subtract the numbers" depending on the signs). The explanation is **always faithful to what the code did** because it's written by the code that did it.

This pattern has downsides — every transform becomes a mixed math/UX file, and string changes require a code deploy — but it's the only architecture I know of that produces explanations that don't lie. If you're building math tutoring software with LLM-generated explanations, this is the failure mode you should be most paranoid about.

→ [`Solver/Functions/EvaluateDefault/EvaluateAddition.swift`](https://github.com/ahmad-almazeedi/AnimathSolver/blob/main/Sources/AnimathSolver/Solver/Functions/EvaluateDefault/EvaluateAddition.swift)

## Idea 4: Fixed-point convergence via tree-diff

How does the solver decide when it's done? Naively, you'd have each transform return a "did I change anything?" boolean and loop until they all return false. That works for trivial cases and breaks the moment two transforms interact — one might un-do what another just did, the loop oscillates, and the solver hangs.

Animath uses a different mechanism: **pin and diff**.

```swift
repeat {
    nodeL.pinRootExpr()      // serialize the current tree to a flat token list
    nodeR.pinRootExpr()
    surfAndEvaluateBothSides(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
    iterationEngine(nodeL: nodeL, nodeR: nodeR, fnCtrl: fnCtrl, &steps)
} while !nodeL.forceStop && (nodeL.pinnedRootDidChange || nodeR.pinnedRootDidChange)
```

`pinRootExpr()` snapshots a flat-token serialization of the tree. After running an entire engine pass, `pinnedRootDidChange` compares the serialization to the current tree. If they differ, something changed somewhere — loop again. If not, we're done.

The advantage: individual transforms don't need to track or report whether they changed anything. They just do their work. The convergence check is one level above, comparing whole-tree snapshots. This makes adding new transforms much safer — you can't forget to flag a change because there's no flag.

The disadvantage: serializing the tree is O(n) per pass. For Animath's expression sizes (rarely more than 50 tokens), this is fine.

The same pattern shows up three times in the code, nested:

- **Inner loop:** `iterationEngine` (cheap cleanups — remove zeros, cancel equal terms)
- **Middle loop:** `surfAndEvaluateAndApplyFnTillEnd` (the main simplification work)
- **Outer loop:** `surfAndEvaluateAndApplyFnAndSolveEqTillEnd` (includes equation moves)

Each loop runs until its pinned-diff is unchanged, then the layer above checks *its* pinned-diff, and so on. The result is a clean nested fixed-point computation that handles surprisingly complex algebraic strategy without needing an explicit search procedure.

→ [`Solver/SolverMain/SolverMain.swift`](https://github.com/ahmad-almazeedi/AnimathSolver/blob/main/Sources/AnimathSolver/Solver/SolverMain/SolverMain.swift), [`Solver/Surfs/SurfAndEvaluate.swift`](https://github.com/ahmad-almazeedi/AnimathSolver/blob/main/Sources/AnimathSolver/Solver/Surfs/SurfAndEvaluate.swift)

## Bonus idea: Speculative "allowed" checks

One more pattern worth mentioning. The solver often needs to decide between competing strategies: should it distribute the multiplier, or factor the polynomial? Should it divide both sides, or multiply by the LCM?

The answer is usually "it depends on what the *other* strategy would produce." So Animath does this:

```swift
func divideBothSidesAllowed(nodeL: StepNode, nodeR: StepNode, fnCtrl: [FnCtrl]) -> Bool {
    let nodeLClone = nodeL.clone(changeID: false, withParent: true)
    let nodeRClone = nodeR.clone(changeID: false, withParent: true)
    nodeLClone.pinRootExpr()
    var tmpSteps = [StepModel()]
    // ...
    divideBothSides(nodeL: nodeLClone, nodeR: nodeRClone,
                    fnCtrl: fnCtrl + [.skipPrintStep, .checkAllowed],
                    &tmpSteps)
    return nodeLClone.pinnedRootDidChange
}
```

Clone the tree, run the candidate transform on the clone, ask the pinned-diff "did anything actually happen?" — if yes, the transform is "allowed" and we should pick it. If no, try the next one.

It's not elegant. It's not fast. It's honest about the fact that algebraic strategy is contextual, and it makes the dispatcher code straightforward.

→ [`Solver/Functions/EquationFns/DivideBothSides/DivideBothSidesMain.swift`](https://github.com/ahmad-almazeedi/AnimathSolver/blob/main/Sources/AnimathSolver/Solver/Functions/EquationFns/DivideBothSides/DivideBothSidesMain.swift)

## Things I would do differently

The architecture above is what I'd keep. The implementation has known smells I'd fix in a do-over:

- **The flag bag** (`FnCtrl`) has ~80 cases. Whenever I hit a new corner case, I added a flag. The combinations are unreasonable. A do-over would use three explicit strategy modes (`Simplify`, `Solve`, `Probe`) and have transforms opt in via metadata.
- **`StepNode` is a 3,900-line god class.** It mixes math, animation metadata, equation linkage, and traversal state. A do-over would separate a pure-math `Expr` from a render-aware wrapper.
- **`fatalError()` as a runtime check.** This crashes on weird user input. A do-over would return `nil` and gracefully fall back to "unable to solve."

But — and this is the part I most want to emphasize — **none of these refactors are why the thing works.** What makes it work is the four ideas above. A clean architecture with the wrong ideas would still produce broken explanations and janky animations. A messy architecture with the right ideas ships a real product.

If you're building tutoring software, copy the ideas. The code is there as evidence and reference — see [`github.com/ahmad-almazeedi/AnimathSolver`](https://github.com/ahmad-almazeedi/AnimathSolver) — but the ideas travel further.

## License & attribution

The code is Apache 2.0. If you build something on top of it, I'd love to hear about it. If you don't, that's fine too.

---

*[footer: bio, links, comments]*
