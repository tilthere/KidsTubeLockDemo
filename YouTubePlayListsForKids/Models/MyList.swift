//
//  MyLists.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/31/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit

struct MyList {
    let title: String!
//    let tagOne:String?
//    let tagTwo: String?
    var tags: [String] = [String]()
    var id: Int!
    init(title: String, tags: [String], id: Int) {
        self.title = title
        self.tags = tags
        self.id = id
    }
}

struct MyLists {
    var mylists : [MyList]!
    mutating func remove (title:String) {
        for i in 0...mylists.count{
            if mylists[i].title == title {
                mylists = mylists.filter { $0.title != "title" }

            }
        }
    }
}

class Tag :Hashable {
    var name: String!
    var isSelected: Bool!
    var hashValue: Int {
        return name.hashValue
    }

    init(name: String) {
        self.name = name
        self.isSelected = false
    }
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name == rhs.name && lhs.name == rhs.name
    }

    
}

struct MyVideo {
    var title: String!
    var image: UIImage?
    var id: String!
}

struct ExistingPlayList {
    var title: String!
    var isSelected: Bool!
    var id: String!
    init(title: String, id: String) {
        self.title = title
        self.isSelected = false
        self.id = id
    }
}



