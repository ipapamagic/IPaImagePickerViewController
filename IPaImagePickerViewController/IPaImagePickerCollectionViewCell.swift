//
//  IPaImagePickerCollectionViewCell.swift
//  IPaImagePickerContentViewController
//
//  Created by IPa Chen on 2016/1/11.
//  Copyright © 2016年 A Magic Studio. All rights reserved.
//

import UIKit

class IPaImagePickerCollectionViewCell: UICollectionViewCell {
    var representedAssetIdentifier:String = ""
    
    lazy var photoImageView = UIImageView()
    lazy var markerLabel = UILabel()
    lazy var highlightView = UIView()
    var _markerNumber:Int = 0
    var markerNumber:Int {
        get {
            return _markerNumber
        }
        set {
            _markerNumber = newValue
            markerLabel.hidden = (_markerNumber <= 0)
            markerLabel.text = "\(_markerNumber)"
            
            
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(photoImageView)
        var viewsDict:[String:UIView] = ["view": photoImageView]
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        markerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(markerLabel)
        viewsDict = ["view": markerLabel]
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view(30)]",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[view(>=30)]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        markerLabel.textColor = UIColor.whiteColor()
        markerLabel.backgroundColor = UIColor(red: 10.0/255.0, green: 138.0/255.0, blue: 246.0/255.0, alpha: 1)
        markerLabel.textAlignment = .Center
        
        contentView.addSubview(highlightView)
        viewsDict = ["view": highlightView]
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
}
