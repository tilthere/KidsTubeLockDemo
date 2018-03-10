//
//  ChannelVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/25/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import IceCream
import RxRealm
import RxSwift
import GoogleMobileAds



class ChannelVC: UIViewController,UITableViewDelegate, UITableViewDataSource,GADBannerViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    let bag = DisposeBag()
    
    let realm = try! Realm()

    
    let BASE_URL: String = "https://www.googleapis.com/youtube/v3/playlists"

    var searchResults : [ChannelPlayList] = []
    var channelId = ""
    var name = ""
    var desc = ""
    var img = ""
    
    var count = 0
    var pageToken = ""
    
    lazy var ad: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ADUNITID
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        tableView.register(PlaylistCell.nib, forCellReuseIdentifier: PlaylistCell.identifier)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"star"), style: .plain, target: self, action: #selector(clickToSaveChanel))
        
        if realm.objects(LocalChannel.self).filter("id = %@ AND isDeleted != true",self.channelId).count > 0 {
            navigationItem.rightBarButtonItem?.tintColor = UIColor.yellow
        }
        
        print("CHANNEL ID: \(channelId)")
        
        let parameters: Parameters = ["part":"snippet,contentDetails",
                                      "maxResults": "30",
                                      "key":API_KEY,
                                      "channelId":channelId
                                    ]
        
        getList(parameters: parameters)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: 0,height: 0))


        // Do any additional setup after loading the view.
        let request = GADRequest()
        
       request.testDevices = [ kGADSimulatorID,"2077ef9a63d2b398840261c8221a0c9b" ]
        
        ad.load(request)

    }
    
    //  https://www.appcoda.com/google-admob-ios-swift/
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Banner loaded successfully")
        tableView.tableFooterView?.frame = bannerView.frame
        tableView.tableFooterView = bannerView
        
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Fail to receive ads")
        print(error)
    }
    
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        print("Banner loaded successfully")
        
        // Reposition the banner ad to create a slide down effect
        let translateTransform = CGAffineTransform(translationX: 0, y: -bannerView.bounds.size.height)
        bannerView.transform = translateTransform
        
        UIView.animate(withDuration: 0.5) {
            bannerView.transform = CGAffineTransform.identity
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return ad
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return ad.frame.height
    }

    
    // ================================================================
    @objc func clickToSaveChanel(){
        if realm.objects(LocalChannel.self).filter("id = %@ AND isDeleted != true",self.channelId).count > 0 {
            let alert = UIAlertController(title: nil, message: "Unsave this Channel?", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Unsave", style: .default) { (action) in
                let channels = self.realm.objects(LocalChannel.self).filter("id = %@ AND isDeleted != true",self.channelId)
                try! self.realm.write {
                 //   realm.delete(channel)
                    for channel in channels {
                        channel.isDeleted = true
                    }
                    
                }
                self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(ok)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
            
        } else {
            
            
            let alert = UIAlertController(title: nil, message: "Save this Channel?", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Save", style: .default) { (action) in
                let channel = LocalChannel()
                print(self.channelId,self.name,self.desc)
                channel.id = self.channelId
                channel.name = self.name
                channel.img = self.img
                channel.desc = self.desc
                
                try! self.realm.write {
                    self.realm.add(channel, update: true)
                    self.dismissAlert()
                }
                self.navigationItem.rightBarButtonItem?.tintColor = UIColor.yellow
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(ok)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        tabBarController?.tabBar.isHidden = true
        
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "ChannelVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistCell.identifier, for:indexPath) as! PlaylistCell
        
        let list = self.searchResults[indexPath.item]
        let url = list.snippet.thumbnails?.medium.url
        cell.videoTitle.text = list.snippet.title
        cell.videoDescription.text = list.snippet.description
        cell.videoCount.text = String(list.contentDetails.itemCount)
        if url != nil {
            Alamofire.request(url!).responseData { response in
                if let data = response.result.value {
                    cell.videoThumbnail.image = UIImage(data: data)
                }
            }
        }

        // User scrolled to last element (i.e. 5th video), so load more results
        if (indexPath.row >= (self.searchResults.count) - 1) && (self.pageToken != "")
        {
            print("indexPath.row = \(indexPath.row)")
            let parameters: Parameters = ["part":"snippet,contentDetails",
                                          "maxResults": "30",
                                          "pageToken":self.pageToken,
                                          "key":API_KEY,
                                          "channelId":channelId
            ]
            
            getList(parameters: parameters)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.searchResults[indexPath.item]
        let id = item.id
        let title = item.snippet.title
        let description = item.snippet.description
        let playlistVC = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistVC") as! PlayListDetailsVC
        playlistVC.playlistId = id
        playlistVC.playlistTitle = title
        playlistVC.playlistDescription = description
        self.navigationController?.pushViewController(playlistVC, animated: true)
    }


    func getList(parameters:Parameters){
        self.pageToken = ""
        
        Alamofire.request(BASE_URL,method: .get,parameters: parameters,encoding: URLEncoding.default)
            .responseJSON(completionHandler: {response in
                guard let data = response.data else {
                    print("didn't get object as JSON from API")
                    print("Error: \(String(describing: response.result.error))")
                    return
                }
                
                if let json = response.result.value as? Dictionary<String, AnyObject> {
                    // print("JSON: \(json)")
                    if json["nextPageToken"] != nil {
                      //  print("nextPageToken: \(json["nextPageToken"])")
                        self.pageToken = json["nextPageToken"] as! String
                    }
                    
                }
                
                let decoder = JSONDecoder()
                
                do {
                    let info = try decoder.decode(ChannelPlayLists.self, from: data)
                    for item in info.items {
                        self.searchResults.append(item)
                        
                    }
                    self.count = (self.searchResults.count)
                    //   self.tableView.reloadSections([1], with: .none)
                    self.tableView.reloadData()
                    
                    
                } catch {
                    print(error)
                }
                
            })
        
        
    }


}
