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

enum ResultsDirection {
    case vertical
    case horizontal
}

struct WordResults {
    public var word = ""
    public var column = 0
    public var row = 0
    public var direction: ResultsDirection = .vertical
}

class GameManager {
    
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

    var words: [Word] = []
    
    var wordsFound = 0
    let count = 8
    let REVEALS = 8
    var revealsRemaining: Int = 8
    let MAX_ATTEMPTS = 200 //Increase this value if words are missing
    
    var size: Int = 10 // By default size of the matrix is 10
    var results: Array<WordResults> = []
    
    var grid: [[GridBlock]] = []
    var grid1D: [GridBlock] = []
    
    func initializeWords() {
        words = []
        for word in wordList {
            words.append(Word(word: word, status: .notFound))
        }
    }
    
    func populateGrid() {
        //Initialize Parameters
        initializeWords()
        wordsFound = 0
        revealsRemaining = REVEALS
        results = []
        
        //Initialize 2D Grid based on size
        grid = Array(repeating: Array(repeating: GridBlock(), count: size), count: size)

        for i in 0..<size {
            for j in 0..<size {
                    grid[i][j] = GridBlock(character: "-", status: .notFound)
            }
        }
        placeWords()
        printGrid()
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
        
        while (foundTwoWordsInSameGrid() == true) {
            print("Developer Warning: Repopulating Grid due to duplicate words in Grid.")
            populateGrid()
        }
    }
    
    func getWordMatrix() -> [[GridBlock]]?{
        if grid.count>0 {
            return grid
        }
        return nil
    }
    
    func getResults() -> [WordResults]? {
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
        
        if (grid[row][col].status != .found) { //Necessary check to never override found grids.
            grid[row][col].status = status
            grid1D[index].status = status
        }
        
        
    }
    
    func updateStatusBetween(_ status: gridStatus, _ start: Int, _ end: Int) {
        
        let endI = (start>end) ? start : end
        let startI = (start>end) ? end : start
        
        if abs(start-end) < 10 { //Same Row
            for i in startI...endI {
                updateStatusAtIndex(status: status, index: i)
            }
        } else {
            let startRow = getRowCol(index: startI)[0]
            let endRow = getRowCol(index: endI)[0]
            let col = getRowCol(index: startI)[1]
            for i in startRow...endRow {
                updateStatusAtIndex(status: status, index: getIndex(row: i, col: col))
            }
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
    
    func isColliding(_ word: String, _ vertical: Bool, _ row: Int, _ col: Int) -> Bool {
        let size = word.count
        let chars = Array(word)
        
        if (vertical) {
            for i in row..<(row+size) {
                if (grid[i][col].character != "-") {
                    
                    if (grid[i][col].character == String(chars[i-row])) {
                        print("Overlap Found!: at \(chars[i-row]), for word \(word)")
                    } else {
                        print("Collision: Word = \(word) : With Letter = \(grid[i][col].character)")
                        return true
                    }
                }
            }
        } else {
            for i in col..<(col+size) {
                if (grid[row][i].character != "-") {
                    
                    if (grid[row][i].character == String(chars[i-col])) {
                        print("Overlap Found! at \(chars[i-col]), for word \(word)")
                    } else {
                        print("Collision: Word = \(word) : With Letter = \(grid[row][i].character)")
                        return true
                    }
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
        
        let words = wordList.map{ Bool.random() ? $0.uppercased() : String($0.uppercased().reversed()) }
        for word in words {
            for i in 1...MAX_ATTEMPTS {
                print("Iteration Number: \(i) for \(word)")
                let vertical = Bool.random()
                let position = Int.random(in: 0..<size)
                let start =  Int.random(in: 0..<(size-word.count+1))
                
                let row = vertical ? start : position
                let col = vertical ? position : start
                
                if (!isColliding(word, vertical, row, col)) {
                    placeWordAt(word, vertical, row, col)
                    results.append(WordResults(word: word,
                                               column: col,
                                               row: row,
                                               direction: vertical ? .vertical : .horizontal))
                    break
                }
            }
        }
        
    }
    
    func revealWord(_ word: String) -> [Int]? {
        var result: WordResults = WordResults()
        for r in results {
            if (r.word == word.uppercased()) || (String(r.word.reversed()) == word.uppercased()) {
                result = r
                wordsFound += 1
                break
            }
        }
        
        if (result.word=="") {
            print("Could not find word to reveal")
            return nil
        }
        
        let vertical = (result.direction == .vertical)
        let startIndex = getIndex(row: result.row, col: result.column)
        
        let endRow = vertical ? (result.row + result.word.count - 1) : (result.row)
        let endCol = vertical ? (result.column) : (result.column + result.word.count - 1)
        print(startIndex,endRow,endCol)
        let endIndex = getIndex(row: endRow, col: endCol)
        return [startIndex, endIndex]
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
    
    func printGrid() {
        print("--------- GRID ---------")
        for i in 0..<size {
            var row = ""
            for j in 0..<size {
                row += grid[i][j].character
            }
            print("Row \(i) - \(row)")
        }
        print("------------------------")
    }
    
    // Edge Case: There is a chance that the random letters in the grid could align to form a duplicate of one
    // of the words in the word list, and this function is a helper function to handle that.
    // However: the chance of this happening is really low, 0.005 % [ (1/26)^3 ] for a 3 - lettered word like iOS
    func foundTwoWordsInSameGrid() -> Bool {
        var wordCount: [Int] = Array(repeating: 0, count: count)
        
        for i in 0..<size {
            var row = ""
            var column = ""
            for j in 0..<size {
                row += grid[i][j].character
                column += grid[j][i].character
            }
            for k in 0..<count {
                let word = wordList[k].uppercased()
                if row.contains(word) {
                    wordCount[k] += 1
                    if (wordCount[k]>1) {
                        print("Developer Warning: Found Duplicate \(word) in Row: \(i) - \(row)")
                    }
                }
                if row.contains(String(word.reversed())) {
                    wordCount[k] += 1
                    if (wordCount[k]>1) {
                        print("Developer Warning: Found Duplicate \(word) in Row: \(i) - \(row)")
                    }
                }
                if column.contains(word) {
                    wordCount[k] += 1
                    if (wordCount[k]>1) {
                        print("Developer Warning: Found Duplicate \(word) in Column: \(i) - \(column)")
                    }
                }
                if column.contains(String(word.reversed())) {
                    wordCount[k] += 1
                    if (wordCount[k]>1) {
                        print("Developer Warning: Found Duplicate \(word) in Column: \(i) - \(column)")
                    }
                }
            }
        }
        
        var found = false
        
        for i in 0..<count {
            if wordCount[i] != 1 {
                print("Developer Warning: Found \(wordCount[i]) instances of Word = \(wordList[i])")
                found = true
            }
        }
        
        return found
        
    }
    
}
