//
//  Words.swift
//  WordSearchShopify
//
//  Created by Rushil on 2019-05-08.
//  Copyright © 2019 Rushil. All rights reserved.
//

import Foundation

class Game {
    let wordList =
        [
          "Shopify",
          "Swift",
          "Kotlin",
          "ObjectiveC",
          "Variable",
          "Java",
          "Mobile"
        ]
    let count = 7
    
    var size: Int = 10 // By default size of the matrix is 10
    var results: Array<CrosswordsGenerator.Word> = []
    
    var grid: [[String]] = []
    
    func populateGrid() {
        //Initialize 2D Grid based on size
        grid = Array(repeating: Array(repeating: "", count: size), count: size)
        
        let cwGen = CrosswordsGenerator(columns: size, rows: size, words: wordList)
        cwGen.fillAllWords = true
        cwGen.generate()
        
        results = cwGen.result
        
        for i in 0...(size-1) {
            for j in 0...(size-1) {
                let char = cwGen.getCell(j, row: i)
                if char=="-" {
                    grid[i][j] = randomLetter()
                } else {
                    grid[i][j] = char
                }
                
            }
        }

        print("Grid = \(grid)")
    }
    
    func getWordMatrix() -> [[String]]?{
        if grid.count>0 {
            return grid
        }
        return nil
    }
    
    func getResults() -> [CrosswordsGenerator.Word]? {
        if results.count > 0 {
            return results
        }
        return nil
    }
    
    func randomLetter() -> String {
        let uppercaseLetters = (97...122).map {String(UnicodeScalar($0))}
        return uppercaseLetters.randomElement()!
    }
    
}
