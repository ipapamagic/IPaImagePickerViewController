//
//  IPaImagePickerController.swift
//  IPaImagePickerController
//
//  Created by IPa Chen on 2016/1/11.
//  Copyright © 2016年 A Magic Studio. All rights reserved.
//

import UIKit
import Photos
protocol IPaImagePickerControllerDelegate {
    func onIPaImagePicker(_ picker:IPaImagePickerController,pickImages:[PHAsset])
    func onIPaImagePickerDidCancel(_ picker:IPaImagePickerController)
}
class IPaImagePickerController: UINavigationController {
    var imagePickerDelegate: IPaImagePickerControllerDelegate?
    var imagePickNumber:Int {
        get {
            guard let viewController = self.viewControllers.first as? IPaImagePickerContentViewController else {
                return 0
            }
            return viewController.imagePickNumber
            
        }
        set {
            guard let viewController = self.viewControllers.first as? IPaImagePickerContentViewController else {
                return
            }
            viewController.imagePickNumber = newValue
        }
    }
    init () {
        let rootViewController = IPaImagePickerContentViewController()
        
        super.init(rootViewController: rootViewController)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName:  nibNameOrNil, bundle: nibBundleOrNil)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func cancelPicker() {
        guard let imagePickerDelegate = imagePickerDelegate else {
            return
        }
        imagePickerDelegate.onIPaImagePickerDidCancel(self)
    }
    func pickImages(_ images:[PHAsset]) {
        guard let imagePickerDelegate = imagePickerDelegate else {
            return
        }
        imagePickerDelegate.onIPaImagePicker(self, pickImages: images)
    }
    
}
