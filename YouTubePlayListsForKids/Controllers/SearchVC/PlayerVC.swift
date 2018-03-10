//
//  PlayerVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/25/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import YouTubePlayer
import Alamofire
import RealmSwift
import IceCream
import RxRealm
import RxSwift
import GoogleMobileAds


class PlayerVC: UIViewController,YouTubePlayerDelegate,GADBannerViewDelegate {
    let bag = DisposeBag()
    
    let realm = try! Realm()

    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var viewContainer: YouTubePlayerView!
    var itemID: String!
   // var videoPlayer: YouTubePlayerView!
    var fromMyList = false
    let BASE_URL = "https://www.googleapis.com/youtube/v3/videos"
    var localVideo = LocalVideo()
    
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var videoTitle: UILabel!
    
    @IBOutlet weak var videoDescription: UILabel!
    
    lazy var ad: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ADUNITID
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
   //     videoPlayer = YouTubePlayerView(frame: self.viewContainer.frame)
   //     self.viewContainer.addSubview(videoPlayer)
        viewContainer.delegate = self
        // remove suggestions
        viewContainer.playerVars = ["rel" : "0" as AnyObject, "showinfo": "0" as AnyObject, "playsinline": "1" as AnyObject]
        viewContainer.loadVideoID(itemID)


     //   viewContainer.play()
        
        if fromMyList {
            self.addButton.isHidden = true
        } else {
            self.addButton.isHidden = false
        }
        
        addButton.addTarget(self, action: #selector(addToList), for: .touchUpInside)

        addButton.layer.cornerRadius = 20
        addButton.layer.masksToBounds = true
        print("video id: ==============\(itemID)")
        let parameters: Parameters = ["part":"snippet,contentDetails",
                                      "key":API_KEY,
                                      "id":self.itemID
        ]
        
        getList(parameters: parameters)
        
        
        let request = GADRequest()
        
        request.testDevices = [ kGADSimulatorID,"2077ef9a63d2b398840261c8221a0c9b" ]
        
        ad.load(request)
        
        self.view.addSubview(ad)
        self.view.addConstraintFunc(format: "V:[v0]-0-|", views: ad)
        self.view.addConstraintFunc(format: "H:|-[v0]-|", views: ad)


    }
    
    
    
    @objc func addToList(){
        showAlert()
    }
    
    func showAlert(){
        // alert
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save to existing list", style: .default, handler: {
            (action) -> Void in
            self.addToExistingList()
            
        } ))
        alert.addAction(UIAlertAction(title: "Save to new list", style: .default, handler:{
            (action) -> Void in
            self.addToNewList("")
        } ))
        
        alert.addAction(UIAlertAction(title: "Add to Playing", style: .default, handler:{
            (action) -> Void in
            self.addToPlay()
            //    self.finishSelect()
        } ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popoverController = alert.popoverPresentationController {
            // popoverController.barButtonItem = sender as? UIBarButtonItem
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            
        }
        present(alert, animated:true, completion: nil)
    }
    
    func addToPlay(){
        //getSelectedVideos

        
        let playingVideo = PlayingVideo(videoId: self.localVideo.videoId, title: self.localVideo.videoTitle)
        try! self.realm.write {
            self.realm.add(playingVideo, update: true)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "backToMain"), object: self)
    }


    func addToExistingList(){
        
        let alert = UIAlertController(title: nil, message: "Add to list", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let localList = realm.objects(LocalPlayList.self).filter("isDeleted != true")                                                        .sorted(byKeyPath: "title")
        

        
        for list in localList {
            alert.addAction(UIAlertAction(title:"\(list.title)", style: .default, handler: { (action) in
                print(list.title)
                let saveVideo = LocalVideo()
                saveVideo.playlistId = list.id
                saveVideo.videoId = self.localVideo.videoId
                saveVideo.videoImg = self.localVideo.videoImg
                saveVideo.videoTitle = self.localVideo.videoTitle
                
                try! self.realm.write {
                    self.realm.add(saveVideo, update: true)
                    self.dismissAlert()
                }
                
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
    
    
    func addToNewList(_ text: String){
        print("create new list")
        let pop = UIAlertController(title: nil, message: "Create new list", preferredStyle: .alert)
        pop.addTextField { (tf) in
            tf.placeholder = "Title"
            tf.text = text
        }
        pop.addTextField { (tf) in
            tf.placeholder = "Tag_1"
        }
        pop.addTextField { (tf) in
            tf.placeholder = "Tag_2"
        }
        
        let action = UIAlertAction(title: "OK", style: .default) { (_) in
            guard let name = pop.textFields![0].text?.trimmingCharacters(in: .whitespacesAndNewlines)
                else {return}
            //  var tags = [String]()
           // let realmTags = List<RealmString>()
            var tag1 = ""
            var tag2 = ""
            
            if pop.textFields![1].text != nil {
             //   let tag = RealmString()
                tag1 = pop.textFields![1].text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
             //   realmTags.append(tag)
            }
            if pop.textFields![2].text != nil {
             //   let tag = RealmString()
                tag2 = pop.textFields![2].text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
             //   realmTags.append(tag)
            }
            
            let localPlaylist = LocalPlayList(title: name, tag1: tag1, tag2: tag2)
            let id = localPlaylist.id
            let saveVideo = LocalVideo()
            saveVideo.playlistId = id
            saveVideo.videoId = self.localVideo.videoId
            saveVideo.videoImg = self.localVideo.videoImg
            saveVideo.videoTitle = self.localVideo.videoTitle

  
            try! self.realm.write {
                self.realm.add(localPlaylist, update: true)
                self.realm.add(saveVideo, update: true)
                self.dismissAlert()
            }
            
            //            NotificationCenter.default.post(name: NSNotification.Name(rawValue:"reloadTableData"), object: self)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        pop.addAction(action)
        pop.addAction(cancel)
        present(pop, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)
     //   videoPlayer.stop()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        tabBarController?.tabBar.isHidden = true
        
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "PlayerVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        
    }
    
    func getList(parameters:Parameters){
        
        Alamofire.request(BASE_URL,method: .get,parameters: parameters,encoding: URLEncoding.default)
            .responseJSON(completionHandler: {response in
                guard let data = response.data else {
                    print("didn't get object as JSON from API")
                    print("Error: \(String(describing: response.result.error))")
                    return
                }

                let decoder = JSONDecoder()
                
                do {
                    let info = try decoder.decode(VideoDetails.self, from: data)
                    let item = info.items[0]
                    self.videoTitle.text = item.snippet.title
                    self.videoDescription.text = item.snippet.description
                    if item.contentDetails.duration == "PT0S" {
                        self.timeLabel.text = "LIVE"
                    } else {
                        self.timeLabel.text = self.getYoutubeFormattedDuration(timeString: item.contentDetails.duration)
                    }
                    var url = ""
                    if item.snippet.thumbnails?.medium.url != nil {
                        url = item.snippet.thumbnails!.medium.url
                    }
                    self.localVideo = LocalVideo(videoId: self.itemID, playlistId: "", videoTitle: item.snippet.title, videoImg: url)
                    // PT0S == "LIVE"
                    print("duration:=====================================\(item.contentDetails.duration)")
                 //   print(self.getYoutubeFormattedDuration(timeString: item.contentDetails.duration))
                    
                } catch {
                    print(error)
                }
                
            })
        // self.items = (self.channelLists?.count)!
        
        
    }
    
    func getYoutubeFormattedDuration(timeString: String) -> String {
        
        let formattedDuration = timeString.replacingOccurrences(of: "PT", with: "").replacingOccurrences(of: "H", with:":").replacingOccurrences(of: "M", with: ":").replacingOccurrences(of: "S", with: "")
        
        let components = formattedDuration.components(separatedBy: ":")
        var duration = ""
        for component in components {
            duration = duration.characters.count > 0 ? duration + ":" : duration
            if component.characters.count < 2 {
                duration += "0" + component
                continue
            }
            duration += component
        }
        
        return duration
        
    }
    
}

