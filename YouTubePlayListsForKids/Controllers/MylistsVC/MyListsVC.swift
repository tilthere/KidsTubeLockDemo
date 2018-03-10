//
//  MyListsVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/31/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
//import SQLite
import TagListView
import RealmSwift
import IceCream
import RxRealm
import RxSwift
import GoogleMobileAds

class MyListsVC: UIViewController,UITableViewDataSource,UITableViewDelegate,TagListViewDelegate, MylistCellDelegate,GADBannerViewDelegate {
    
    let bag = DisposeBag()
    
    let realm = try! Realm()

    lazy var ad: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ADUNITID
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    @IBOutlet weak var tagsView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var tagsList: TagListView!
    @IBOutlet weak var closeBtn: UIButton!
    var count = 0
//    var tableView = UITableView()
    var myLists = [LocalPlayList]()
    var allLists = [LocalPlayList]()

    @IBOutlet weak var tagsViewHeight: NSLayoutConstraint!
    var tags = Set<Tag>()
//    var tagsView = TagsView()
    var filters = [String]()
    
    var tapOn = false
    var addBtnEnable = true
    var fromLeft = false
    var fromMain = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTagsView()
        
//        self.tagsView = TagsView()
//        self.tableView = UITableView()
//
//        self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
        self.tagsView.isHidden = true
        self.tagsViewHeight.constant = 0
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
//        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension
//        tableView.estimatedSectionHeaderHeight = 180
        
        tableView.estimatedRowHeight = 90
        
        tableView.register(MyListsCell.nib, forCellReuseIdentifier: MyListsCell.identifier)
        tableView.register(TagHeaderCell.nib, forCellReuseIdentifier: TagHeaderCell.identifier)

 //       self.view.addSubview(tableView)
 //       self.view.addConstraintFunc(format: "H:|-0-[v0]-0-|", views: tableView)
 //       self.view.addConstraintFunc(format: "H:|-0-[v0]-0-|", views: tableView)

        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData(notification:)), name: NSNotification.Name(rawValue:"reloadTableData"), object: nil)
        let editImage = UIImage(named: "add")!
        let searchImage = UIImage(named: "tags")!
        
        let editButton   = UIBarButtonItem(image: editImage,  style: .plain, target: self, action: #selector(didTapEditButton))
        let searchButton = UIBarButtonItem(image: searchImage,  style: .plain, target: self, action: #selector(didTapSearchButton))
        
        navigationItem.rightBarButtonItems = [editButton, searchButton]

        
        if !addBtnEnable {
            navigationItem.rightBarButtonItems?[0].isEnabled = false
            navigationItem.rightBarButtonItems?[0].image = nil
            
        }
        
        loadPlaylists()
        loadTags()
        
 //       tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: 0,height: 0))
        self.tableView.separatorColor = UIColor.clear
        
//        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange , object: nil)
        
        let request = GADRequest()
        
        request.testDevices = [ kGADSimulatorID,"2077ef9a63d2b398840261c8221a0c9b" ]
        
        ad.load(request)
        
        self.view.addSubview(ad)
        self.view.addConstraintFunc(format: "V:[v0]-0-|", views: ad)
        self.view.addConstraintFunc(format: "H:|-[v0]-|", views: ad)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))


    }
    
    func setupTagsView(){
        closeBtn.tintColor = UIColor.gray
        tagsList.textFont = UIFont.systemFont(ofSize: 18)
        tagsList.borderColor = blueColor
        tagsList.backgroundColor = UIColor.clear
        tagsList.textColor = blueColor

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "MyListsVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        
        loadPlaylists()
        loadTags()
        if fromLeft {
            self.setNavigationBarItem()
        }
    }
    
    @objc func reloadTableData(notification:NSNotification){
        loadTags()
        loadPlaylists()
        self.tableView.reloadData()
    }
    
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    

    
    @objc func didTapEditButton(){
        print("add playlist")
        // insert table
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Search YouTube", style: .default, handler: {
            (action) -> Void in
            let searchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchVC") as! SearchVideosVC
            self.navigationController?.pushViewController(searchVC, animated: false)
        } ))
        alert.addAction(UIAlertAction(title: "Create new list", style: .default, handler:{
            (action) -> Void in
            self.createNewList(text: "")
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
    
    @objc func didTapSearchButton(){
        self.tapOn = true
        self.tagsViewHeight.constant = 150
        self.tagsView.isHidden = false
//        self.tagsView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 150)
//        self.tableView.frame = CGRect(x: 0, y: 150, width: self.view.bounds.width, height: self.view.bounds.height-150)
//        self.view.addSubview(self.tagsView)
        self.closeBtn.addTarget(self, action: #selector(closeTags), for: .touchUpInside)
    }
    
    @objc func closeTags(){
        self.tapOn = false
        
//        self.tagsView.removeFromSuperview()
//        self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        self.tagsViewHeight.constant = 0
        self.tagsView.isHidden = true
        self.filters.removeAll()
        self.myLists = allLists
        loadTags()
        self.tableView.reloadData()
    }
    
//    @objc func orientationChanged(){
//        if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)){
//            if tapOn {
//                self.tagsView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 150)
//                self.tableView.frame = CGRect(x: 0, y: 150, width: self.view.bounds.width, height: self.view.bounds.height-150)
//            }else {
//                self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
//            }
//        }
//        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)){
//            if tapOn {
//                self.tagsView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 150)
//                self.tableView.frame = CGRect(x: 0, y: 150, width: self.view.bounds.width, height: self.view.bounds.height-150)
//            }else {
//                self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
//            }
//        }
//    }
//

    
    @objc func loadPlaylists(){
        self.allLists.removeAll()
        self.myLists.removeAll()
        
        let localPlaylist = realm.objects(LocalPlayList.self).sorted(byKeyPath: "title")
        
        Observable.array(from: localPlaylist).subscribe(onNext: { (localPlaylist) in

            self.allLists = localPlaylist.filter{ !$0.isDeleted }
            self.myLists = self.allLists
            self.tableView.reloadData()
            
        }).disposed(by: bag)
        
    }
    
    func loadTags(){
        self.tags.removeAll()
        
        let localList = realm.objects(LocalPlayList.self).filter("isDeleted != true")
        
        for item in localList {
            if item.getTags().count > 0 {
                for i in item.getTags() {
                    if i != "" {
                        let tag = Tag(name: i)
                        self.tags.insert(tag)
                    }

                }
            }

            
        }
        
        self.tagsList.removeAllTags()
        for item in self.tags {
            let tag = self.tagsList.addTag(item.name)
            tag.onTap = { tagView in
                print(item.name)
                let selected = item.isSelected!
                item.isSelected = !selected
                print(item.isSelected)
                if item.isSelected {
                    //
                    tagView.tagBackgroundColor = blueColor
                    tagView.textColor = UIColor.white
                    self.filters.append(item.name)
                    self.filterLists(filters: self.filters)
                } else {
                    tagView.borderColor = blueColor
                    tagView.tagBackgroundColor = UIColor.clear
                    tagView.textColor = blueColor
                    self.filters.remove(at: self.filters.index(of: item.name)!)
                    self.filterLists(filters: self.filters)
                    
                }
            }
        }
        
    }
    
    func filterLists(filters: [String]) {
        if filters.count == 0 {
            self.myLists = self.allLists
            self.tableView.reloadData()
            return
        } else {
            self.myLists.removeAll()
            myLists = allLists
            
            myLists = myLists.filter { $0.getTags().contains(where: { filters.contains($0) }) }

            
            self.tableView.reloadData()
        }
    }
    

    //=============================================================================
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myLists.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func setHide(_ cell: MyListsCell) {
        guard let index = tableView.indexPath(for: cell) else {
            return
        }
        try! realm.write {
            self.myLists[index.item].isHiden = !self.myLists[index.item].isHiden
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadMenu"), object: self)
        self.tableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyListsCell.identifier, for: indexPath) as! MyListsCell
        cell.delegate = self
        let mylist = myLists[indexPath.row]
        if mylist.isHiden {
            cell.hideBtn.setTitle("Hiding", for: .normal)
            cell.cellView.alpha = 0.5
        } else {
            cell.hideBtn.setTitle("Showing", for: .normal)
            cell.cellView.alpha = 1.0
            
        }
        
        cell.listTitle.text = "● \(mylist.title)"
        
        
        cell.playlistTag.removeAllTags()
        if mylist.getTags().count != 0 {
            var tags = [String]()
            for item in mylist.getTags() {
                tags.append(item)
            }
            cell.playlistTag.addTags(tags)
        }
        
        
        cell.playlistTag.alignment = .left
        cell.playlistTag.textFont = UIFont.systemFont(ofSize: 15)
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //    let cell = tableView.cellForRow(at: indexPath) as! MyListsCell
        let listId = self.myLists[indexPath.item].id
        print("selected list id: \(listId)")
        let myVideosVC = MyVideosListVC()
        myVideosVC.playlistId = listId
        myVideosVC.fromMain = fromMain
        self.navigationController?.pushViewController(myVideosVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.showAlert(indexPath)
        }
        let change = UITableViewRowAction(style: .normal, title: "Modify") { (action, index) in
            self.showModifyAlert(indexPath)
        }
        
        delete.backgroundColor = UIColor.red
        change.backgroundColor = blueColor
        return[delete,change]
    }
    
    //========================================================================

    func showModifyAlert(_ indexPath: IndexPath){
        let pop = UIAlertController(title: nil, message: "Modify list name/tags?", preferredStyle: .alert)
        let listInfo = self.myLists[indexPath.item]
//        var tags = [String]()
//        for item in listInfo.getTags() {
//            tags.append(item)
//        }
        
        
        pop.addTextField { (tf) in
            tf.placeholder = "Title"
            tf.text = listInfo.title
        }
        pop.addTextField { (tf) in
            tf.placeholder = "Tag_1"
            tf.text = listInfo.tag1
            
        }
        pop.addTextField { (tf) in
            tf.placeholder = "Tag_2"
            tf.text = listInfo.tag2

        }
        
        let action = UIAlertAction(title: "OK", style: .default) { (_) in
            guard let name = pop.textFields![0].text?.trimmingCharacters(in: .whitespacesAndNewlines)
                else {return}
            //  var tags = [String]()
           // let realmTags = List<RealmString>()
            let id = listInfo.id
            var tag1 = ""
            var tag2 = ""
            
            if pop.textFields![1].text != nil {
            //    let tag = RealmString()
                tag1 = pop.textFields![1].text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
            //    realmTags.append(tag)
            }
            if pop.textFields![2].text != nil {
            //    let tag = RealmString()
                tag2 = pop.textFields![2].text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
             //   realmTags.append(tag)
            }
            let modified = LocalPlayList()
            modified.id = id
            modified.title = name
            modified.tag1 = tag1
            modified.tag2 = tag2
            try! self.realm.write {
                self.realm.add(modified, update: true)
                self.dismissAlert()
            }
            
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue:"reloadTableData"), object: self)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        pop.addAction(action)
        pop.addAction(cancel)
        present(pop, animated: true, completion: nil)

    }
    
    
    
    func showAlert(_ indexPath: IndexPath){
        let alert = UIAlertController(title: nil, message: "Confirm to delete", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "Delete", style: .default, handler: { (action) in
            let id = self.myLists[indexPath.row].id
            let videos = self.realm.objects(LocalVideo.self).filter("playlistId = %@",id)
            var v = [LocalVideo]()
            Observable.array(from: videos).subscribe(onNext: { (videos) in
                v = videos.filter{ !$0.isDeleted }
                self.tableView.reloadData()
            }).disposed(by: self.bag)
            
            let count = v.count
            if count > 0 {
                self.showNoEmptyAlert(indexPath, count)
            } else {
                try! self.realm.write {
                  //  self.realm.delete(self.myLists[indexPath.row])
                    self.myLists[indexPath.row].isDeleted = true
                }
                //    self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.loadPlaylists()
                self.loadTags()
            }
        })
        alert.addAction(cancel)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showNoEmptyAlert(_ indexPath: IndexPath, _ count: Int){
        let alert = UIAlertController(title: "List NOT empty", message: "There're \(count) videos in the list", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "Delete the whole list", style: .default, handler: { (action) in
            print("deleting videos in the list.....")
            let id = self.myLists[indexPath.row].id
            let videos = self.realm.objects(LocalVideo.self).filter("playlistId = %@",id)
            var v = [LocalVideo]()

            Observable.array(from: videos).subscribe(onNext: { (videos) in
                v = videos.filter{ !$0.isDeleted }
                self.tableView.reloadData()
            }).disposed(by: self.bag)
            
            try! self.realm.write {
             //   self.realm.delete(videos)
             //   realm.delete(self.myLists[indexPath.row])
                for item in v {
                    item.isDeleted = true
                }
                self.myLists[indexPath.row].isDeleted = true
            }
            self.loadPlaylists()
            self.loadTags()
        })
        alert.addAction(cancel)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)

    }
    
    
    
}
