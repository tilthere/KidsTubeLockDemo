//
//  ExistingListVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/3/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import RealmSwift
import IceCream
import RxRealm
import RxSwift


class ExistingListVC: UITableViewController {

    var listNames = [ExistingPlayList]()
    var previousSelected: IndexPath?
    var videos = [LocalVideo]()
    var playlistid = ""
    var realm = try! Realm()
    let bag = DisposeBag()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("selected videos: \(videos.count)")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelSelect))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didSelectList))
        
        
        getExistingList()

    }

    @objc func didSelectList(){
       // save to existing list
        print(self.playlistid)
        for video in videos {
            let id = video.videoId
            
            let videoTitle = video.videoTitle
         //   print(id!,videoThumbnail!, videoTitle!,playlistid)
            if video.videoImg != "" {
                let localVideo = LocalVideo(videoId: id, playlistId: self.playlistid, videoTitle: videoTitle, videoImg: video.videoImg)
                localVideo.realmSave()
            } else {
                let localVideo = LocalVideo(videoId: id,playlistId: self.playlistid,videoTitle: videoTitle)
                localVideo.realmSave()
            }

        }
        _ = navigationController?.popViewController(animated: true)
    }
    @objc func cancelSelect(){
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    
    func getExistingList(){
        self.listNames.removeAll()
        let localList = realm.objects(LocalPlayList.self).filter("isDeleted = false").sorted(byKeyPath: "title")
        
        Observable.array(from: localList).subscribe(onNext: { (localList) in

            let items = localList.filter{ !$0.isDeleted }
            for item in localList {
                let name = item.title
                let id = item.id
                let list = ExistingPlayList(title: name, id: id)
                self.listNames.append(list)
            }

            self.tableView.reloadData()
        }).disposed(by: bag)
        

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.listNames.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingListCell", for: indexPath)
        cell.textLabel?.text = self.listNames[indexPath.item].title
        // Configure the cell...
        
        if self.listNames[indexPath.item].isSelected {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.previousSelected != nil {
            self.listNames[previousSelected!.item].isSelected = false
            self.tableView.reloadRows(at: [previousSelected!], with: .fade)
        }
        
        self.previousSelected = indexPath
        if let cell = tableView.cellForRow(at: indexPath) {
        if cell.accessoryType == .none {
            cell.accessoryType = .checkmark
            self.listNames[indexPath.item].isSelected = true
            self.playlistid = self.listNames[indexPath.item].id
        } else if cell.accessoryType == .checkmark {
            cell.accessoryType = .none
            self.listNames[indexPath.item].isSelected = false

        }
        self.tableView.reloadRows(at: [indexPath], with: .fade)
            
        }
    }
    
    


}
