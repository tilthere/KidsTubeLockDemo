//
//  MenuCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/7/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
protocol MenuCellDelegate {
    func hideMenu(_ cell: MenuCell)
}

class MenuCell: UITableViewCell {
    
    @IBOutlet weak var iconImg: UIImageView!
    var delegate: MenuCellDelegate!
    @IBOutlet weak var menuName: UILabel!
    @IBAction func clickToHide(_ sender: Any) {
        delegate.hideMenu(self)
    }
    
    @IBOutlet weak var hideBtn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
