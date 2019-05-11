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
    
    @IBOutlet weak var safeFrame: UIView!
    @IBOutlet weak var gridView: UICollectionView!
    @IBOutlet weak var namesView: UICollectionView!
    @IBOutlet weak var hintsRemainingLabel: UILabel!
    
    
    let game = Game()
    var firstTap: Int = -1
    var secondTap: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup game
        game.populateGrid()
        gridView.reloadData()
        
        //Height and width of screen
        let height = safeFrame.frame.height
        let width = safeFrame.frame.width
        let unsafeHeight = self.view.frame.height - height
        print("Height = \(height), width = \(width), \(unsafeHeight)")
        
        //Setup Buttons
        //TODO: AutoLayout button
        let resetBtnWidth = 30
        let resetBtnHeight = 30
        let resetBtnX = Int(width) - resetBtnWidth - 40
        let resetBtn = UIButton(frame: CGRect(x: resetBtnX, y: Int(unsafeHeight+25), width: resetBtnWidth, height: resetBtnHeight))
        resetBtn.setImage(UIImage(named: "restart50"), for: .normal)
        resetBtn.addTarget(self, action: #selector(resetLevel), for: .touchUpInside)
        self.view.addSubview(resetBtn)
        
        
        
        //SetupGrid
        gridView.layer.cornerRadius = 10
        gridView.clipsToBounds = true
        
        
        
        
        
    }
    
    @objc func resetLevel(sender: UIButton!) {
        print("RESHUFFLE")
        game.populateGrid()
        hintsRemainingLabel.text = "Hints: \(game.hintsRemaining)"
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
            var indexes: [IndexPath] = []
            if (firstTap == -1) {
                firstTap = indexPath.item
                game.updateStatusAtIndex(status: .selected, index: indexPath.item)
                indexes.append(indexPath)
            } else if (game.sameRowOrColumn(firstTap, indexPath.item) != .none) {
                secondTap = indexPath.item
                indexes.append(indexPath)
                game.updateStatusAtIndex(status: .selected, index: secondTap)
                
                let word: String = game.getWordBetweenIndexes(firstTap, secondTap)
                print("Word Selected = \(word)")
                
                game.updateStatusBetween(.selected, firstTap, secondTap)
                if (game.foundWord(word)) {
                    game.updateStatusBetween(.found, firstTap, secondTap)
                    print("Found word!")
                    
                    if (game.wordsFound == game.count) {
                        //Present WIN Alert
                        presentWinAlert()
                    }
                    
                } else {
                    print("Did not find word!")
                    game.updateStatusBetween(.notFound, firstTap, secondTap)
                }
                
                gridView.reloadData()
                namesView.reloadData()
                
                firstTap = -1
                secondTap = -1
                
            } else {
                game.updateStatusAtIndex(status: .notFound, index: firstTap)
                game.updateStatusAtIndex(status: .selected, index: indexPath.item)
                indexes.append(indexPath)
                indexes.append(IndexPath(item: firstTap, section: 0))
                firstTap = indexPath.item
            }
            
            gridView.reloadItems(at: indexes)
        } else {
            if (game.hintsRemaining > 0 && game.words[indexPath.item].status == .notFound) {
                game.hintsRemaining -= 1
                hintsRemainingLabel.text = "Hints: \(game.hintsRemaining)"
                let word = game.words[indexPath.item].word
                game.revealWord(word)
                game.words[indexPath.item].status = .found
                
                namesView.reloadData()
                gridView.reloadData()
                
                if (game.wordsFound == game.count) {
                    //Present WIN Alert
                    presentWinAlert()
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (collectionView == gridView) {
            return CGSize(width: collectionView.bounds.size.width/10, height: collectionView.bounds.size.height/10)
        } else {
            return CGSize(width: collectionView.bounds.size.width/2, height: 40)
        }
    }
    
    func presentWinAlert() {
        let alert = UIAlertController(title: "YOU WON!", message: "Congrats! You found all the words", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Thats Great! :)", style: .default, handler: { action in
            self.game.populateGrid()
            self.gridView.reloadData()
            self.namesView.reloadData()
            self.hintsRemainingLabel.text = "Hints: \(self.game.hintsRemaining)"
        }))
        self.present(alert, animated: true, completion: nil)
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


