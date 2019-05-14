<img src = "WordSearch5Logo.png" width = 75 align="left">  


# Word Search 5 - Powered by Swift 5
<p align="center">
    <img src = "Screenshots/GIFs/appDemoGif.gif" height="600" align="center">
</p>

## Shopify Challenge Task List: 
1. Create a Word Search iOS App ✔
2. Word search should have at least a 10 x 10 grid ✔ 
3. Include at least the following 6 words ✔
[Swift, Kotlin, ObjectiveC, Variable, Java, Mobile.]
4. Keep track of how many words a user has found ✔
5. Compiles successfully ✔
### Bonus:
6. Randomize word placement ✔
7. Make a slick UI with smooth animations ✔
8. Make it look good in portrait and landscape ✔
9. Allow users to find words by swiping over words ✔
10. Add additional features ✔

## Features
1. **Word Selection can be done in two easy ways:**
    - Two-Tap selection
    - Swipe over words

While testing, I realized that swiping on a 10 x 10 grid would be a little hard for smaller devices like the iPhone 7. Hence, words can be selected by tapping two grids in the same row or column too.

2. **Users get 2 Reveals: (For free!)**

Are you worried that you might not be able to find a few words in the grid? Well, don't worry! ...because you get 2 free reveals! Just tap on the word that you want to reveal, and Voila! ITS REVEALED! 
You only get 2 reveals though, use them wisely!

3. **Restart button:** 

Users can restart the game anytime they want. This resets game parameters and re-populates the grids and words view.

4. **Disco Effect:**

Users get to witness a disco effect (with smooth animations) on the grid every time they win. 

*Players definitely deserve a disco effect for their victory* :) 

5. **Nothing is hardcoded:** *This is probably gonna be my motto for a very long time*:

Architecture supports changing game parameters by modifying a few variables. This makes it easier to implement future improvements.
    - *Grid Size* can be dynamically changed to any size by modifying **GameManager.size**
    - *Word List* can be modified by changing **GameManager.wordList**
    - *Reveals* can be modified by changing **GameManager.REVEALS**

6. **Auto Layout: Supports Portrait & Landscape**

Supports any orientation on any device. (iPhones & iPads) [I've only tested it on the iPhone XR, iPhone 8, iPhone 7, iPad]

7. **Randomization Logic:**

    - Randomly places words in a grid of any size. (Words with length greater than the grid size will be ignored)
    - Supports 4 - orientations: Vertical, Horizontal, Reverse-Vertical, Reverse-Horizontal
    - Supports overlaps: The algorithm allows overlapping words as long as they collide (overlap) at the same letter.

8. **Special Edge Cases Handled:**
    - *Duplicate Words in Grid:* 
    
    There is a chance that the random letters in the grid could align to form a duplicate of one of the words in the word       list, and this function is a helper function to handle that.
    However: the chance of this happening is really low, *0.005 % [ (1/26)^3 ]* for a 3-lettered word like iOS
    - *Oversized Words in a smaller grid:*
    
    Implemented a logical function to remove all words with length greater than the size of the grid, since they obviously cannot be placed and could crash the app.
    - *Swipe Edge Cases:*
    
    Ensured that users get a lot of flexibility with their swipes. 
    For example: If a user accidentally swipes out of his row/column and comes back to the same row, he gets to continue his swipe :)
    
    - *Overlapping Words:*
    
    The algorithm is designed to prevent collisions between words, so that already placed words do not get interfered with. However, if at random, the word to be placed collides at the exact same letter as the word placed in the grid, we have found an overlap! Hence, the algorithm allows collisions/overlaps between two words at the same letter.  

9. **MVC Design Pattern:**
    - The app mainly consists of two collection views: Words & Grids. 
    - Each collection view has its on model for its collection-view-cell.
    - The two CollectionView's are controlled in the ViewController
    - All the logic to play and handle the game is present in the *GameManager.swift*

## Future Improvements:
1. Add support for diagonal words
2. Add sound effects / vibrations based on user interactions
3. Support JSON-Input/Link-to-API to modify Game Parameters such as:
    - List of words
    - Size of Grid
    - Number of reveals remaining
4. Add difficulty levels: Easy, Medium, Hard which modifies the size of the grid and the length of the words being placed.

## Screenshots

### 1. No Words Found ---> All Words Found
<p align="center">
    <img src = "Screenshots/NoWordsFound.png" height="450" align="center"> <img src = "Screenshots/AllWordsFound.png" height="450" align="center">
</p>

### 2. Slick Animations
<p align="center">
    <img src = "Screenshots/GIFs/SmoothAnimations.gif" height="450" align="center"> <img src = "Screenshots/GIFs/WinAnimations.gif" height="450" align="center">
</p>

### 3. AutoLayout: Portrait and Landscape Support

#### a. Portrait - iPhone XR
<p align="center">
    <img src = "Screenshots/AutoLayout%20-%20Portrait%20%26%20Landscape/Portrait%20-%20iPhone%20X.png" height="450" align="center">
</p>

#### b. Landscape - iPhone XR
<p align="center">
    <img src = "Screenshots/AutoLayout%20-%20Portrait%20%26%20Landscape/Landscape%20-%20iPhone%20X.png" height="350">
</p>

