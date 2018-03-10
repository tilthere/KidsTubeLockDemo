//
//  TagsView.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/1/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit
import TagListView


@IBDesignable class TagsView: UIView {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var tagsList: TagListView!
    @IBOutlet weak var closeBtn: UIButton!
    
    var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        closeBtn.tintColor = blueColor
        tagsList.textFont = UIFont.systemFont(ofSize: 18)
        tagsList.borderColor = blueColor
        tagsList.backgroundColor = UIColor.clear
        tagsList.textColor = blueColor

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init has not been implemented")
    }
    
    func setupViews(){
        view = loadViewFromNib()
        
        view.frame = bounds
       // view.backgroundColor = UIColor.blue
        
        addSubview(view)
        
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "TagsView", bundle: bundle)
        let view = nib.instantiate(withOwner: self,options:nil)[0] as! UIView
        
        return view
    }
    
}
