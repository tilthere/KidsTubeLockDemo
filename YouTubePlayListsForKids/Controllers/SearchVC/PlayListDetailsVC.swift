//
//  PlayListDetailsVC.swift
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


class PlayListDetailsVC: UIViewController,UITableViewDelegate,UITableViewDataSource,GADBannerViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    lazy var ad: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ADUNITID
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    let bag = DisposeBag()
    
    let realm = try! Realm()
    
    var cellIsEditing = false
    var selectedCount = 0
    
    var searchResults = [PlayListSearchResult]()
    var selectedVideos = [LocalVideo]()
    var playlistId = ""
    let BASE_URL: String = "https://www.googleapis.com/youtube/v3/playlistItems"

    var playlistDescription = ""
    var playlistTitle = ""
    var playlistCount = ""
    
    var count = 0
    var pageToken = ""
    var checkboxHeader = CheckboxHeader()

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
                
        print("*************this is playlist detail vc\(playlistId)")
        navigationItem.rightBarButtonItem =  UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectToSave))
        let backBtn = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(cancelSelect))
        let selectAllBtn = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(selectAllVideos))
        
        navigationItem.leftBarButtonItems = [backBtn,selectAllBtn]
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        tableView.estimatedSectionHeaderHeight = 120
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.estimatedRowHeight = 120
        
        self.tableView.register(VideoCell.nib, forCellReuseIdentifier: VideoCell.identifier)
        self.tableView.register(ListHeaderCell.nib, forCellReuseIdentifier: ListHeaderCell.identifier)


        
        let para: Parameters = ["part":"snippet,contentDetails",
                                      "maxResults": "30",
                                      "key":API_KEY,
                                      "playlistId":playlistId
        ]
        
        getList(parameters: para)
        
        let request = GADRequest()
        
        request.testDevices = [ kGADSimulatorID,"2077ef9a63d2b398840261c8221a0c9b" ]
        
        ad.load(request)
        
        self.view.addSubview(ad)
        self.view.addConstraintFunc(format: "V:[v0]-0-|", views: ad)
        self.view.addConstraintFunc(format: "H:|-[v0]-|", views: ad)
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "PlayListDetailsVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
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


    //=============================================================================
    
    @objc func selectToSave(){
        if navigationItem.rightBarButtonItem?.title == "Select"{
            if self.selectedCount > 0 {
                navigationItem.rightBarButtonItem?.title = "Done"
            } else {
                navigationItem.rightBarButtonItem?.title = ""
            }
            
            navigationItem.leftBarButtonItems![0].title = "Cancel"
            if self.searchResults.count < 30 {
                navigationItem.leftBarButtonItems![1].title = "Select All"
            }
            self.cellIsEditing = true
            self.tableView.reloadData()
        }else if navigationItem.rightBarButtonItem?.title == "Done"{
            navigationItem.rightBarButtonItem?.title = "Select"
            navigationItem.leftBarButtonItems![0].title = "Back"
            navigationItem.leftBarButtonItems![1].title = ""
            showAlert()
        }
    }

    
    func showAlert(){
        // alert
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save to existing list", style: .default, handler: {
            (action) -> Void in
            self.addToExistingList()
            self.finishSelect()
            
        } ))
        alert.addAction(UIAlertAction(title: "Save to new list", style: .default, handler:{
            (action) -> Void in
            self.addToNewList(self.playlistTitle)
        } ))
        
        alert.addAction(UIAlertAction(title: "Play", style: .default, handler:{
            (action) -> Void in
            self.addToPlay()
            //    self.finishSelect()
        } ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action) -> Void in
            self.finishSelect()
        }))
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
        
        var selected = self.searchResults.filter{$0.isSelected==true}
        if selected.count > 0 {
            try! self.realm.write {
                for i in 0...selected.count - 1 {
                    let id = selected[i].playlistItem.snippet.resourceId.videoId
                    let title = selected[i].playlistItem.snippet.title
                    print("video title: \(title)")
                    
                    let playingVideo = PlayingVideo(videoId: id, title: title)
                    self.realm.add(playingVideo, update: true)
                    
                }
            }
        }
        self.finishSelect()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "backToMain"), object: self)
    }
    
    
    func getSelectedVideos(){
        var selected = self.searchResults.filter{$0.isSelected==true}
        print(selected.count)
        
        if selected.count > 0 {
            for i in 0...selected.count - 1 {
                let video = selected[i].playlistItem
                let id = video.snippet.resourceId.videoId
                let title = video.snippet.title
                print("video title: \(title)")
                var selectedVideo = LocalVideo(videoId: id, videoTitle: title)
                if let url = video.snippet.thumbnails?.medium.url {
                    selectedVideo = LocalVideo(videoId: id, playlistId: "", videoTitle: title, videoImg: url)
                }
                self.selectedVideos.append(selectedVideo)
                print(self.selectedVideos.count)
                
            }

        }
    }
    @objc func selectAllVideos(){
        let count = self.searchResults.count
        self.selectedCount = count
        if count > 0 {
            navigationItem.rightBarButtonItem?.title = "Done"
            for i in 0...count - 1 {
                self.searchResults[i].isSelected = true
            }
        }
        self.tableView.reloadData()
    }
    
    func addToExistingList(){
        let existingVC = self.storyboard?.instantiateViewController(withIdentifier: "ExistingListVC") as! ExistingListVC
            getSelectedVideos()
            existingVC.videos = self.selectedVideos
            self.navigationController?.pushViewController(existingVC, animated: false)
            finishSelect()
    }
    
    
    func finishSelect(){
        navigationItem.rightBarButtonItem?.title = "Select"
        navigationItem.leftBarButtonItem?.title = "Back"
        //  self.headerView.countLabel.text = ""
        self.cellIsEditing = false
        for i in 0...self.searchResults.count - 1 {
            searchResults[i].isSelected = false
        }
        
        self.selectedCount = 0
        self.tableView.reloadData()
    }
    
    @objc func cancelSelect(){
        if navigationItem.leftBarButtonItem?.title == "Back" {
            _ = navigationController?.popViewController(animated: false)
        } else {
            self.cellIsEditing = false
            navigationItem.rightBarButtonItem?.title = "Select"

            navigationItem.leftBarButtonItems![0].title = "Back"
            navigationItem.leftBarButtonItems![1].title = ""

            self.selectedCount = 0
            self.tableView.reloadData()
            if self.searchResults.count > 0 {
                
                for i in 0...self.searchResults.count - 1 {
                    searchResults[i].isSelected = false
                }
            }
        }

        //  self.tableView.setEditing(false, animated: true)

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
              //  let tag = RealmString()
                tag2 = pop.textFields![2].text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
              //  realmTags.append(tag)
            }
            
            let localPlaylist = LocalPlayList(title: name, tag1: tag1, tag2: tag2)
            let id = localPlaylist.id
            
            self.getSelectedVideos()
            
            print("localPlaylist.id: ----\(id)")
            print("self.selectedVideos ----\(self.selectedVideos)")
            
            
            try! self.realm.write {
                self.realm.add(localPlaylist, update: true)
                for item in self.selectedVideos {
                    let video = LocalVideo(videoId: item.videoId, playlistId: id, videoTitle: item.videoTitle, videoImg: item.videoImg)
                    self.realm.add(video, update: true)
                }
            }
            self.finishSelect()
            self.dismissAlert()

//            NotificationCenter.default.post(name: NSNotification.Name(rawValue:"reloadTableData"), object: self)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        pop.addAction(action)
        pop.addAction(cancel)
        present(pop, animated: true, completion: nil)
    }
    
    
    
    
    //==========================================================================
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Dequeue with the reuse identifier
        let cell = self.tableView.dequeueReusableCell(withIdentifier: ListHeaderCell.identifier) as! ListHeaderCell
        cell.playlistTitle.text = playlistTitle
        cell.playlistDescription.text = playlistDescription
        cell.videoCount.text = playlistCount
        return cell.contentView
    }
    
    
 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell
        
        let list = self.searchResults[indexPath.item].playlistItem
        print(list)
        let url = list.snippet.thumbnails?.medium.url
        cell.videoTitle.text = list.snippet.title
        cell.videoDescription.text = list.snippet.description
        cell.setEditingMode(self.cellIsEditing)
        cell.delegate = self
        cell.addDelegate = self
        
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
                                          "playlistId":playlistId
            ]
            
            getList(parameters: parameters)
        }
        
        if self.cellIsEditing {
            cell.checkBox.isCheckboxSelected = self.searchResults[indexPath.row].isSelected
            print(cell.checkBox.isCheckboxSelected)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.cellIsEditing == false {

            let item = self.searchResults[indexPath.item].playlistItem
            let id = item.snippet.resourceId.videoId
            let playerVC = self.storyboard?.instantiateViewController(withIdentifier: "PlayerVC") as! PlayerVC
            playerVC.itemID = id
            self.navigationController?.pushViewController(playerVC, animated: true)
        }
    
    }
    
    
   //===============================================================================
    func getList(parameters:Parameters){
        self.pageToken = ""
        
        Alamofire.request(BASE_URL,method: .get,parameters: parameters,encoding: URLEncoding.default)
            .responseJSON(completionHandler: {response in
                guard let data = response.data else {
                    print("!!!!!!!!!!!didn't get object as JSON from API")
                    print("!!!!!!!!!!!Error: \(String(describing: response.result.error))")
                    return
                }
                
                if let json = response.result.value as? Dictionary<String, AnyObject> {
                    // print("JSON: \(json)")
                    if json["nextPageToken"] != nil {
                        print("nextPageToken: \(json["nextPageToken"])")
                        self.pageToken = json["nextPageToken"] as! String
                    }
                    
                }
                
                let decoder = JSONDecoder()
                
                do {
                    let info = try decoder.decode(PlayList.self, from: data)
                    self.playlistCount = String(info.pageInfo.totalResults) + " Videos"
                    for item in info.items {
                        
                        let result = PlayListSearchResult(playlistItem: item)
                    
                        self.searchResults.append(result)
                        
                    }
                    self.count = (self.searchResults.count)
                    //   self.tableView.reloadSections([1], with: .none)
                    self.tableView.reloadData()
                    
                    
                } catch {
                    print(error)
                }
                
            })
        // self.items = (self.channelLists?.count)!
        
        
    }
    


}

extension PlayListDetailsVC: CellCheckBoxCheckDelegate{
    // delegate function
    func checkBoxDidSelect(_ sender: VideoCell) {
        guard let tapIndexPath = tableView.indexPath(for: sender) else {
            return
        }
      //  print("checkbox", sender,tapIndexPath)
        
        print("check box is selected...")
        
        self.searchResults[tapIndexPath.item].isSelected = true
        self.selectedCount += 1
        if self.selectedCount > 0 {
            navigationItem.rightBarButtonItem?.title = "Done"
        }
    }
    
    func checkBoxDidDeSelect(_ sender: VideoCell) {
        guard let tapIndexPath = tableView.indexPath(for: sender) else {
            return
        }
        // print("checkbox", sender,tapIndexPath)
        print("check box is deselected...")
        self.selectedCount -= 1
        self.searchResults[tapIndexPath.item].isSelected = false
        if self.selectedCount < 1 {
            navigationItem.rightBarButtonItem?.title = ""
        }
    }
    
}


extension PlayListDetailsVC: VideoCellAddDelegate{
    func addVideo(_ cell: VideoCell) {
        print("add video.....")
        if !self.cellIsEditing {
            guard let index = tableView.indexPath(for: cell) else {
                return
            }
            self.searchResults[index.item].isSelected = true
            showAlert()
        }
    }
    
    
}


