//
//  ListHeaderCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/25/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
class ListHeaderCell: UITableViewCell {
    
    @IBOutlet weak var playlistTitle: UILabel!
    @IBOutlet weak var playlistDescription: UILabel!
    
    @IBOutlet weak var videoCount: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    
    
}
