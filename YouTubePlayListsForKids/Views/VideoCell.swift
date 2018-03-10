//
//  VideoCell.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/25/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
protocol CellCheckBoxCheckDelegate {
    func checkBoxDidSelect(_ sender: VideoCell)
    func checkBoxDidDeSelect(_ sender: VideoCell)

}
protocol VideoCellAddDelegate {
    func addVideo(_ cell: VideoCell)
}

class VideoCell: UITableViewCell,CheckboxDelegate {

    @IBOutlet weak var checkBoxWidth: NSLayoutConstraint!
    @IBOutlet weak var checkLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoThumbnail: UIImageView!
    @IBOutlet weak var checkBox: CCheckbox!
    
    @IBAction func addSingleVideo(_ sender: Any) {
        addDelegate.addVideo(self)
    }
    
    @IBOutlet weak var videoTitle: UILabel!
    @IBOutlet weak var videoDescription: UILabel!
    
    @IBOutlet weak var addButton: UIButton!
    
    var isCellSelected: Bool!
    var delegate: CellCheckBoxCheckDelegate?
    var addDelegate: VideoCellAddDelegate!
    
    @IBAction func tapCheckbox(_ sender: CCheckbox) {
        if !self.checkBox.isCheckboxSelected {
            delegate?.checkBoxDidSelect(self)
        } else {
            delegate?.checkBoxDidDeSelect(self)
        }
    }
    

    
    func setEditingMode(_ editing: Bool) {
        if editing {
            self.checkBox.isHidden = false
            self.leadingConstraint.constant = 10
            self.checkLeadingConstraint.constant = 8
            self.checkBoxWidth.constant = 25
            
        } else {
            self.leadingConstraint.constant = 0
            self.checkLeadingConstraint.constant = 0
            self.checkBox.isHidden = true
            self.checkBoxWidth.constant = 0
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        checkBox.delegate = self
        // Initialization code
        self.leadingConstraint.constant = 0
        self.checkLeadingConstraint.constant = 0
        self.checkBox.isHidden = true
        self.checkBoxWidth.constant = 0
        
        if self.checkBox.isCheckboxSelected {
            self.isCellSelected = true
        } else {
            self.isCellSelected = false
        }
        
    }
    


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    
    func didSelect(_ checkbox: CCheckbox) {
        print("didSelect")
        self.isCellSelected = true
    }
    
    func didDeselect(_ checkbox: CCheckbox) {
        print("didDeselect")
        self.isCellSelected = false
    }
    
}
