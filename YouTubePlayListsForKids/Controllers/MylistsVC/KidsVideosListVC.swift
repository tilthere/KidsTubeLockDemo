//
//  KidsVideosListVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/10/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import RealmSwift
import IceCream
import RxRealm
import RxSwift
import Alamofire
import GoogleMobileAds

//import SQLite

class KidsVideosListVC: UIViewController,UITableViewDataSource, UITableViewDelegate,CellCheckBoxCheckDelegate,GADBannerViewDelegate {
    
    let bag = DisposeBag()
    
    let realm = try! Realm()
    
    var tableView = UITableView()
    let headerView = CheckboxHeader()

    var myVideos = [LocalVideo]()
    var playlistId = ""
    var playingVideos = [PlayingVideo]()
    
    var cellIsEditing = false
    var selectedCount = 0
    
    weak var leftMenuDelegate : LeftMenuProtocol?
    
    lazy var ad: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ADUNITID
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
   //     let selectBtn = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectToPlay))
        
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 35)
        headerView.selectBtn.addTarget(self, action: #selector(selectToPlay), for: .touchUpInside)
        headerView.selectAllBtn.addTarget(self, action: #selector(selectAllVideos), for: .touchUpInside)
        headerView.selectAllBtn.isHidden = true
        
        headerView.cancelBtn.isHidden = true
        
        
        
//        if headerView.selectBtn.currentTitle == "Select"{
//            headerView.cancelBtn.isHidden = true
//        }
        headerView.cancelBtn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
//        let cancelBtn = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAction))
//
//        let selectAllBtn = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(selectAllVideos))
        
  //      navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Play", style: .plain, target: self, action: #selector(queueToPlay))
        

        
        
        self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - 60)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        
        self.view.addSubview(tableView)
        
        tableView.register(VideoCell.nib, forCellReuseIdentifier: VideoCell.identifier)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange , object: nil)
        
        
        // Do any additional setup after loading the view.
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
        tracker.set(kGAIScreenName, value: "KidsVideoListVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])

        self.setNavigationBarItem()
        loadMyVideos()
        if self.myVideos.count < 1 {
            headerView.selectBtn.isHidden = true
        } else {
            headerView.selectBtn.isHidden = false
        }

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
        
        let localVideos = realm.objects(LocalVideo.self).filter("playlistId == %@",(self.playlistId)).sorted(byKeyPath: "videoTitle")
        
        
        Observable.array(from: localVideos).subscribe(onNext: { (localVideos) in
            let items = localVideos.filter{ !$0.isDeleted }
            self.myVideos = items
            
            
            for item in items {
                let playVideo = PlayingVideo(videoId: item.videoId, title: item.videoTitle)
                self.playingVideos.append(playVideo)
                
            }
            
            if self.myVideos.count < 1 {
                self.navigationItem.rightBarButtonItem?.title = ""
            }
            
            self.tableView.reloadData()
        }).disposed(by: self.bag)

    }
    
    //=============================================================================
    @objc func selectToPlay(){
        
        if headerView.selectBtn.currentTitle == "Select" {
            headerView.cancelBtn.isHidden = false
            headerView.selectAllBtn.isHidden = false
            headerView.selectAllBtn.setTitle("Select All", for: .normal)
            if self.selectedCount > 0 {
                headerView.selectBtn.setTitle("Play", for: .normal)
            } else {
                headerView.selectBtn.setTitle("", for: .normal)
            }
            
            self.cellIsEditing = true
            self.tableView.reloadData()
            //   self.tableView.setEditing(true, animated: true)
            
            
        } else if headerView.selectBtn.currentTitle == "Play" {
            self.cellIsEditing = false
            headerView.cancelBtn.isHidden = true
            headerView.selectAllBtn.isHidden = true
            queueToPlay()
        }
      //  resetToUnselected()

        self.tableView.reloadData()
    }
    
    @objc func queueToPlay(){
        
        
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
        
        //  let myvideoPlayer = MyVideoPlayerVC()
        /*
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
            self.dismissAlert()
        }
        */
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
        self.dismissAlert()
        self.resetToUnselected()
        leftMenuDelegate?.changeViewController(LeftMenu.main)

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
        headerView.selectBtn.setTitle("Play", for: .normal)
        headerView.cancelBtn.isHidden = false
        self.tableView.reloadData()
    }
    
    @objc func cancelAction(){
        headerView.selectBtn.setTitle("Select", for: .normal)
        headerView.selectAllBtn.isHidden = true
        headerView.cancelBtn.isHidden = true
        self.cellIsEditing = false
        resetToUnselected()
        self.tableView.reloadData()
    }
    func resetToUnselected(){
        if self.playingVideos.count > 1 {
            for i in 0...self.playingVideos.count - 1 {
                self.playingVideos[i].isSelected = false
            }
        }
        self.selectedCount = 0
    }
    
    //======================================================================================
    func checkBoxDidSelect(_ sender: VideoCell) {
        guard let index = tableView.indexPath(for: sender) else {
            return
        }
        self.playingVideos[index.item].isSelected = true
        self.selectedCount += 1
        if self.selectedCount > 0 {
            headerView.selectBtn.setTitle("Play", for: .normal)
        } else {
            headerView.selectBtn.setTitle("", for: .normal)
        }
    }
    
    func checkBoxDidDeSelect(_ sender: VideoCell) {
        guard let index = tableView.indexPath(for: sender) else {
            return
        }
        self.playingVideos[index.item].isSelected = false
        self.selectedCount -= 1
        if self.selectedCount > 0 {
            headerView.selectBtn.setTitle("Play", for: .normal)
        } else {
            headerView.selectBtn.setTitle("", for: .normal)
        }
    }
    
    
    
    
    //======================================================================================
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myVideos.count
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell
        cell.setEditingMode(self.cellIsEditing)
        cell.delegate = self
        if self.cellIsEditing {
            cell.checkBox.isCheckboxSelected = self.playingVideos[indexPath.row].isSelected
           // print(cell.checkBox.isCheckboxSelected)
        }
        
        let myVideo = self.myVideos[indexPath.item]
       // print(myVideo.compoundKey)
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
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerVC") as! PlayerVC
            playerVC.itemID = self.myVideos[indexPath.row].videoId
            playerVC.fromMyList = true
            self.navigationController?.pushViewController(playerVC, animated: true)
        }
    }
        
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Dequeue with the reuse identifier
        
        return headerView
    }
    
    
}
