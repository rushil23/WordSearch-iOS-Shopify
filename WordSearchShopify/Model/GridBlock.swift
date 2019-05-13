//
//  GridBlock.swift
//  WordSearchShopify
//
//  Created by Rushil on 2019-05-09.
//  Copyright © 2019 Rushil. All rights reserved.
//

import UIKit

//Grid status changes upon user interaction ---> results in UI color changes
enum gridStatus {
    case notFound //Grids that are not found
    case selected //Grids that are in the process of being drawn / swiped by user
    case found    //Grids that are found
}

class GridBlock: NSObject {
    var character: String
    var status: gridStatus
    
    override init() {
        character = "-"
        status = .notFound
    }
    
   init(character: String, status: gridStatus) {
        self.character = character
        self.status = status
    }
}
