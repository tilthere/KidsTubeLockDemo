//
//  TagHeaderCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/31/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import TagListView


class TagHeaderCell: UITableViewCell {
    
    @IBOutlet weak var tagView: TagListView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    
}
