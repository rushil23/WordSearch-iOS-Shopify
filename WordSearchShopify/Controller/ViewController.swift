//
//  ViewController.swift
//  WordSearchShopify
//
//  Created by Rushil on 2019-05-07.
//  Copyright © 2019 Rushil. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //MARK: Parameters & Variables
    //ColorScheme:
    let darkRed = UIColor(rgb: 0xb71c1c)
    let crimsonRed = UIColor(rgb: 0xd50000)
    let mediumRed = UIColor(rgb: 0xf44336)
    let lightRed = UIColor(rgb: 0xffcdd2)
    let selectedRed = UIColor(rgb: 0xef5350)
    // Random Colors for animations when the User wins
    let partyColors: [UIColor] = [.green, .blue, .red, .yellow, .magenta , .purple]
    
    //UI Outlets
    @IBOutlet weak var gridView: UICollectionView!
    @IBOutlet weak var wordsView: UICollectionView!
    @IBOutlet weak var revealsRemainingLabel: UILabel!
    @IBOutlet weak var wordsFound: UILabel!
    @IBOutlet weak var wordSearchLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var safeArea: UIView!
    
    // Game Parameters - Will reset after every game / button click
    let game = GameManager()
    var userHasWon: Bool = false
    var startIndex: Int = -1 // For Two - Tap
    var endIndex: Int = -1
    var currIndex: Int = -1 // For swipe
    var gridCount: Int = 0 // To handle swipe edge cases
    
    let animationDuration = 0.4 //For grid & words
    
    //MARK: Initial Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
        
        //SetupGrid
        gridView.layer.cornerRadius = 10
        gridView.clipsToBounds = true
        
        //Setup game
        initializeGame()
    }
    
    //MARK: Reset Button
    @IBAction func resetLevel(_ sender: Any) {
        initializeGame()
    }
    
    func initializeGame() { //Helper function to restart game
        game.populateGrid()
        userHasWon = false
        startIndex = -1
        endIndex = -1
        currIndex = -1
        gridCount = 0
        revealsRemainingLabel.text = "Reveals: \(game.revealsRemaining)"
        wordsFound.text = "Words Found: \(game.wordsFound)"
        gridView.performBatchUpdates({ //Adds an animated effect
            gridView.reloadSections(IndexSet(integer: 0))
        }, completion: nil)
        wordsView.performBatchUpdates({
            wordsView.reloadSections(IndexSet(integer: 0))
        }, completion: nil)
    }

    //MARK: Collection View - Grid & Words View functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (collectionView==gridView) ? game.size*game.size : game.wordList.count
    }
    
    // Adjust number of rows & columns - by adjusting size of cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // ----- GRID COLLECTION VIEW -----
        if (collectionView == gridView) {
            let size = CGFloat(game.size)
            return CGSize(width: collectionView.bounds.size.width/size,
                          height: collectionView.bounds.size.height/size)
        } // ------ WORDS COLLECTION VIEW ------
        else {
            let cols: CGFloat = 2
            let rows = CGFloat(game.count/2)
            return CGSize(width: collectionView.bounds.size.width/cols,
                          height: collectionView.bounds.size.height/rows)
        }
    }
    
    // Handles Grid & Words UI - updates colors upon different user interactions
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // ----- GRID COLLECTION VIEW -----
        if (collectionView == gridView) {
            let grid = gridView.dequeueReusableCell(withReuseIdentifier: "Grid", for: indexPath) as! GridViewCell
            
            let gridBlock = game.getCharArray()![indexPath.item]
            
            grid.character.text = gridBlock.character
            
            switch gridBlock.status {
                case .notFound:
                    grid.backgroundColor = darkRed
                    break
            case .selected: //If user has won: show party colors
                    grid.backgroundColor = userHasWon ? partyColors.randomElement() : selectedRed
                    break
                case .found: // .found & .selected grids use the same color for UI aesthetics
                    grid.backgroundColor = selectedRed
                    break
                }
            
            return grid
        // --- WORDS COLLECTION VIEW ----
        } else {
            let nameCell = wordsView.dequeueReusableCell(withReuseIdentifier: "NameCell", for: indexPath) as! WordsViewCell
            
            let words = game.words
            
            nameCell.name.text = words[indexPath.item].word
            nameCell.name.textColor = mediumRed

            let status = words[indexPath.item].status
            if (status == .found) {
                //Strike out Word
                let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: words[indexPath.item].word)
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
                nameCell.name.attributedText = attributeString
                nameCell.name.font = UIFont.systemFont(ofSize: 22) //Decrease size
            } else {
                nameCell.name.font = UIFont.systemFont(ofSize: 24) //Reset size
            }
            return nameCell
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // ----- GRID COLLECTION VIEW -----
        if (collectionView == gridView) {
            print("Grid Selected = \(indexPath.item)")
            // Handles Two - Tap word selections
            if (startIndex == -1) { // First Tap
                startIndex = indexPath.item
                animateStatusAt(status: .selected, indexPath.item)
            } else if (game.sameRowOrColumn(startIndex, indexPath.item) != .none) { // Second Tap
                endIndex = indexPath.item
                
                animateStatusBetween(status: .selected, startIndex, endIndex)
                checkWord()
                
                startIndex = -1
                endIndex = -1
            } else { // User taps another row/column grid ---> Reset to first tap
                animateStatusAt(status: .notFound, startIndex)
                animateStatusAt(status: .selected, indexPath.item)
                startIndex = indexPath.item
            }
            
            gridView.reloadData()
            
        // ----- WORDS COLLECTION VIEW ------
        } else {
            // Check if the user has any REVEALS remaining to use
            if (game.revealsRemaining > 0 && game.words[indexPath.item].status == .notFound) {
                game.revealsRemaining -= 1
                revealsRemainingLabel.text = "Reveals: \(game.revealsRemaining)"
                let word = game.words[indexPath.item].word
                guard let wordIndexes = game.revealWord(word) else { return }
                animateStatusBetween(status: .found, wordIndexes[0], wordIndexes[1])
                game.words[indexPath.item].status = .found
                
                UIView.animate(withDuration: animationDuration) {
                    self.wordsView.reloadSections(IndexSet(integer: 0))
                }

                gridView.reloadData()
                
                wordsFound.text = "Words Found: \(game.wordsFound)"
                
                if (game.wordsFound == game.count) {
                    //Present WIN Alert
                    presentWinAlert()
                }
            }
        }
    }
    
    
    // MARK: Swipe Gesture Handler
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        guard let index = gridView.indexPathForItem(at: recognizer.location(in: gridView))?.item else { return }
        if currIndex == index && recognizer.state != .ended {
            return
        } else if startIndex == index {
            return
        }
        switch (recognizer.state) {
        case .began:
            
            if (startIndex != -1) { //Disable tapped grid when swipe begins
                animateStatusAt(status: .notFound, startIndex)
            }
            
            startIndex = index
            currIndex = index
            print("BEGAN AT POINT: \(index)")
            gridCount += 1
            animateStatusAt(status: .selected, startIndex)
            break
        case .changed:
            if game.sameRowOrColumn(currIndex, index) == .none
                || game.sameRowOrColumn(startIndex, index) == .none{ //Edge Case: if user swipes out of a row or column, do nothing.
                return
            }
            fillGapsBetween(.selected, currIndex, index) //Edge Case: If user returns back to the same row or column, continue swipe and fill gaps.
            currIndex = index
            print("CHANGED AT POINT: \(index)")
            gridCount += 1
            animateStatusAt(status: .selected, currIndex)
            break
        case .ended:
            if game.sameRowOrColumn(currIndex, index) == .none
                || game.sameRowOrColumn(startIndex, index) == .none{ //Edge Case: If user ends their swipe somewhere else, in another row and column, take the swipe gesture as the last point they were at.
                endIndex = currIndex
            } else {
                endIndex = index
                currIndex = index
                fillGapsBetween(.selected, currIndex, index)
            }
            
            print("ENDED AT POINT: \(endIndex)")
            animateStatusAt(status: .selected, endIndex)
            checkWord()
            break
        default:
            break
        }
        gridView.reloadData()
    }
    
    // MARK: Animation Functions
    func animateStatusAt(status: gridStatus, _ index: Int) {
        if (index<0) { return }
        animateStatusBetween(status: status, index, index)
    }
    
    func animateStatusBetween(status: gridStatus, _ start: Int, _ end: Int) { //Animates the status between indexes.
        if (status == .notFound) {
            print("Unselecting items ! From index: \(start) --> \(end)")
        }
        let endI = (start>end) ? start : end
        let startI = (start>end) ? end : start
        
        if abs(start-end) < 10 { //Same Row
            for i in startI...endI {
                game.updateStatusAtIndex(status: status, index: i)
                UIView.animate(withDuration: animationDuration, animations: {
                    self.gridView.reloadItems(at: [IndexPath(item: i, section: 0)])
                })
            }
        } else {
            let startRow = game.getRowCol(index: startI)[0]
            let endRow = game.getRowCol(index: endI)[0]
            let col = game.getRowCol(index: startI)[1]
            for i in startRow...endRow {
                game.updateStatusAtIndex(status: status, index: game.getIndex(row: i, col: col))
                UIView.animate(withDuration: animationDuration, animations: {
                    self.gridView.reloadItems(at: [IndexPath(item: self.game.getIndex(row: i, col: col), section: 0)])
                })
            }
        }
    }
    
    //MARK: Win Condition Handler
    func presentWinAlert() {
        var curr = -1
        //Display Disco Effect
        let partyColorsTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (t) in
            self.animateStatusAt(status: .notFound, curr)
            curr = Int.random(in: 0..<100)
            self.userHasWon = true
            self.animateStatusAt(status: .selected, curr)
        }
        
        //Show win alert
        let alert = UIAlertController(title: "YOU WON!", message: "Congrats! You found all the words", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Thats Great! :)", style: .default, handler: { action in
            partyColorsTimer.invalidate()
            self.initializeGame()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Word Checker
    func checkWord() {
        let word: String = game.getWordBetweenIndexes(startIndex, endIndex)
        print("Word Selected = \(word)")
        
        if (game.foundWord(word)) {
            game.updateStatusBetween(.found, startIndex, endIndex)
            print("Found word!")
            wordsView.reloadData()
            wordsFound.text = "Words Found: \(game.wordsFound)"
            
            if (game.wordsFound == game.count) {
                //Present WIN Alert
                presentWinAlert()
            }
            
        } else {
            print("Did not find word!")
            animateStatusBetween(status: .notFound, startIndex, endIndex)
        }
            //EdgeCase: If user swipes back, some of the grids would remain selected ---> need to initiate clean up
            if (gridCount != word.count && gridCount>0) {
                print("Cleaning Up Matrix | Grid Count = \(gridCount) for Word = \(word)")
                initiateCleanUp()
        }
        gridCount = 0
        startIndex = -1
        endIndex = -1
        currIndex = -1
    }
    
    //MARK: Helper Functions
    func fillGapsBetween(_ status:gridStatus, _ start: Int, _ end: Int) {
        // Same cells, or adjacent cells do not have gaps in between them
        if (start == end) || abs(start-end)==1 || abs(start-end)==10 { return }
        animateStatusBetween(status: status, start, end)
    }
    
    func initiateCleanUp() { //Helper functions to clean up all the selected states
        for i in 0..<game.size {
            for j in 0..<game.size {
                if (game.grid[i][j].status == .selected) {
                    game.grid[i][j].status = .notFound
                    gridView.reloadItems(at: [IndexPath(item: game.getIndex(row: i, col: j), section: 0)])
                }
            }
        }
    }
    
    //MARK: AutoLayout functions
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
       layoutViews()

    }
    
    func layoutViews() {
        
        //Height and width of screen
        let height = (self.view.frame.height > self.view.frame.width)
                        ? self.view.frame.height : self.view.frame.width
        let width = (self.view.frame.height < self.view.frame.width)
                        ? self.view.frame.height : self.view.frame.width
        
        //UI Parameters
        let gridSize = width
        let wsLabelHeight = 45
        let resetBtnHeight = 25
        let wordsFoundWidth = 140
        let gameParametersHeight = 35 // replaces and Words Found Labels
        let safe = 10 //Safe Distance from corners
        
        //Necessary to rearrange cells in collection view when layout changes
        gridView.collectionViewLayout.invalidateLayout()
        wordsView.collectionViewLayout.invalidateLayout()
        
        if (UIDevice.current.orientation.isLandscape) {
            print("Orientation: Landscape")

            var topSafeHeight: CGFloat = 0 //The top inset in iPhone X models
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.windows[0]
                let safeFrame = window.safeAreaLayoutGuide.layoutFrame
                topSafeHeight = (safeFrame.minY > safeFrame.minX) ? safeFrame.minY : safeFrame.minX
                
            }
            
            //Place Grid
            gridView.frame = (CGRect(x: 0, y: topSafeHeight-CGFloat(safe), width: gridSize-topSafeHeight-CGFloat(safe), height: gridSize-topSafeHeight-CGFloat(safe)))
            
            let remainingWidth = height - 2*topSafeHeight - gridView.frame.width - CGFloat(safe)
            let remainingX = Int(gridView.frame.width) + safe
            // Place Label :
            let wsY = Int(topSafeHeight)
            wordSearchLabel.frame = CGRect(x: remainingX, y: wsY, width: Int(remainingWidth), height: wsLabelHeight)
            
            //Place Button :
            let btnY = wsY + safe
            let btnX = Int(height) - 2*Int(topSafeHeight) - resetBtnHeight
            resetButton.frame = CGRect(x: btnX, y: btnY,
                                       width: resetBtnHeight, height: resetBtnHeight)
            
            //Place Reveals and Word Found Labels
            let gameParametersLabelY = btnY + wsLabelHeight
            revealsRemainingLabel.frame = CGRect(x: remainingX + safe, y: gameParametersLabelY, width: Int(remainingWidth), height: gameParametersHeight)
            wordsFound.frame = CGRect(x: Int(height) - wordsFoundWidth - 2*Int(topSafeHeight), y: gameParametersLabelY, width: wordsFoundWidth, height: gameParametersHeight)
            
            //Place Words
            let namesGridHeight: Int = Int(width - wordsFound.frame.maxY)
            wordsView.frame = (CGRect(x: remainingX, y: Int(wordsFound.frame.maxY) - safe, width: Int(remainingWidth), height: namesGridHeight))
            
        } else {
            print("Orientation: Portrait")
            var topSafeHeight: CGFloat = 0
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.windows[0]
                let safeFrame = window.safeAreaLayoutGuide.layoutFrame
                topSafeHeight = (safeFrame.minY > safeFrame.minX) ? safeFrame.minY : safeFrame.minX
            }
            
            // Place Label :
            wordSearchLabel.frame = CGRect(x: 0, y: 0, width: Int(width), height: wsLabelHeight)
            
            //Place Button :
            let btnY = safe
            resetButton.frame = CGRect(x: Int(width) - resetBtnHeight - safe, y: btnY,
                                        width: resetBtnHeight, height: resetBtnHeight)
            
            //Place Reveals and Word Found
            let gameParametersLabelY = btnY + wsLabelHeight
            revealsRemainingLabel.frame = CGRect(x: safe, y: gameParametersLabelY, width: Int(resetButton.frame.maxX), height: gameParametersHeight)
            wordsFound.frame = CGRect(x: Int(width)-safe-wordsFoundWidth, y: gameParametersLabelY, width: wordsFoundWidth, height: gameParametersHeight)
            
            //Place Grid
            let gridY = CGFloat(gameParametersHeight + gameParametersLabelY)
            gridView.frame = (CGRect(x: 0, y: gridY, width: gridSize, height: gridSize))
            
            //Place Words
            let wordsGridHeight: Int = Int(height - gridView.frame.maxY - topSafeHeight)
            let wordsGridY = Int(gridView.frame.maxY)
            wordsView.frame = (CGRect(x: 0, y: wordsGridY, width: Int(gridSize), height: wordsGridHeight))
            
        }
    }
    

}

//MARK: Helper functions to get UIColor directly using Hex code
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}


