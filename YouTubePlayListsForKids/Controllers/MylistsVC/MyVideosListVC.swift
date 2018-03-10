//
//  MyVideosListVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/4/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import RealmSwift
import IceCream
import RxRealm
import RxSwift
import Alamofire
//import SQLite

class MyVideosListVC: UIViewController,UITableViewDataSource, UITableViewDelegate,CellCheckBoxCheckDelegate {

    let bag = DisposeBag()
    
    let realm = try! Realm()
    
    var tableView = UITableView()
    var myVideos = [LocalVideo]()
    var playlistId = ""
    var playingVideos = [PlayingVideo]()
    var fromMain = false
    
    var cellIsEditing = false
    var selectedCount = 0
 //   var delegate: LeftMenuProtocol?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectToPlay))
        

        let backBtn = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(cancelAction))
        let selectAllBtn = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(selectAllVideos))
        
        navigationItem.leftBarButtonItems = [backBtn,selectAllBtn]

        
        
        self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(tableView)
        
        tableView.register(VideoCell.nib, forCellReuseIdentifier: VideoCell.identifier)
        
        
        loadMyVideos()
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange , object: nil)

        
        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: 0,height: 0))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "MyVideosListVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    @objc func orientationChanged(){
        if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)){
            self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        }
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)){
            self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        }
    }
    
    func loadMyVideos(){
        self.myVideos.removeAll()
        self.playingVideos.removeAll()
        let localVideos = realm.objects(LocalVideo.self).filter("playlistId == %@",(self.playlistId)).sorted(byKeyPath: "videoTitle")
        

        var items = [LocalVideo]()
        Observable.array(from: localVideos).subscribe(onNext: { (localVideos) in
            items = localVideos.filter{ !$0.isDeleted }
            
            
            
            for item in items {
                self.myVideos.append(item)
                let playVideo = PlayingVideo(videoId: item.videoId, title: item.videoTitle)
                self.playingVideos.append(playVideo)
                
            }
            
            print(self.myVideos.count)
            if self.myVideos.count < 1 {
                self.navigationItem.rightBarButtonItem?.title = ""
            }
            self.tableView.reloadData()
            
            
        }).disposed(by: bag)




    }

    
 //=============================================================================
    @objc func selectToPlay(){
        if navigationItem.rightBarButtonItem?.title == "Select"{
            
            navigationItem.rightBarButtonItem?.title = "Play"
            navigationItem.rightBarButtonItem?.isEnabled = false

            navigationItem.leftBarButtonItems![0].title = "Cancel"
            navigationItem.leftBarButtonItems![1].title = "Select All"
            
            self.cellIsEditing = true
            
        }else if navigationItem.rightBarButtonItem?.title == "Play"{
            queueToPlay()
            
            navigationItem.rightBarButtonItem?.title = "Select"
            navigationItem.leftBarButtonItems![0].title = "Back"
            navigationItem.leftBarButtonItems![1].title = ""
            
            
            self.cellIsEditing = false
            self.selectedCount = 0
        }
        self.tableView.reloadData()

    }
    
    func queueToPlay(){
      //  let myvideoPlayer = MyVideoPlayerVC()
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let append = UIAlertAction(title: "Add to current Playing list", style: .default) { (action) in
            self.playing()
        }
        
        let clear = UIAlertAction(title: "Create new Playing list", style: .default) { (action) in
            self.deletePlaying()
            self.playing()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(append)
        alert.addAction(clear)
        alert.addAction(cancel)
        if let popoverController = alert.popoverPresentationController {
            // popoverController.barButtonItem = sender as? UIBarButtonItem
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            
        }
        present(alert, animated: true, completion: nil)
        
 
    }
    
    func deletePlaying(){
        let items = realm.objects(PlayingVideo.self)
        var v = [PlayingVideo]()
        Observable.array(from: items).subscribe(onNext: { (items) in
            v = items.filter{ !$0.isDeleted }
        }).disposed(by: self.bag)

        do {
            try realm.write {
             //   realm.delete(items)
                for item in v {
                    item.isDeleted = true
                }
             }
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    
    func playing() {
        let videosToPlay = self.playingVideos.filter{$0.isSelected==true}
        print(videosToPlay.count)
        if videosToPlay.count > 0 {
            for item in videosToPlay {
                let playing = PlayingVideo(videoId: item.videoId, title: item.title, isSelected: true)
                do {
                    try realm.write {
                        /// Add... or update if already exists
                        realm.add(playing, update: true)
                    }
                } catch let error as NSError {
                    fatalError(error.localizedDescription)
                }
                
            }
        }
      //  self.dismissAlert()
        self.resetToUnselected()
        
        if fromMain {
            _ = navigationController?.popToRootViewController(animated: true)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "backToMain"), object: self)
        }
    }

    
    @objc func selectAllVideos(){
        print("select all")
        let count = self.playingVideos.count
        self.selectedCount = count
        if count > 0 {
            navigationItem.rightBarButtonItem?.isEnabled = true
            for i in 0...count - 1 {
                self.playingVideos[i].isSelected = true
            }
        }
        self.tableView.reloadData()
    }
    
    @objc func cancelAction(){
        if navigationItem.leftBarButtonItems![0].title == "Back"{
            self.cellIsEditing = false
            _ = navigationController?.popViewController(animated: true)
        }else if navigationItem.leftBarButtonItems![0].title == "Cancel"{
            navigationItem.leftBarButtonItems![0].title = "Back"
            navigationItem.rightBarButtonItem?.title = "Select"
            navigationItem.leftBarButtonItems![1].title = ""

            navigationItem.rightBarButtonItem?.isEnabled = true
            self.cellIsEditing = false
        }
        resetToUnselected()
        self.tableView.reloadData()
    }
    func resetToUnselected(){
        if self.playingVideos.count > 1 {
            for i in 0...self.playingVideos.count - 1 {
                self.playingVideos[i].isSelected = false
            }
        }

    }
    
//======================================================================================
    func checkBoxDidSelect(_ sender: VideoCell) {
        guard let index = tableView.indexPath(for: sender) else {
            return
        }
        self.playingVideos[index.item].isSelected = true
        self.selectedCount += 1
        if self.selectedCount < 1 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    func checkBoxDidDeSelect(_ sender: VideoCell) {
        guard let index = tableView.indexPath(for: sender) else {
            return
        }
        self.playingVideos[index.item].isSelected = false
        self.selectedCount -= 1
        if self.selectedCount < 1 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }

    }
    
    
    
    
//======================================================================================
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myVideos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell
        cell.setEditingMode(self.cellIsEditing)
        cell.delegate = self
        if self.cellIsEditing {
            cell.checkBox.isCheckboxSelected = self.playingVideos[indexPath.row].isSelected
            print(cell.checkBox.isCheckboxSelected)
        }
        
        let myVideo = self.myVideos[indexPath.item]
        print(myVideo.compoundKey)
        cell.videoTitle.text = myVideo.videoTitle
        cell.addButton.isHidden = true
        cell.videoDescription.isHidden = true
        cell.labelButtonConstraint.constant = 0
        if myVideo.videoImg != "" {
            Alamofire.request(myVideo.videoImg).responseData { response in
                if let data = response.result.value {
                    cell.videoThumbnail.image = UIImage(data: data)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.cellIsEditing == false {
            if fromMain {
                let video = self.myVideos[indexPath.row]
                let playing = PlayingVideo(videoId: video.videoId, title: video.videoTitle, isSelected: true)
                do {
                    try realm.write {
                        /// Add... or update if already exists
                        realm.add(playing, update: true)
                      //  self.dismissAlert()
                    }
                } catch let error as NSError {
                    fatalError(error.localizedDescription)
                }
                
                navigationController?.popToRootViewController(animated: true)
            } else {
            
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerVC") as! PlayerVC
                playerVC.itemID = self.myVideos[indexPath.row].videoId
                playerVC.fromMyList = true
                self.navigationController?.pushViewController(playerVC, animated: true)
            }

        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            
             let alert = UIAlertController(title: nil, message: "Confirm to delete", preferredStyle: .alert)
             let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
             let ok = UIAlertAction(title: "Delete", style: .default, handler: { (action) in
             
                try! self.realm.write {
           //  realm.delete(self.myVideos[indexPath.row])
               self.myVideos[indexPath.row].isDeleted = true
             }
                self.loadMyVideos()
        //     self.myVideos.remove(at: indexPath.row)
        //     self.tableView.deleteRows(at: [indexPath], with: .fade)
             
             })
             alert.addAction(cancel)
             alert.addAction(ok)
             self.present(alert, animated: true, completion: nil)
 
        }
        let move = UITableViewRowAction(style: .normal, title: "Move") { (action, indexPath) in
            
            
            let alert = UIAlertController(title: nil, message: "Move to another list?", preferredStyle: .actionSheet)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

            let localList = self.realm.objects(LocalPlayList.self).sorted(byKeyPath: "title").filter("isDeleted != true")
            for list in localList {
                alert.addAction(UIAlertAction(title:"\(list.title)", style: .default, handler: { (action) in
                    print(list.title)
                    let oldVideo = self.myVideos[indexPath.row]
                    let newVideo = LocalVideo(videoId: oldVideo.videoId, playlistId: list.id, videoTitle: oldVideo.videoTitle, videoImg: oldVideo.videoImg)

                    try! self.realm.write {
                      //  realm.delete(self.myVideos[indexPath.row])
                        self.myVideos[indexPath.row].isDeleted = true
                        self.realm.add(newVideo, update: true)
                        self.dismissAlert()
                    }
                      self.loadMyVideos()

                }))
              
            }
            alert.addAction(cancel)
            if let popoverController = alert.popoverPresentationController {
                // popoverController.barButtonItem = sender as? UIBarButtonItem
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
                
            }
            
            self.present(alert, animated: true, completion: nil)

        }
        
        delete.backgroundColor = UIColor.red
        move.backgroundColor = blueColor
        return[delete,move]
    }
    

}
