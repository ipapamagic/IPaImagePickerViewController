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
    
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var markerLabel: UILabel!
    @IBOutlet var highlightView: UIView!
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
    
    
}
