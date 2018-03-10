//
//  MyListsCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/31/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import TagListView

protocol MylistCellDelegate {
    func setHide(_ cell: MyListsCell)
}

class MyListsCell: UITableViewCell {
    var delegate: MylistCellDelegate!
    @IBOutlet weak var cellView: UIView!
    
    @IBOutlet weak var listTitle: UILabel!
    
    @IBOutlet weak var playlistTag: TagListView!
    
    @IBOutlet weak var hideBtn: UIButton!
    
    @IBAction func clickHide(_ sender: Any) {
        delegate.setHide(self)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cellView.layer.cornerRadius = 5
       // cellView.backgroundColor = UIColor.groupTableViewBackground
       // playlistTag.alignment = .left
        cellView.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        cellView.layer.borderWidth = 2
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
}
