//
//  IPaImagePickerViewController.swift
//  IPaImagePickerViewController
//
//  Created by IPa Chen on 2016/1/11.
//  Copyright © 2016年 A Magic Studio. All rights reserved.
//

import UIKit
import Photos
protocol IPaImagePickerControllerDelegate {
    func onIPaImagePicker(picker:IPaImagePickerViewController,pickImages:[PHAsset])
    func onIPaImagePickerDidCancel(picker:IPaImagePickerViewController)
}
class IPaImagePickerViewController: UINavigationController {
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
    func cancelPicker() {
        guard let imagePickerDelegate = imagePickerDelegate else {
            return
        }
        imagePickerDelegate.onIPaImagePickerDidCancel(self)
    }
    func pickImages(images:[PHAsset]) {
        guard let imagePickerDelegate = imagePickerDelegate else {
            return
        }
        imagePickerDelegate.onIPaImagePicker(self, pickImages: images)
    }
    
}
