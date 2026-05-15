//
//  PrintNodes.swift
//  Hulul
//
//  Created by Ahmad on 07/04/2021.
//  Copyright © 2021 Ahmad. All rights reserved.
//

extension CalcBrain {
    func printExpression(keys: [Key]) {
        var i = 0
        while i < keys.count {
            if keys[i] == .sqrt {
                print(keys[i+1].powTitle!, terminator: "")
                print(keys[i].title, terminator: "")
                i += 2
            } else {
                print(keys[i].title, terminator: "")
                i += 1
            }
        }
    }
    func printExprLB(keys: [Key]) {
        var i = 0
        while i < keys.count {
            if keys[i] == .sqrt {
                print(keys[i+1].powTitle!, terminator: "")
                print(keys[i].title, terminator: "")
                i += 2
            } else {
                print(keys[i].title, terminator: "")
                i += 1
            }
        }
        print("")
    }
}
