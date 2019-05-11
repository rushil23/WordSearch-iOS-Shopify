//
//  ViewController.swift
//  WordSearchShopify
//
//  Created by Rushil on 2019-05-07.
//  Copyright © 2019 Rushil. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    //ColorScheme:
    let darkRed = UIColor(rgb: 0xb71c1c)
    let crimsonRed = UIColor(rgb: 0xd50000)
    let mediumRed = UIColor(rgb: 0xf44336)
    let lightRed = UIColor(rgb: 0xffcdd2)
    let selectedRed = UIColor(rgb: 0xef5350)
    
    @IBOutlet weak var gridView: UICollectionView!
    @IBOutlet weak var namesView: UICollectionView!
    @IBOutlet weak var hintsRemainingLabel: UILabel!
    @IBOutlet weak var wordsFound: UILabel!
    @IBOutlet weak var wordSearchLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var safeArea: UIView!
    
    
    
    let game = Game()
    var startIndex: Int = -1
    var endIndex: Int = -1
    //Swipe Variables
    var currIndex: Int = -1
    var gridCount: Int = 0
    
    //AutoLayoutVariables
    var topSafeHeight: CGFloat = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        layoutViews()
        
        //SetupGrid
        gridView.layer.cornerRadius = 10
        gridView.clipsToBounds = true
        
        //Setup game
        game.populateGrid()
        gridView.reloadData()
    
    }
    @IBAction func resetLevel(_ sender: Any) {
        print("RESHUFFLE")
        game.populateGrid()
        hintsRemainingLabel.text = "Hints: \(game.hintsRemaining)"
        wordsFound.text = "Words Found: \(game.wordsFound)"
        gridView.reloadData()
        namesView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (collectionView==gridView) ? game.size*game.size : game.wordList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == gridView) {
            let grid = gridView.dequeueReusableCell(withReuseIdentifier: "Grid", for: indexPath) as! GridViewCell
            
            let gridBlock = game.getCharArray()![indexPath.item]
            
            grid.character.text = gridBlock.character
            
            switch gridBlock.status {
                
                case .notFound:
                    grid.backgroundColor = darkRed
                    break
                case .selected:
                    grid.backgroundColor = selectedRed
                    break
                case .found:
                    grid.backgroundColor = selectedRed
                    break
                }
            
            return grid
        } else {
            let nameCell = namesView.dequeueReusableCell(withReuseIdentifier: "NameCell", for: indexPath) as! NameViewCell
            
            let words = game.words
            
            nameCell.name.text = words[indexPath.item].word
            let status = words[indexPath.item].status
            nameCell.name.textColor = mediumRed
            
            if (status == .found) {
                let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: words[indexPath.item].word)
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
                nameCell.name.attributedText = attributeString
            } else {
                nameCell.name.font = UIFont.systemFont(ofSize: 26)
            }
            
            return nameCell
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (collectionView == gridView) {
            print("Grid Selected = \(indexPath.item)")
            if (startIndex == -1) {
                startIndex = indexPath.item
                game.updateStatusAtIndex(status: .selected, index: indexPath.item)
            } else if (game.sameRowOrColumn(startIndex, indexPath.item) != .none) {
                endIndex = indexPath.item
                
                game.updateStatusBetween(.selected, startIndex, endIndex)
                //Animate this function
                checkWord()
                
                startIndex = -1
                endIndex = -1
            } else {
                game.updateStatusAtIndex(status: .notFound, index: startIndex)
                game.updateStatusAtIndex(status: .selected, index: indexPath.item)
                startIndex = indexPath.item
            }
            
            gridView.reloadData()
        } else {
            if (game.hintsRemaining > 0 && game.words[indexPath.item].status == .notFound) {
                game.hintsRemaining -= 1
                hintsRemainingLabel.text = "Hints: \(game.hintsRemaining)"
                let word = game.words[indexPath.item].word
                game.revealWord(word)
                game.words[indexPath.item].status = .found
                
                namesView.reloadData()
                gridView.reloadData()
                
                wordsFound.text = "Words Found: \(game.wordsFound)"
                
                if (game.wordsFound == game.count) {
                    //Present WIN Alert
                    presentWinAlert()
                }
            }
        }
    }
    
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        guard let index = gridView.indexPathForItem(at: recognizer.location(in: gridView))?.item else { return }
        if currIndex == index && recognizer.state != .ended {
            return
        } else if startIndex == index {
            return
        }
        switch (recognizer.state) {
        case .began:
            startIndex = index
            currIndex = index
            print("BEGAN AT POINT: \(index)")
            gridCount += 1
            game.updateStatusAtIndex(status: .selected, index: startIndex)
            break
        case .changed:
            if game.sameRowOrColumn(currIndex, index) == .none
                || game.sameRowOrColumn(startIndex, index) == .none{
                return
            }
            fillGapsBetween(.selected, currIndex, index)
            currIndex = index
            print("CHANGED AT POINT: \(index)")
            gridCount += 1
            game.updateStatusAtIndex(status: .selected, index: currIndex)
            break
        case .ended:
            if game.sameRowOrColumn(currIndex, index) == .none
                || game.sameRowOrColumn(startIndex, index) == .none{
                endIndex = currIndex
            } else {
                endIndex = index
                currIndex = index
                fillGapsBetween(.selected, currIndex, index)
            }
            
            print("ENDED AT POINT: \(endIndex)")
            gridCount += 1
            game.updateStatusAtIndex(status: .selected, index: endIndex)
            checkWord()
            break
        default:
            break
        }
        gridView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (collectionView == gridView) {
            return CGSize(width: collectionView.bounds.size.width/10, height: collectionView.bounds.size.height/10)
        } else {
//            if (UIDevice.current.orientation.isLandscape) {
//                return CGSize(width: collectionView.bounds.size.width, height: collectionView.bounds.size.height/8)
//            }
            return CGSize(width: collectionView.bounds.size.width/2, height: collectionView.bounds.size.height/4)
        }
    }
    
    func fillGapsBetween(_ status:gridStatus, _ start: Int, _ end: Int) {
        // Same cells, or adjacent cells do not have gaps in between them
        if (start == end) || abs(start-end)==1 || abs(start-end)==10 { return }
        game.updateStatusBetween(status, start, end)
    }

    func presentWinAlert() {
        let alert = UIAlertController(title: "YOU WON!", message: "Congrats! You found all the words", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Thats Great! :)", style: .default, handler: { action in
            self.game.populateGrid()
            self.gridView.reloadData()
            self.namesView.reloadData()
            self.hintsRemainingLabel.text = "Hints: \(self.game.hintsRemaining)"
            self.wordsFound.text = "Words Found: \(self.game.wordsFound)"
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func checkWord() {
        let word: String = game.getWordBetweenIndexes(startIndex, endIndex)
        print("Word Selected = \(word)")
        
        if (game.foundWord(word)) {
            game.updateStatusBetween(.found, startIndex, endIndex)
            print("Found word!")
            namesView.reloadData()
            wordsFound.text = "Words Found: \(game.wordsFound)"
            
            if (game.wordsFound == game.count) {
                //Present WIN Alert
                presentWinAlert()
            }
            
        } else {
            print("Did not find word!")
            game.updateStatusBetween(.notFound, startIndex, endIndex)
        }
        
        //EdgeCase: If user swipes back, need to initiate clean up
        if gridCount != word.count {
            print("Cleaning Up Matrix! ")
            game.initiateCleanUp()
        }
        
        startIndex = -1
        endIndex = -1
        currIndex = -1
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
       layoutViews()

    }
    
    func layoutViews() {
        
        //Height and width of screen
        let height = (self.view.frame.height > self.view.frame.width)
                        ? self.view.frame.height : self.view.frame.width
        let width = (self.view.frame.height < self.view.frame.width)
                        ? self.view.frame.height : self.view.frame.width
        
        let gridSize = width
        print("AutoLayout: Height = \(height), Width = \(width)")
        let wsLabelHeight = 45
        let wsLabelWidth = 195
        let resetBtnHeight = 25
        let wordsFoundWidth = 140
        let gameParametersHeight = 35 // Hints and Words Found Labels
        let safe = 10 //Safe Distance from corners
        
        gridView.collectionViewLayout.invalidateLayout()
        namesView.collectionViewLayout.invalidateLayout()
        
        if (UIDevice.current.orientation.isLandscape) {
            print("Orientation: Landscape")

            var topSafeHeight: CGFloat = 0 //The top inset in iPhone X models
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.windows[0]
                let safeFrame = window.safeAreaLayoutGuide.layoutFrame
                topSafeHeight = (safeFrame.minY > safeFrame.minX) ? safeFrame.minY : safeFrame.minX
                
            }
            print("Height = \(height), width = \(width), \(topSafeHeight)")
            
            // Grid Setup
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
            
            //Place Hints and Word Found
            let gameParametersLabelY = btnY + wsLabelHeight
            hintsRemainingLabel.frame = CGRect(x: remainingX + safe, y: gameParametersLabelY, width: Int(remainingWidth), height: gameParametersHeight)
            wordsFound.frame = CGRect(x: Int(height) - wordsFoundWidth - 2*Int(topSafeHeight), y: gameParametersLabelY, width: wordsFoundWidth, height: gameParametersHeight)
            
            // Names Setup
            let namesGridHeight: Int = Int(width - wordsFound.frame.maxY)
            namesView.frame = (CGRect(x: remainingX, y: Int(wordsFound.frame.maxY) - safe, width: Int(remainingWidth), height: namesGridHeight))
            
        } else {
            print("Orientation: Portrait")
            var topSafeHeight: CGFloat = 0
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.windows[0]
                let safeFrame = window.safeAreaLayoutGuide.layoutFrame
                topSafeHeight = (safeFrame.minY > safeFrame.minX) ? safeFrame.minY : safeFrame.minX
            }
            print("Height = \(height), width = \(width), \(topSafeHeight)")
            
            // Place Label :
            wordSearchLabel.frame = CGRect(x: 0, y: 0, width: Int(width), height: wsLabelHeight)
            
            //Place Button :
            let btnY = safe
            resetButton.frame = CGRect(x: Int(width) - resetBtnHeight - safe, y: btnY,
                                        width: resetBtnHeight, height: resetBtnHeight)
            
            //Place Hints and Word Found
            let gameParametersLabelY = btnY + wsLabelHeight
            hintsRemainingLabel.frame = CGRect(x: safe, y: gameParametersLabelY, width: Int(resetButton.frame.maxX), height: gameParametersHeight)
            wordsFound.frame = CGRect(x: Int(width)-safe-wordsFoundWidth, y: gameParametersLabelY, width: wordsFoundWidth, height: gameParametersHeight)
            
            // Grid Setup
            let gridY = CGFloat(gameParametersHeight + gameParametersLabelY)
            gridView.frame = (CGRect(x: 0, y: gridY, width: gridSize, height: gridSize))
            
            // Names Setup
            let namesGridHeight: Int = Int(height - gridView.frame.maxY - topSafeHeight)
            let namesGridY = Int(gridView.frame.maxY)
            namesView.frame = (CGRect(x: 0, y: namesGridY, width: Int(gridSize), height: namesGridHeight))
            
        }
    }
    

}

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


