//
//  SmokeTest.swift
//  AnimathSolverTests
//
//  This package's symbols are `internal` to keep the diff against the
//  original Animath app minimal. Real tests would require either
//  adding `@testable import AnimathSolver` (works because tests live
//  in the same module by default in SPM) plus making the public API
//  surface explicit, or forking the package.
//
//  For now this is a placeholder to keep `swift test` happy.
//

import XCTest

final class SmokeTest: XCTestCase {
    func testPackageBuilds() {
        XCTAssertTrue(true, "If this test runs, the package compiled.")
    }
}
