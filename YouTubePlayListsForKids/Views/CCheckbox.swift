//
//  CheckBoxView.swift
//  YouTubePlayListsForKids
//
//  Created by Xiaomei Huang on 2/2/18.
//  Copyright © 2018 Xiaomei Huang. All rights reserved.
//

import UIKit

/**
 CheckboxDelegate protocol to be confirmed
 when you need callbacks for checkboc status change
 **/
@objc protocol CheckboxDelegate {
    func didSelect(_ checkbox: CCheckbox)
    func didDeselect(_ checkbox: CCheckbox)
}

/**
 CCheckbox is a custom UIButton class
 which represents custom checkbox with
 custom images
 **/

@IBDesignable class CCheckbox: UIButton {
    
    //MARK:- Variables
    @IBInspectable var normalImage: UIImage? = UIImage(named: "normalImage")
    @IBInspectable var selectedImage: UIImage? = UIImage(named: "selectedImage")
    
    /// when set this variable checkbox status changed
    @IBInspectable var isCheckboxSelected: Bool = false {
        didSet {
            self.imageView?.contentMode = .scaleAspectFit
            self.changeStatus()
        }
    }
    
    open weak var delegate: CheckboxDelegate?
    var animation: UIViewAnimationOptions = .transitionCrossDissolve
    
    //MARK:- Customize Button Properties
    override func layoutSubviews() {
        super.layoutSubviews()
        initComponent()
    }
    
    private func initComponent () {
        //Check Button Type Value
        if self.buttonType != .system
            && self.buttonType != .custom {
            fatalError("Button Type Error. Please Make Button Type System or Custom")
        }
        self.setTitle("", for: .normal)
        self.addTarget(self,
                       action: #selector(CCheckbox.didTouchUpInside(_:)),
                       for: .touchUpInside)
        
        //Styling UIView
        self.backgroundColor = UIColor.clear
    }
    
    //MARK:- Checkbox Status
    private func changeStatus() {
        if isCheckboxSelected {
            UIView.transition(with: self.imageView!,
                              duration:0.5,
                              options: animation,
                              animations: { self.setImage(self.selectedImage, for: .normal) },
                              completion: nil)
            
        } else {
            UIView.transition(with: self.imageView!,
                              duration:0.5,
                              options: animation,
                              animations: { self.setImage(self.normalImage, for: .normal) },
                              completion: nil)
        }
        
    }
    
    // MARK: IBActions
    @objc func didTouchUpInside(_ sender: UIButton) {
        self.isCheckboxSelected = !self.isCheckboxSelected
        
        if isCheckboxSelected && delegate != nil {
            delegate?.didSelect(self)
        } else if delegate != nil {
            delegate?.didDeselect(self)
        }
    }
}

