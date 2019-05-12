//
//  Word.swift
//  WordSearchShopify
//
//  Created by Rushil on 2019-05-10.
//  Copyright © 2019 Rushil. All rights reserved.
//

import UIKit

enum WordStatus {
    case notFound //Words that are not found
    case found //Words that are found
}

class Word: NSObject {
    var word: String
    var status: WordStatus
    
    override init() {
        word = ""
        status = .notFound
    }
    
    init(word: String, status: WordStatus) {
        self.word = word
        self.status = status
    }
}
