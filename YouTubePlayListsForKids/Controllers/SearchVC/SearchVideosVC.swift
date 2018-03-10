//
//  SearchVideosVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/23/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import GoogleMobileAds



class SearchVideosVC: UIViewController,UITableViewDelegate,UITableViewDataSource, UISearchBarDelegate,GADBannerViewDelegate,UISearchResultsUpdating{
    
    var cellIsEditing = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segment: UISegmentedControl!
    let headerView = CheckboxHeader()
    
    var selectedVideos = [LocalVideo]()
    
    let searchBar = UISearchBar()
    var fromLeft = false
    let realm = try! Realm()
    
    lazy var ad: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ADUNITID
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()


 //   let searchController = UISearchController(searchResultsController: nil)
    

    // let SEARCH_VIDEO: String = "search?part=snippet&maxResults=15&q="
    let VIDEO_TYPE = ["video", "channel","playlist"]
    let BASE_URL: String = "https://www.googleapis.com/youtube/v3/search"

    
    
    var searchResults : [SearchResult] = []
    var selectedCount = 0
    
    var count = 0
    var pageToken = ""
    var searchKey = ""
    
    
    
    @IBAction func selectType(_ sender: Any) {
        if searchBar.text != "" {
            self.searchResults.removeAll()

            let parameters: Parameters = ["part":"snippet",
                                          "maxResults": "30",
                                          "key":API_KEY,
                                          "q":self.searchBar.text!,
                                          "type":VIDEO_TYPE[segment.selectedSegmentIndex]
            ]
            
            getList(parameters: parameters)
        } else {
            self.searchResults.removeAll()
            self.count = 0
            self.tableView.reloadData()

        }
    }


    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchBar.delegate = self
        
        
     //   self.searchBar.text = "Hoffman"
        
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 35)
        headerView.selectBtn.addTarget(self, action: #selector(clickSelect), for: .touchUpInside)
        if headerView.selectBtn.currentTitle == "Select"{
            headerView.cancelBtn.isHidden = true
        }
        headerView.cancelBtn.addTarget(self, action: #selector(cancelSelect), for: .touchUpInside)
        
        self.segment.selectedSegmentIndex = 0
        self.segment.addTarget(self, action: #selector(reload), for: .valueChanged)
        
        self.tableView.register(VideoCell.nib, forCellReuseIdentifier: VideoCell.identifier)

        
       // searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        navigationItem.titleView?.tintColor = UIColor.darkGray
        
        if #available(iOS 11.0, *) {
            searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.estimatedRowHeight = 120
        
        // hide seperate line
   //     tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: 0,height: 0))
        
        
        let request = GADRequest()
        
        request.testDevices = [ kGADSimulatorID,"2077ef9a63d2b398840261c8221a0c9b" ]
        
        ad.load(request)
        
        self.view.addSubview(ad)
        self.view.addConstraintFunc(format: "V:[v0]-0-|", views: ad)
        self.view.addConstraintFunc(format: "H:|-[v0]-|", views: ad)

        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "SearchVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        
        tabBarController?.tabBar.isHidden = false
        print("view willlll appear")
        if fromLeft {
            self.setNavigationBarItem()
            searchBar.frame = CGRect(x: 30, y: 0, width: view.frame.width - 40, height: 44)

        }
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
                        print("nextPageToken: \(json["nextPageToken"])")
                        self.pageToken = json["nextPageToken"] as! String
                    }
                    
                }
                
                let decoder = JSONDecoder()
                
                do {
                    let info = try decoder.decode(Videos.self, from: data)
                    for item in info.items {
                        let result = SearchResult(video:item)
                        self.searchResults.append(result)
                        
                    }
                //    print("++++++++++++++++++++++++\(info.items.count)")
                    self.count = (self.searchResults.count)
                 //   self.tableView.reloadSections([1], with: .none)
                    self.tableView.reloadData()
                    
                    
                } catch {
                    print(error)
                }
                
            })
        // self.items = (self.channelLists?.count)!
        
        
    }
    
    @objc func clickSelect(){
        
        if headerView.selectBtn.currentTitle == "Select" {
            headerView.cancelBtn.isHidden = false
            if self.selectedCount > 0 {
                headerView.selectBtn.setTitle("Done", for: .normal)
            } else {
                headerView.selectBtn.setTitle("", for: .normal)
            }
            
            self.cellIsEditing = true
            self.tableView.reloadData()
         //   self.tableView.setEditing(true, animated: true)

            
        } else if headerView.selectBtn.currentTitle == "Done" {
            showAlert()
        }
    }
    
    func showAlert(){
        // alert
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save to existing list", style: .default, handler: {
            (action) -> Void in
            self.addToExistingList()
        //    self.finishSelect()
            
        } ))
        alert.addAction(UIAlertAction(title: "Save to new list", style: .default, handler:{
            (action) -> Void in
            self.addToNewList("")
        //    self.finishSelect()
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
                    let video = selected[i].video
                    let id = video.id.videoId
                    let title = video.snippet.title
                    print("video title: \(title)")
                    
                    let playingVideo = PlayingVideo(videoId: id!, title: title)
                    self.realm.add(playingVideo, update: true)
                    
                }
            }
        }
        self.finishSelect()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "backToMain"), object: self)
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
                
               // realmTags.append(tag)
            }
            
            let localPlaylist = LocalPlayList(title: name, tag1: tag1, tag2: tag2)
            let id = localPlaylist.id
            
            //getSelectedVideos
            
            var selected = self.searchResults.filter{$0.isSelected==true}
            if selected.count > 0 {
                for i in 0...selected.count - 1 {
                    let video = selected[i].video
                    let id = video.id.videoId
                    let title = video.snippet.title
                    print("video title: \(title)")
                    var selectedVideo = LocalVideo(videoId: id!, videoTitle: title)
                    if let url = video.snippet.thumbnails?.medium.url {
                        selectedVideo = LocalVideo(videoId: id!, playlistId: "", videoTitle: title, videoImg: url)
                    }
                    self.selectedVideos.append(selectedVideo)
                    print(self.selectedVideos.count)
                }
            }
            
            
            
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
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        pop.addAction(action)
        pop.addAction(cancel)
        present(pop, animated: true, completion: nil)
    }
    
    
    func addToExistingList(){
        let existingVC = self.storyboard?.instantiateViewController(withIdentifier: "ExistingListVC") as! ExistingListVC
        var selected = self.searchResults.filter{$0.isSelected==true}
        print(selected.count)
        
        if selected.count > 0 {
            for i in 0...selected.count - 1 {
                let video = selected[i].video
                let id = video.id.videoId
                let title = video.snippet.title
                print("video title: \(title)")
                var selectedVideo = LocalVideo(videoId: id!, videoTitle: title)
                if let url = video.snippet.thumbnails?.medium.url {
                    selectedVideo = LocalVideo(videoId: id!, playlistId: "", videoTitle: title, videoImg: url)
                }
                self.selectedVideos.append(selectedVideo)
                print(self.selectedVideos.count)
                
                
            }
            existingVC.videos = self.selectedVideos
            self.navigationController?.pushViewController(existingVC, animated: false)
            self.finishSelect()
        } else {
            cancelSelect()
        }


    }

    
    func finishSelect(){
        self.headerView.cancelBtn.isHidden = true
        self.headerView.selectBtn.setTitle("Select", for: .normal)
        self.headerView.countLabel.text = ""
        self.cellIsEditing = false
 
        for i in 0...self.searchResults.count - 1 {
            searchResults[i].isSelected = false
        }

        self.selectedCount = 0
        self.tableView.reloadData()
    }
    
    @objc func cancelSelect(){
      //  self.tableView.setEditing(false, animated: true)
        self.cellIsEditing = false
        headerView.cancelBtn.isHidden = true
        headerView.selectBtn.setTitle("Select", for: .normal)
        headerView.countLabel.text = ""
        if self.searchResults.count > 0 {
            
            for i in 0...self.searchResults.count - 1 {
                searchResults[i].isSelected = false
            }
        }
        self.selectedCount = 0
        
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchResults.removeAll()
        self.searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        let parameters: Parameters = ["part":"snippet",
                                      "maxResults": "30",
                                      "key":API_KEY,
                                      "q":self.searchBar.text!,
                                      "type":VIDEO_TYPE[segment.selectedSegmentIndex]
        ]
        
        getList(parameters: parameters)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filterContentForSearchText(searchBar.text!, scope: segment.selectedSegmentIndex)

    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!, scope: segment.selectedSegmentIndex)
    }

    
    
    @objc func reload(){
        print("click segment")
        print(self.selectedCount)
        self.selectedCount = 0
        if self.segment.selectedSegmentIndex == 0 {
            self.headerView.countLabel.text = ""
        }

    }
    
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: segment.selectedSegmentIndex)

    }
    
    func filterContentForSearchText(_ searchText: String, scope: Int) {
        
        let parameters: Parameters = ["part":"snippet",
                                      "maxResults": "30",
                                      "key":API_KEY,
                                      "q":self.searchBar.text!,
                                      "type":VIDEO_TYPE[scope]
        ]
        
        getList(parameters: parameters)
        
    }
    
    

    // ========================================================================

    // MARK: UITableView method implementation
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.segment.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell
            
            cell.setEditingMode(self.cellIsEditing)
            cell.delegate = self
            cell.addDelegate = self
            
            let list = self.searchResults[indexPath.item].video
            //    print(list)
            let url = list.snippet.thumbnails?.medium.url
            cell.videoTitle.text = list.snippet.title
            cell.videoDescription.text = list.snippet.description
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
                let parameters: Parameters = ["part":"snippet",
                                              "maxResults": "30",
                                              "pageToken":self.pageToken,
                                              "key":API_KEY,
                                              "q":searchKey,
                                              "type":VIDEO_TYPE[segment.selectedSegmentIndex]
                ]
                
                getList(parameters: parameters)
            }
            if self.cellIsEditing {
                cell.checkBox.isCheckboxSelected = self.searchResults[indexPath.row].isSelected
                print(cell.checkBox.isCheckboxSelected)
            }
            
            return cell
        } else if self.segment.selectedSegmentIndex == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for:indexPath) as! ChannellistCell
            
            let list = self.searchResults[indexPath.item].video
            let url = list.snippet.thumbnails?.medium.url
            cell.videoTitle.text = list.snippet.title
            cell.videoDescription.text = list.snippet.description
            cell.videoThumbnail.layer.masksToBounds = true
            cell.videoThumbnail.layer.cornerRadius = 45
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
                let parameters: Parameters = ["part":"snippet",
                                              "maxResults": "30",
                                              "pageToken":self.pageToken,
                                              "key":API_KEY,
                                              "q":searchKey,
                                              "type":VIDEO_TYPE[segment.selectedSegmentIndex]
                ]
                
                getList(parameters: parameters)
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for:indexPath) as! PlaylistTableViewCell
            
            let list = self.searchResults[indexPath.item].video
            let url = list.snippet.thumbnails?.medium.url
            cell.videoTitle.text = list.snippet.title
            cell.videoDescription.text = list.snippet.description
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
                let parameters: Parameters = ["part":"snippet",
                                              "maxResults": "30",
                                              "pageToken":self.pageToken,
                                              "key":API_KEY,
                                              "q":searchKey,
                                              "type":VIDEO_TYPE[segment.selectedSegmentIndex]
                ]
                
                getList(parameters: parameters)
            }
            return cell
        }
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(count)
        return count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if segment.selectedSegmentIndex == 0 {
            return UITableViewAutomaticDimension
        }
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if segment.selectedSegmentIndex == 0 {
            if !self.cellIsEditing {
                let item = self.searchResults[indexPath.item].video
                let id = item.id.videoId
                let playerVC = self.storyboard?.instantiateViewController(withIdentifier: "PlayerVC") as! PlayerVC
                playerVC.itemID = id!
                self.navigationController?.pushViewController(playerVC, animated: true)
            }
            
            
        }
        // to channel
        if segment.selectedSegmentIndex == 1 {
            let item = self.searchResults[indexPath.item].video
            let id = item.id.channelId
            let channelVC = self.storyboard?.instantiateViewController(withIdentifier: "ChannelVC") as! ChannelVC
            channelVC.channelId = id!
            channelVC.name = item.snippet.title
            channelVC.desc = item.snippet.description
            if item.snippet.thumbnails != nil {
                channelVC.img = item.snippet.thumbnails!.medium.url
            }
            
            self.navigationController?.pushViewController(channelVC, animated: true)
        }
        
        // segue to playlist
        if segment.selectedSegmentIndex == 2 {
            let item = self.searchResults[indexPath.item].video
            let id = item.id.playlistId
            let title = item.snippet.title
            let description = item.snippet.description
            let playlistVC = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistVC") as! PlayListDetailsVC
            playlistVC.playlistId = id!
            playlistVC.playlistTitle = title
            playlistVC.playlistDescription = description
            self.navigationController?.pushViewController(playlistVC, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
       // print(indexPath.row)
       // print(self.tableView.indexPathsForSelectedRows)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.segment.selectedSegmentIndex == 1 || self.segment.selectedSegmentIndex == 2 {
            return 0
        } else {
            if self.count == 0 {
                return 0
            }
            return 35
            
        }
        
    }
    
    
    
    
}

extension SearchVideosVC: VideoCellAddDelegate{
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

extension SearchVideosVC: CellCheckBoxCheckDelegate{
    
    // delegate function
    func checkBoxDidSelect(_ sender: VideoCell) {
        guard let tapIndexPath = tableView.indexPath(for: sender) else {
            return
        }
        print("checkbox", sender,tapIndexPath)
        
        print("check box is selected...")
        
        self.searchResults[tapIndexPath.item].isSelected = true
        self.selectedCount += 1
        if self.selectedCount > 0 {
            headerView.selectBtn.setTitle("Done", for: .normal)
        } else {
            headerView.selectBtn.setTitle("", for: .normal)
        }
        self.headerView.countLabel.text = String(self.selectedCount)
        
    }
    
    func checkBoxDidDeSelect(_ sender: VideoCell) {
        guard let tapIndexPath = tableView.indexPath(for: sender) else {
            return
        }
        // print("checkbox", sender,tapIndexPath)
        print("check box is deselected...")
        self.selectedCount -= 1
        self.searchResults[tapIndexPath.item].isSelected = false
        self.headerView.countLabel.text = String(self.selectedCount)
        if self.selectedCount > 0 {
            headerView.selectBtn.setTitle("Done", for: .normal)
        } else {
            headerView.selectBtn.setTitle("", for: .normal)
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Dequeue with the reuse identifier
        
        return headerView
    }
    
  //  https://www.appcoda.com/google-admob-ios-swift/
}

