//
//  LeftMenuVC.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/7/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import IceCream
import RxRealm
import RxSwift
import RealmSwift
import CloudKit


enum LeftMenu: Int {
    case main = 0
    case myVideo
    case playList
    case channel
    case search
    
}
protocol LeftMenuProtocol: class {
    func changeViewController(_ menu: LeftMenu)
}


class LeftMenuVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MenuCellDelegate {

    var kidsList = [LocalPlayList]()
    let bag = DisposeBag()

    let realm = try! Realm()

    var channels = [LocalChannel]()
    var mainVC: UIViewController!
    var playlistVC: UIViewController!
    var searchVC: UIViewController!
    var myVideoVC: UIViewController!
    var myChannelVC: UIViewController!
    
    var syncLocalChannel: SyncEngine<LocalChannel>?
    var syncLocalPlayList: SyncEngine<LocalPlayList>?
    var syncLocalVideo: SyncEngine<LocalVideo>?
    var syncPlayingVideo: SyncEngine<PlayingVideo>?
    
    
    @IBAction func clickSetting(_ sender: Any) {
      //  changeViewController(LeftMenu.setting)
        isICloudContainerAvailable()
    }
    
    func isICloudContainerAvailable() {
        CKContainer.default().accountStatus { accountStatus, error in
            if accountStatus == .noAccount {
                let alert = UIAlertController(title: "Sign in to iCloud", message: "Please go to Settings to enable your iCloud account to sync your lists", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Got it", style:.default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            } else {
                
                if UserDefaults.standard.bool(forKey: "cloudAvailable") == false {
                    self.syncLocalChannel = SyncEngine<LocalChannel>()
                    self.syncLocalPlayList = SyncEngine<LocalPlayList>()
                    self.syncLocalVideo = SyncEngine<LocalVideo>()
                    self.syncPlayingVideo = SyncEngine<PlayingVideo>()
                }
                
                // Code if user has account here...
                let alert = UIAlertController(title: "Success!", message: "Your lists are kept in sync with iCloud.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style:.default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }

    
    @IBOutlet weak var lockImage: UIImageView!
    var parentMenu = ["Search YouTube","Saved Playlists","Saved Channels","Reset Passcode"]

    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var switchBtn: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    
    var parentalOn: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor.white
        
        tableView.delegate = self
        tableView.dataSource = self

        switchBtn.isOn = false
        switchLabel.text = "Off"
        parentalOn = false
        tableView.register(MenuCell.nib, forCellReuseIdentifier: MenuCell.identifier)
        switchBtn.addTarget(self, action: #selector(toggleSwitch), for: .valueChanged)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        NotificationCenter.default.addObserver(self, selector: #selector(turnOnMenu), name: NSNotification.Name(rawValue:"accessToMenu"), object: nil)
        
        //==================
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let main = storyboard.instantiateViewController(withIdentifier: "MainVC") as! MainVC
        mainVC = UINavigationController(rootViewController: main)
        
        let mylistVC = storyboard.instantiateViewController(withIdentifier: "MyListsVC") as! MyListsVC
        mylistVC.fromLeft = true
        playlistVC = UINavigationController(rootViewController: mylistVC)
        
        let channelVC = storyboard.instantiateViewController(withIdentifier: "MyChannelVC") as! MyChannelVC
        myChannelVC = UINavigationController(rootViewController: channelVC)
        
        let searchYoutube = storyboard.instantiateViewController(withIdentifier: "SearchVC") as! SearchVideosVC
        searchYoutube.fromLeft = true
        searchVC = UINavigationController(rootViewController: searchYoutube)
        
        
    
        
        
        //==================
        
        loadKidsPlaylist()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadMenu), name: NSNotification.Name(rawValue: "reloadMenu"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backToMain), name: NSNotification.Name(rawValue: "backToMain"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let tracker = GAI.sharedInstance().tracker(withTrackingId: TrackingId) else {return}
        tracker.set(kGAIScreenName, value: "LeftMenu")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
    }


    //=====================================================================
    
    @objc func reloadMenu(){
        loadKidsPlaylist()
    }
    
    @objc func toggleSwitch(){
        if switchBtn.isOn {
            if UserDefaults.standard.string(forKey: ALConstants.kPincode) == nil{
                switchLabel.text = "Off"
                switchBtn.setOn(false, animated: false)
                askToSetup()
            } else {
                // print(UserDefaults.standard.string(forKey: ALConstants.kPincode))
                switchLabel.text = "Off"
                switchBtn.setOn(false, animated: false)
                self.pin(.switchOn)
            }

        } else {
            parentalOn = false
            switchLabel.text = "Off"
            switchBtn.setOn(false, animated: false)
            lockImage.image = UIImage(named: "passcode")
            self.changeViewController(LeftMenu.main)
        }
        self.tableView.reloadData()
    }
    
    func askToSetup(){
        let alert = UIAlertController(title: "Welcome!", message: "Seems you haven't set up your parental passcode", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Setup NOW", style: .default) { (action) in
            //  goToSetupView()
            self.pin(.create)
        }
        let cancel = UIAlertAction(title: "Maybe Later :P", style: .cancel) { (action) in
            self.switchBtn.setOn(false, animated: false)
            self.switchLabel.text = "Off"

        }
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func turnOnMenu(){
        parentalOn = true
        switchBtn.setOn(true, animated: true)
        switchLabel.text = "On"
        lockImage.image = UIImage(named: "openlock")
        self.tableView.reloadData()
    }


 //==========================================================
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.parentalOn {
            return 3
        }
        return 2
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 75
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return self.kidsList.count
        }
        
        
        if section == 2 {
            return self.parentMenu.count
        }

        return 1
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 20
        }

        if section == 1 {
            if parentalOn {
                return 40
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Visible Playlists: "
        }

        if section == 2 {
            return "Parental control: "
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view:UIView, forSection: Int) {
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = UIColor.darkGray
        }
    }
//    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
//        if let footer = view as? UITableViewHeaderFooterView {
//            footer.textLabel?.textColor = blueColor
//         //   footer.contentView.backgroundColor = blueColor
//        }
//    }
    
    func hideMenu(_ cell: MenuCell) {
        guard let index = tableView.indexPath(for: cell) else {
            return
        }
        try! realm.write {
            self.kidsList[index.item].isHiden = !self.kidsList[index.item].isHiden
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:"reloadTableData"), object: self)

        loadKidsPlaylist()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: MenuCell.identifier, for: indexPath) as! MenuCell
        cell.delegate = self
        cell.menuName.text = "Playing"
        cell.iconImg.image = UIImage(named: "youtube")
        cell.menuName.textColor = blueColor
        cell.menuName.font = UIFont.boldSystemFont(ofSize:22)
        cell.hideBtn.isHidden = true
        
        if indexPath.section == 1{
            cell.menuName.text = self.kidsList[indexPath.row].title
            cell.menuName.font = UIFont.systemFont(ofSize: 17)
            cell.menuName.textColor = blueColor
            cell.iconImg.image = UIImage(named: "approved")


            if self.parentalOn {
                cell.hideBtn.isHidden = false
            } else {
                cell.hideBtn.isHidden = true
            }
        }
        
        if indexPath.section == 2 {
            cell.menuName.font = UIFont.systemFont(ofSize: 17)
            cell.menuName.textColor = blueColor

            cell.menuName.text = self.parentMenu[indexPath.row]
            cell.hideBtn.isHidden = true
            
            if cell.menuName.text == "Search YouTube" {
                cell.iconImg.image = UIImage(named: "searchyoutube")

            }
            if cell.menuName.text == "Saved Playlists" {
                cell.iconImg.image = UIImage(named: "playlist")
                
            }

            if cell.menuName.text == "Saved Channels" {
                cell.iconImg.image = UIImage(named: "star")
                
            }
            if cell.menuName.text == "Reset Passcode" {
                cell.iconImg.image = UIImage(named: "reset")
                
            }



        }
            return cell
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            self.changeViewController(LeftMenu.main)
                
            
        }
        if indexPath.section == 1 {
            let listId = self.kidsList[indexPath.item].id
         //   print("selected list id: \(listId)")
            let vc = KidsVideosListVC()
            vc.leftMenuDelegate = self
            vc.playlistId = listId

            self.myVideoVC = UINavigationController(rootViewController: vc)
            self.changeViewController(LeftMenu.myVideo)
        }
        
        if indexPath.section == 2 {
            let cell = tableView.cellForRow(at: indexPath) as! MenuCell

            if cell.menuName.text == "Saved Playlists" {
                self.changeViewController(LeftMenu.playList)
                
            }
            
            if cell.menuName.text == "Saved Channels" {
                self.changeViewController(LeftMenu.channel)
                
            }
            
            if cell.menuName.text == "Search YouTube" {
                self.changeViewController(LeftMenu.search)
                
            }
            
            if cell.menuName.text == "Reset Passcode" {
                self.pin(.change)
                
            }
            

        }
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    
    
    //=====================================================================
    func loadKidsPlaylist(){
        print("loadKidsPlaylist called......")
        self.kidsList.removeAll()
        let localList = realm.objects(LocalPlayList.self).filter("isHiden = false")
        
        Observable.array(from: localList).subscribe(onNext: { (localList) in
            /// When data changes in Realm, the following code will be executed
            self.kidsList = localList.filter{ !$0.isDeleted }
            self.tableView.reloadData()
        }).disposed(by: bag)


    }

    

}

extension LeftMenuVC: LeftMenuProtocol{
    
    func changeViewController(_ menu: LeftMenu) {
        print("changing view controller....")
        switch menu {
        case .main:
            self.slideMenuController()?.changeMainViewController(self.mainVC, close: true)
        case .myVideo:
            self.slideMenuController()?.changeMainViewController(self.myVideoVC, close: true)
        case .playList:
            self.slideMenuController()?.changeMainViewController(self.playlistVC, close: true)
        case .search:
            self.slideMenuController()?.changeMainViewController(self.searchVC, close: true)

        case .channel:
            self.slideMenuController()?.changeMainViewController(self.myChannelVC, close: true)

        }
    }
    
    @objc func backToMain(){
        self.slideMenuController()?.changeMainViewController(self.mainVC, close: true)
    }
}
