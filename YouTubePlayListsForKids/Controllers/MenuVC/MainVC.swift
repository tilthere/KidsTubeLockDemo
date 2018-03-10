//
//  MainVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/7/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import YouTubePlayer
import RealmSwift
import IceCream
import RxRealm
import RxSwift
import CloudKit


class MainVC: UIViewController, SlideMenuControllerDelegate, YouTubePlayerDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var playerView: YouTubePlayerView!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func reorderList(_ sender: UIButton) {
        if sender.currentTitle == "REORDER"{
            sender.setTitle("DONE", for: .normal)
            self.tableView.isEditing = true
        } else if sender.currentTitle == "DONE"{
            sender.setTitle("REORDER", for: .normal)
            self.tableView.isEditing = false
        }
    }
    
    @IBOutlet weak var reorderBtn: UIButton!
    
    
    var playingVideos = [PlayingVideo]()
    var playingIndex = 0
    
    var autoPlay = false

    let bag = DisposeBag()

    var realm = try! Realm()
    override func viewDidLoad() {
        super.viewDidLoad()
    //    isICloudContainerAvailable()
        print("view did load.........")

        playerView.delegate = self
        
        // remove suggestions
        playerView.playerVars = ["rel" : "0" as AnyObject, "showinfo": "0" as AnyObject, "playsinline": "1" as AnyObject]
        
  /*  https://developers.google.com/youtube/player_parameters#autoplay
        "playsinline": "0",
        "controls": "0",
        "showinfo": "0",
        "autoplay" : "1",
        "fs" : "1",
        "modestbranding" : "1"
  */
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PlayinglistCell.nib, forCellReuseIdentifier: PlayinglistCell.identifier)
        


        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(accessToParentalView), name:NSNotification.Name(rawValue:"accessToParental"), object: nil)
        
        self.addBtn.addTarget(self, action: #selector(addPlaylist), for: .touchUpInside)
        self.addBtn.isHidden = true
        loadPlayingList()
        if playingVideos.count > 0 {
            playerView.loadVideoID(playingVideos[playingIndex].videoId)
        } else {
            playerView.loadVideoID("")
            
        }
        playerView.stop()
        

//        if realm.objects(LocalPlayList.self).count > 0 {
//            addBtn.isHidden = false
//        }
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

    }
    

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view will appear")
        
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "MainVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])

        
        print(realm.objects(LocalPlayList.self).count)
        print(realm.objects(LocalPlayList.self).filter("isDeleted = false").count)
        self.setNavigationBarItem()
      //  loadPlayingList()
        if playingVideos.count > 0 {
            playerView.loadVideoID(playingVideos[playingIndex].videoId)
            self.reorderBtn.isHidden = false
        } else {
            self.reorderBtn.isHidden = true
        }
        if realm.objects(LocalPlayList.self).filter("isDeleted = false").count > 0 {
            addBtn.isHidden = false
        } else {
            addBtn.isHidden = true
        }

    }
    
    //==========================================================================
    @objc func addPlaylist(){
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let clear = UIAlertAction(title: "Clear Playing list", style: .default) { (action) in
            self.confirmToClear()
        }
        let add = UIAlertAction(title: "Add from My List", style: .default) { (actiion) in
            self.pin(.verify)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        alert.addAction(add)
        if self.playingVideos.count > 0 {
            alert.addAction(clear)
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
    
    func confirmToClear(){
        let alert = UIAlertController(title: nil, message: "Confirm to Clear", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "Clear", style: .default, handler: { (action) in
            let videos = self.realm.objects(PlayingVideo.self)
            try! self.realm.write {
              //  self.realm.delete(videos)
                for video in videos {
                    video.isDeleted = true
                }
            }
            self.playingVideos.removeAll()
            self.playingIndex = 0
            self.playerView.loadVideoID("")
             self.tableView.reloadData()
        })
        alert.addAction(cancel)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @objc func accessToParentalView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let parentalVC = storyboard.instantiateViewController(withIdentifier: "MyListsVC") as! MyListsVC
        parentalVC.addBtnEnable = false
        parentalVC.fromMain = true
        navigationController?.pushViewController(parentalVC, animated: true)
    }
    
    //========================================================================
    
    func loadPlayingList(){
        self.playingVideos.removeAll()
        let videos = realm.objects(PlayingVideo.self).sorted(byKeyPath: "title")
        
        Observable.array(from: videos).subscribe(onNext: { (videos) in
            self.playingVideos = videos.filter{ !$0.isDeleted }
            self.tableView.reloadData()
        }).disposed(by: bag)

        
    }
    
    
    func checkFirstTimeUse(){
        if UserDefaults.standard.string(forKey: ALConstants.kPincode) == nil{
            askToSetup()
        } else {
           // print(UserDefaults.standard.string(forKey: ALConstants.kPincode))
           self.pin(.verify)
        }

    }
    func askToSetup(){
        let alert = UIAlertController(title: nil, message: "Seems you haven't set up your parental passcode", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Setup NOW", style: .default) { (action) in
          //  goToSetupView()
            
            self.pin(.create)
        }
        let cancel = UIAlertAction(title: "Mayber later", style: .cancel, handler: nil)
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    

    
    
    // ===============================================================
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playingVideos.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlayinglistCell.identifier, for: indexPath) as! PlayinglistCell
        let playingVideo = playingVideos[indexPath.item]
        cell.videoTitle.text = playingVideo.title
        if playingIndex == indexPath.item {
            cell.playingBtn.setImage(UIImage(named:"playing"), for: .normal)
        } else {
            cell.playingBtn.setImage(UIImage(named:"unplaying"), for: .normal)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = self.playingVideos[indexPath.item].videoId
        print(id)
        self.playingIndex = indexPath.item
        playerView.loadVideoID(id)
        self.autoPlay = false
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            try! self.realm.write {
              //  self.realm.delete(self.playingVideos[indexPath.row])
                self.playingVideos[indexPath.row].isDeleted = true
            }
            self.loadPlayingList()
            
            self.playingIndex = 0
            if self.playingVideos.count > 0 {
                self.playerView.loadVideoID(self.playingVideos[self.playingIndex].videoId)
            } else {
                self.playerView.loadVideoID("")
            }


        }
        delete.backgroundColor = UIColor.red
        return[delete]
    }
    
     func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
     func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.playingVideos[sourceIndexPath.row]
        playingVideos.remove(at: sourceIndexPath.row)
        playingVideos.insert(movedObject, at: destinationIndexPath.row)
        NSLog("%@", "\(sourceIndexPath.row) => \(destinationIndexPath.row) \(playingVideos)")
        // To check for correctness enable: self.tableView.reloadData()
    }

    
    //=========================================================================
    func playerReady(_ videoPlayer: YouTubePlayerView){
        if autoPlay {
            videoPlayer.play()
        }
    }
    

    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState){
        print(playerState)
        if playerState == .Ended {
            if self.playingIndex + 1 < self.playingVideos.count {
                self.playingIndex += 1
                videoPlayer.loadVideoID(playingVideos[self.playingIndex].videoId)
                self.autoPlay = true
                self.tableView.reloadData()
            }
        }
    }
    
}


