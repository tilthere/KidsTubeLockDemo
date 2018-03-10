//
//  RealmModels.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/4/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import Foundation
import RealmSwift
import IceCream
import CloudKit

class RealmString: Object {
    @objc dynamic var stringValue = ""
}

class LocalChannel: Object{
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var desc = ""
    @objc dynamic var img = ""
    @objc dynamic var isDeleted = false

    override static func primaryKey() -> String? {
        return "id"
    }
    
}

extension LocalChannel: CKRecordConvertible {
    
}

extension LocalChannel: CKRecordRecoverable {
    
   typealias O = LocalChannel
}




class LocalPlayList: Object {
    @objc dynamic var title = ""
  //  var tag = List<RealmString>()
    @objc dynamic var tag1 = ""
    @objc dynamic var tag2 = ""
    
    @objc dynamic var id = ""
    @objc dynamic var isHiden = true
    @objc dynamic var isDeleted = false

    
    override static func primaryKey() -> String? {
        return "id"
    }


    convenience init(title:String, tag1: String, tag2: String, isHiden: Bool = true) {
        self.init()
        self.id = UUID().uuidString
        self.tag1 = tag1
        self.tag2 = tag2
        self.title = title
        self.isHiden = isHiden
    }
    func getTags() -> [String] {
        var tags = [String]()
        if self.tag1 != "" {
            tags.append(tag1)

        }
        if self.tag2 != "" {
            tags.append(tag2)

        }
        return tags
    }
    

}

extension LocalPlayList: CKRecordConvertible {
    
}

extension LocalPlayList: CKRecordRecoverable {
     typealias O = LocalPlayList
}


class LocalVideo: Object {

    @objc dynamic var compoundKey = "0-"

    @objc dynamic var videoId = ""
    @objc dynamic var playlistId = ""
    @objc dynamic var videoTitle = ""
    @objc dynamic var videoImg = ""
    @objc dynamic var isDeleted = false


    public override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(videoId)-\(playlistId)"
    }
    
    convenience init(videoId: String, playlistId: String = "", videoTitle: String, videoImg: String = "") {
        self.init()
        self.videoId = videoId
        self.playlistId = playlistId
        self.compoundKey = playlistId + "-" + videoId
        self.videoTitle = videoTitle
        self.videoImg = videoImg
    }
    
}


extension LocalVideo: CKRecordConvertible {
    
}

extension LocalVideo: CKRecordRecoverable {
     typealias O = LocalVideo
}


class PlayingVideo: Object {
    @objc dynamic var isSelected = false
 //   var myVideo: LocalVideo!
    @objc dynamic var videoId = ""
    @objc dynamic var title = ""
    @objc dynamic var isDeleted = false


    convenience init(videoId: String, title: String, isSelected: Bool = false) {
        self.init()
        self.videoId = videoId
        self.isSelected = isSelected
        self.title = title
        
    }
    override static func primaryKey() -> String? {
        return "videoId"
    }
}


extension PlayingVideo: CKRecordConvertible {
    
}

extension PlayingVideo: CKRecordRecoverable {
     typealias O = PlayingVideo
}



extension Object {
    func realmSave(){
        let rm = try! Realm()
        do {
            
            try rm.write {
                /// Add... or update if already exists
                rm.add(self, update: true)
            }
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }

}


