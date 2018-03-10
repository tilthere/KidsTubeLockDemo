//
//  MyChannelSVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/12/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import IceCream
import RxRealm
import RxSwift
import GoogleMobileAds



class MyChannelVC: UIViewController,GADBannerViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let bag = DisposeBag()
    
    let realm = try! Realm()
    
    lazy var ad: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = ADUNITID
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    var channels = [LocalChannel]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
     //   self.tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(ChannelCell.nib, forCellReuseIdentifier: ChannelCell.identifier)
        
    //    tableView.estimatedRowHeight = 120
        
        // hide seperate line
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: 0,height: 0))
        
        loadChannels()
        
        let request = GADRequest()
        
        request.testDevices = [ kGADSimulatorID,"2077ef9a63d2b398840261c8221a0c9b" ]
        
        ad.load(request)
        self.view.addSubview(ad)
        self.view.addConstraintFunc(format: "V:[v0]-0-|", views: ad)
        self.view.addConstraintFunc(format: "H:|-[v0]-|", views: ad)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

    }
    
    
    func loadChannels(){
        self.channels.removeAll()
        let myChannels = realm.objects(LocalChannel.self)
        
        Observable.array(from: myChannels).subscribe(onNext: { (myChannels) in
            self.channels = myChannels.filter{ !$0.isDeleted }
            self.tableView.reloadData()
        }).disposed(by: bag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNavigationBarItem()
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "MyChannelVC")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
     //   self.loadChannels()
    }


}

extension MyChannelVC: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return self.channels.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for:indexPath) as! ChannelCell
        
        let channel = self.channels[indexPath.item]
        let url = channel.img
        cell.videoTitle.text = channel.name
        cell.videoDescription.text = channel.desc
        cell.videoThumbnail.layer.masksToBounds = true
        cell.videoThumbnail.layer.cornerRadius = 45
        if url != "" {
            Alamofire.request(url).responseData { response in
                if let data = response.result.value {
                    cell.videoThumbnail.image = UIImage(data: data)
                }
            }
        }
        
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.channels[indexPath.item]
        let id = item.id
        let channelVC = self.storyboard?.instantiateViewController(withIdentifier: "ChannelVC") as! ChannelVC
        channelVC.channelId = id
        channelVC.name = item.name
        channelVC.desc = item.desc
        if item.img != "" {
            channelVC.img = item.img
        }
        
        self.navigationController?.pushViewController(channelVC, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            try! self.realm.write {
              //  self.realm.delete(self.channels[indexPath.row])
                self.channels[indexPath.row].isDeleted = true
            }
            self.loadChannels()
            
        }
        delete.backgroundColor = UIColor.red
        return[delete]
    }
    
    
}















