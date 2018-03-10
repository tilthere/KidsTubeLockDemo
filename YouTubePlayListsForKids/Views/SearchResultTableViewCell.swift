//
//  SearchResultTableViewCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/24/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var videoTitle: UILabel!
    @IBOutlet weak var videoDescription: UILabel!
    @IBOutlet weak var videoThumbnail: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
}
