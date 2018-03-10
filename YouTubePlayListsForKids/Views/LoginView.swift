//
//  LoginView.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 1/30/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//
/*
import UIKit
import GoogleSignIn

@IBDesignable class LoginView: UIView{
    
     var view: UIView!

    @IBOutlet weak var googleBTN: GIDSignInButton!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        googleBTN.style = .wide
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init has not been implemented")
    }
    
    func setupViews(){
        view = loadViewFromNib()
        
        view.frame = bounds
        //view.backgroundColor = UIColor.blue
        
        addSubview(view)
        
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "LoginView", bundle: bundle)
        let view = nib.instantiate(withOwner: self,options:nil)[0] as! UIView
        
        return view
    }
    

    
}

 */
