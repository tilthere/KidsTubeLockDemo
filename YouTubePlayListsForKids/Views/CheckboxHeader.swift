//
//  CheckboxHeader.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/2/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit


@IBDesignable class CheckboxHeader: UIView {
    
    var view: UIView!

    
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var selectAllBtn: UIButton!
    
    @IBOutlet weak var countLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
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
        let nib = UINib(nibName: "CheckboxHeader", bundle: bundle)
        let view = nib.instantiate(withOwner: self,options:nil)[0] as! UIView
        
        return view
    }
    

    
    
    
    
    
    
    
    
}
