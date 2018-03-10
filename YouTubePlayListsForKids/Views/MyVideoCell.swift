//
//  MyVideoCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/4/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit

class MyVideoCell: UITableViewCell {
    
    @IBOutlet weak var videoThumbnail: UIImageView!
    
    @IBOutlet weak var videoTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
