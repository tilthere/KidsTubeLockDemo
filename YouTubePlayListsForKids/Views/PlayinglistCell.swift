//
//  PlayinglistCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/6/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit

class PlayinglistCell: UITableViewCell {
    @IBOutlet weak var playingBtn: UIButton!
    @IBOutlet weak var videoTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
     //   backgroundColor = UIColor.clear
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
