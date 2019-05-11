//
//  Words.swift
//  WordSearchShopify
//
//  Created by Rushil on 2019-05-08.
//  Copyright © 2019 Rushil. All rights reserved.
//

import Foundation

enum RowColumn {
    case row
    case column
    case none
}

class Game {
    
    let wordList: [String] =
        [
          "Shopify",
          "Swift",
          "Kotlin",
          "ObjectiveC",
          "Variable",
          "Java",
          "Mobile",
          "iOS"
        ]
    
    let bigWords: [String] = ["ObjectiveC","Variable"]
    var words: [Word] = []
    
    var wordsFound = 0
    let count = 8
    var hintsRemaining: Int = 2
    let MAX_ATTEMPTS = 100 //Increase this value if words are missing
    
    var size: Int = 10 // By default size of the matrix is 10
    var results: Array<CrosswordsGenerator.Word> = []
    
    var grid: [[GridBlock]] = []
    var grid1D: [GridBlock] = []
    
    func initializeWords() {
        words = []
        for word in wordList {
            words.append(Word(word: word, status: .notFound))
        }
    }
    
    func populateGrid() {
        initializeWords()
        wordsFound = 0
        hintsRemaining = 2
        
        //Initialize 2D Grid based on size
        grid = Array(repeating: Array(repeating: GridBlock(), count: size), count: size)
        
        // Convert words to upper case
        var words:[String] = wordList.map { Bool.random() ? $0.uppercased() : String($0.uppercased().reversed()) } //Randomize words being placed in reverse or not.
        words.shuffle() //Randomize order of placing words
        
        let cwGen = CrosswordsGenerator(columns: size, rows: size, words: words)
        cwGen.fillAllWords = true
        cwGen.generate()
        while cwGen.result.count != 6 {
            cwGen.generate()
        }
        
        results = cwGen.result
        
        print(results)
        for i in 0...(size-1) {
            for j in 0...(size-1) {
                let char = cwGen.getCell(j+1, row: i+1)
                if char != "-" {
                    grid[i][j] = GridBlock(character: char, status: .notFound)
                } else {
                    grid[i][j] = GridBlock(character: "-", status: .notFound)
                }
            }
        }
        
        placeWords()
        
        //TODO: Fill in remaining characters
        
        for i in 0..<size {
            for j in 0..<size {
                if grid[i][j].character == "-" {
                    grid[i][j].character = randomLetter()
                }
            }
        }
        
        if (results.count != count) {
            print("Developer Warning: SOME OF THE WORDS WERE NOT PLACED IN THE GRID. Consider increasing the MAX_ATTEMPTS threshold.")
        }
        
        updateGrid1D()
    }
    
    func getWordMatrix() -> [[GridBlock]]?{
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
        let uppercaseLetters = (65...90).map {String(UnicodeScalar($0))}
        return uppercaseLetters.randomElement()!
    }
    
    func updateStatusAtIndex(status: gridStatus, index: Int) { //Function to update both grid, and grid1d
        let row = getRowCol(index: index)[0]
        let col = getRowCol(index: index)[1]
        
        if !((status == .selected) && (grid[row][col].status == .found)) {
            grid[row][col].status = status
            grid1D[index].status = status
        }
        
        
    }
    
    func updateStatusBetween(_ status: gridStatus, _ i1: Int, _ i2: Int) {
        var r1: Int = getRowCol(index: i1)[0]
        var c1: Int = getRowCol(index: i1)[1]
        var r2: Int = getRowCol(index: i2)[0]
        var c2: Int = getRowCol(index: i2)[1]
        
        let rowcolumn = sameRowOrColumn(i1,i2)
        switch rowcolumn {
        case .row:
            if (c1 > c2) {
                (c1,c2) = (c2,c1)
            }
            for i in c1...c2 {
                if (grid[r1][i].status != .found) {
                    updateStatusAtIndex(status: status, index: getIndex(row: r1, col: i))
                }
            }
            break
        case .column:
            if (r1 > r2) {
                (r1,r2) = (r2,r1)
            }
            for i in r1...r2 {
                if (grid[i][c1].status != .found) {
                    updateStatusAtIndex(status: status, index: getIndex(row: i, col: c1))
                }
            }
            break
        case .none:
            break
        }
    }
    
    func getRowCol(index: Int)->[Int] {
        let row: Int = (index/size)
        let col: Int = index % size
        return [row,col]
    }
    
    func getIndex(row: Int, col: Int) -> Int {
        return row*size+col
    }
    
    func updateGrid1D(){
        grid1D = []
        for row in grid {
            for gridBlock in row {
                grid1D.append(gridBlock)
            }
        }
    }
    
    func getCharArray() -> [GridBlock]? {
        if grid.count>0 {
            return grid1D
        }
        return nil
    }
    
    func sameRowOrColumn(_ i1: Int, _ i2: Int) -> RowColumn {
        let r1: Int = getRowCol(index: i1)[0]
        let c1: Int = getRowCol(index: i1)[1]
        let r2: Int = getRowCol(index: i2)[0]
        let c2: Int = getRowCol(index: i2)[1]
        if (r1==r2) {
            return .row
        } else if (c1==c2) {
            return .column
        }
        return .none
    }
    
    func getWordBetweenIndexes(_ i1: Int, _ i2: Int ) -> String {
        let r1: Int = getRowCol(index: i1)[0]
        let c1: Int = getRowCol(index: i1)[1]
        let r2: Int = getRowCol(index: i2)[0]
        let c2: Int = getRowCol(index: i2)[1]
        
        var word: String = ""
        let rowcolumn = sameRowOrColumn(i1,i2)
        
        switch rowcolumn {
        case .row:
            if (c2>c1) {
                for i in c1...c2 {
                    word.append(contentsOf: grid[r1][i].character)
                }
                return word
            } else {
                for i in c2...c1 {
                    word.append(contentsOf: grid[r1][i].character)
                }
                return String(word.reversed())
            }
        case .column:
            if (r2>r1) {
                for i in r1...r2 {
                    word.append(contentsOf: grid[i][c1].character)
                }
                return word
            } else {
                for i in r2...r1 {
                    word.append(contentsOf: grid[i][c1].character)
                }
                return String(word.reversed())
            }
        case .none:
            return ""
        }
    }
    
    func foundWord(_ word: String) -> Bool {
        for i in 0..<words.count {
            if wordList[i].uppercased() == word {
                words[i].status = .found
                wordsFound += 1
                return true
            }
        }
        return false
    }
    
    func isColliding(_ size: Int, _ vertical: Bool, _ row: Int, _ col: Int) -> Bool {
        if (vertical) {
            for i in row..<(row+size) {
                if (grid[i][col].character != "-") {
                    return true
                }
            }
        } else {
            for i in col..<(col+size) {
                if (grid[row][i].character != "-") {
                    return true
                }
            }
        }
        return false
    }
    
    func placeWordAt(_ word: String, _ vertical:Bool, _ row: Int, _ col: Int) {
        let characters = Array(word)
        if (vertical) {
            for i in row..<(row+word.count) {
                grid[i][col].character = characters[i-row].uppercased()
            }
        } else {
            for i in col..<(col+word.count) {
                grid[row][i].character = characters[i-col].uppercased()
            }
        }
    }
    
    func placeWords() { // Function to place all the words in the grid
        
        let words = bigWords.map{ Bool.random() ? $0.uppercased() : String($0.uppercased().reversed()) }
        
        for word in words {
            for i in 1...MAX_ATTEMPTS {
                print("Iteration Number: \(i) for \(word)")
                let vertical = Bool.random()
                let position = Int.random(in: 0..<size)
                let start =  Int.random(in: 0..<(size-word.count+1))
                
                let row = vertical ? start : position
                let col = vertical ? position : start
                
                if (!isColliding(word.count, vertical, row, col)) {
                    placeWordAt(word, vertical, row, col)
                    results.append(CrosswordsGenerator.Word(word: word,
                                                            column: (col+1),
                                                            row: (row+1),
                                                            direction: vertical ? .vertical : .horizontal))
                    break
                }
            }
        }
        
    }
    
    func revealWord(_ word: String) {
        var result: CrosswordsGenerator.Word = CrosswordsGenerator.Word()
        for r in results {
            if (r.word == word.uppercased()) || (String(r.word.reversed()) == word.uppercased()) {
                result = r
                wordsFound += 1
                break
            }
        }
        
        if (result.word=="") {
            print("Could not find word to reveal")
            return
        }
        
        let vertical = (result.direction == .vertical)
        let startIndex = getIndex(row: result.row-1, col: result.column-1)
        
        let endRow = vertical ? (result.row + result.word.count - 2) : (result.row - 1)
        let endCol = vertical ? (result.column - 1) : (result.column + result.word.count - 2)
        print(startIndex,endRow,endCol)
        let endIndex = getIndex(row: endRow, col: endCol)
        
        updateStatusBetween(.found, startIndex, endIndex)
    }
    
    func initiateCleanUp() { //Helper functions to clean up all the selected states
        for i in 0..<size {
            for j in 0..<size {
                if (grid[i][j].status == .selected) {
                    grid[i][j].status = .notFound
                }
            }
        }
    }
    
    func countGridsWith(_ status: gridStatus) -> Int { //Helper function to count selected
        var count = 0
        for i in 0..<size {
            for j in 0..<size {
                if (grid[i][j].status == status) {
                    count+=1
                }
            }
        }
        return count
        
    }
    
}
