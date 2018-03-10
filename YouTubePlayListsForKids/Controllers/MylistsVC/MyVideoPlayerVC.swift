//
//  MyVideoPlayerVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/6/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import YouTubePlayer

class MyVideoPlayerVC: UIViewController,YouTubePlayerDelegate{
    var tableView = UITableView()
    var playerView = YouTubePlayerView()
    var playinglist = [PlayingVideo]()
    var playingIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width*9/16)
        

        
        self.view.backgroundColor = UIColor.white
        playerView.delegate = self

        // remove suggestions
        playerView.playerVars = ["rel" : "0" as AnyObject, "showinfo": "0" as AnyObject, "playsinline": "1" as AnyObject]
        
        tableView.frame = CGRect(x: 0, y: self.view.frame.width*9/16, width: self.view.frame.width, height: self.view.frame.height - self.view.frame.width*9/16)
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(PlayinglistCell.nib, forCellReuseIdentifier: PlayinglistCell.identifier)
        
        self.view.addSubview(playerView)
        self.view.addSubview(tableView)
        
        playerView.loadVideoID(playinglist[playingIndex].videoId)
 




    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        tabBarController?.tabBar.isHidden = true
        
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "MyVideoPlayerVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
    }


    func playerReady(_ videoPlayer: YouTubePlayerView){
        videoPlayer.play()
    }
    
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState){
        print(playerState)
        if playerState == .Ended {
            if self.playingIndex + 1 < self.playinglist.count {
                self.playingIndex += 1
                videoPlayer.loadVideoID(playinglist[self.playingIndex].videoId)
                self.tableView.reloadData()
            }
        }
    }
    
    
    //===================================================================================
    
}

extension MyVideoPlayerVC: UITableViewDelegate, UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playinglist.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlayinglistCell.identifier, for: indexPath) as! PlayinglistCell
        let playingVideo = playinglist[indexPath.item]
        cell.videoTitle.text = playingVideo.title
        if playingIndex == indexPath.item {
            cell.playingBtn.setImage(UIImage(named:"playing"), for: .normal)
        } else {
            cell.playingBtn.setImage(UIImage(named:"unplaying"), for: .normal)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = self.playinglist[indexPath.item].videoId
        print("-------id:\(id)")
        self.playingIndex = indexPath.item
        playerView.loadVideoID(id)
        self.tableView.reloadData()
    }
    

}
