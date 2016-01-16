//
//  IPaImagePickerContentViewController.swift
//  IPaImagePickerContentViewController
//
//  Created by IPa Chen on 2016/1/10.
//  Copyright © 2016年 A Magic Studio. All rights reserved.
//

import UIKit
import Photos

class IPaImagePickerContentViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,PHPhotoLibraryChangeObserver {
    
    lazy var contentCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    lazy var photoLibrary = PHPhotoLibrary.sharedPhotoLibrary()
    lazy var currentAssetResult:PHFetchResult = {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssetsWithOptions(allPhotosOptions)
        
    }()
    lazy var imageManager = PHCachingImageManager()
    lazy var photoCellItemSize = CGSizeZero
    var previousPreheatRect = CGRectZero
    var imagePickNumber:Int = 0
    var selectedPHAsset = [PHAsset]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "onConfirm:")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "onCancel:")
        

        view.addSubview(contentCollectionView)
        let viewsDict = ["view": contentCollectionView]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        
        contentCollectionView.registerClass(IPaImagePickerCollectionViewCell.self, forCellWithReuseIdentifier: "photoCell")
        
        // Store the PHFetchResult objects and localized titles for each section.

        photoLibrary.registerChangeObserver(self)
        
        // Do any additional setup after loading the view.
    }
    deinit{
        photoLibrary.unregisterChangeObserver(self)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        refreshPhotoCellItemSize()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
      
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onConfirm(sender: AnyObject) {
        guard let navigationController = navigationController as?    IPaImagePickerViewController else {
            return
        }

//        
//        let selectedImages:[PHAsset] = selectedIndexPaths.map({
//            indexPath in
//            var asset:PHAsset
//            if currentAssetResult == allPhotosAssetResult {
//                
//                asset = currentAssetResult[indexPath.item - 1] as! PHAsset
//            }
//            else {
//                asset = currentAssetResult[indexPath.item] as! PHAsset
//            }
//            return asset
//        })
        

        
        navigationController.pickImages(selectedPHAsset)
        
    }
    @IBAction func onCancel(sender: AnyObject) {
        guard let navigationController = navigationController as?    IPaImagePickerViewController else {
            return
        }
        navigationController.cancelPicker()
        
    }
    func refreshPhotoCellItemSize() {
        let width = (view.bounds.width - 20.0 ) / 3.0
        photoCellItemSize = CGSize(width: width, height: width)
    }
    
    
    func getIndexPaths(inRect:CGRect) -> [NSIndexPath] {
        guard let attributes = contentCollectionView.collectionViewLayout.layoutAttributesForElementsInRect(inRect) where attributes.count > 0 else {
            return []
        }
        var indexPaths = [NSIndexPath]()
        for layoutAttribute in attributes {
            indexPaths.append(layoutAttribute.indexPath)
        }
        return indexPaths
    }
    //MARK: Asset Caching
    
    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRectZero
    }
    func updateCachedAssets() {
        guard let _ = view.window where isViewLoaded() else {
            return
        }
    
        // The preheat window is twice the height of the visible rect.
        var preheatRect = contentCollectionView.bounds
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * preheatRect.height)
    
        /*
        Check if the collection view is showing an area that is significantly
        different to the last preheated area.
        */
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > contentCollectionView.bounds.height / 3.0 {
    
            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [NSIndexPath]()
            var removedIndexPaths = [NSIndexPath]()
            computeDifference(previousPreheatRect, newRect: preheatRect, removedHandler: {
                removedRect in
                    let indexPaths = self.getIndexPaths(removedRect)
                    removedIndexPaths.appendContentsOf(indexPaths)

                }, addedHandler: {
                    addedRect in
                    let indexPaths = self.getIndexPaths(addedRect)
                    addedIndexPaths.appendContentsOf(indexPaths)
            })
            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths)

            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths)

        // Update the assets the PHCachingImageManager is caching.
            imageManager.startCachingImagesForAssets(assetsToStartCaching, targetSize: photoCellItemSize, contentMode: .AspectFill, options: nil)
            imageManager.stopCachingImagesForAssets(assetsToStopCaching, targetSize: photoCellItemSize, contentMode: .AspectFill, options: nil)


        // Store the preheat rect to compare against in the future.
            previousPreheatRect = preheatRect
        }
    }
    func computeDifference(oldRect:CGRect,newRect:CGRect,removedHandler:((CGRect) -> Void),addedHandler:((CGRect) -> Void)) {
        
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.width, height: newMaxY - oldMaxY)
                addedHandler(rectToAdd)
            }
            
            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y:newMinY, width:newRect.width, height:oldMinY - newMinY)
                addedHandler(rectToAdd)
            }
    
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x:newRect.origin.x, y:newMaxY, width:newRect.width, height:(oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
    
            if oldMinY < newMinY {
                let rectToRemove = CGRect(x:newRect.origin.x, y:oldMinY, width:newRect.width, height:(newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        }
        else {
            addedHandler(newRect);
            removedHandler(oldRect);
        }
    }
    
    func assetsAtIndexPaths(indexPaths:[NSIndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 {
            return []
        }
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            assets.append(currentAssetResult[indexPath.item] as! PHAsset)
        }
    
        return assets;
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK:PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange)
    {
      
        // Check if there are changes to the assets we are showing.
        guard let collectionChanges = changeInstance.changeDetailsForFetchResult(currentAssetResult) else {
            return
        }
        
        /*
        Change notifications may be made on a background queue. Re-dispatch to the
        main queue before acting on the change as we'll be updating the UI.
        */
        dispatch_async(dispatch_get_main_queue(), {
            // Get the new fetch result.
            self.currentAssetResult = collectionChanges.fetchResultAfterChanges
          
            
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                self.contentCollectionView.reloadData()
            }
            else {
            
                /*
                Tell the collection view to animate insertions and deletions if we
                have incremental diffs.
                */
                self.contentCollectionView.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes where removedIndexes.count > 0{
                        let removedIndexPaths = removedIndexes.map({
                            index in
                            return NSIndexPath(forItem: index, inSection: 0)
                        })
                        self.contentCollectionView.deleteItemsAtIndexPaths(removedIndexPaths)
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes where insertedIndexes.count > 0 {
                        let insertedIndexPaths = insertedIndexes.map({
                            index in
                            return NSIndexPath(forItem: index, inSection: 0)
                        })
                        self.contentCollectionView.insertItemsAtIndexPaths(insertedIndexPaths)
                    }
                    
                    if let changedIndexes = collectionChanges.changedIndexes where changedIndexes.count > 0{
                        let changedIndexPaths = changedIndexes.map({
                            index in
                            return NSIndexPath(forItem: index, inSection: 0)
                        })
                        self.contentCollectionView.reloadItemsAtIndexPaths(changedIndexPaths)
                    }
                }, completion: nil)
            }
            self.resetCachedAssets()
        });

    }
    //MARK:UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return currentAssetResult.count
    }
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let asset = currentAssetResult[indexPath.item] as! PHAsset

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! IPaImagePickerCollectionViewCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        imageManager.requestImageForAsset(asset, targetSize: photoCellItemSize, contentMode: .AspectFill, options: nil, resultHandler: {
            resultImage,info in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.photoImageView.image = resultImage
            }
        })
        
        if let index = selectedPHAsset.indexOf(asset) {
            cell.markerNumber = (index.advancedBy(0) + 1)
        }
        else {
            cell.markerNumber = 0
        }
        
        return cell
    }
    //MARK: UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return photoCellItemSize
    }
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    

        let asset = currentAssetResult[indexPath.item] as! PHAsset
        if let index = selectedPHAsset.indexOf(asset) {
            
            selectedPHAsset.removeAtIndex(index)
            
            let selectedIndexPaths:[NSIndexPath] = selectedPHAsset.map({
                asset in
                let index = self.currentAssetResult.indexOfObject(asset)
                return NSIndexPath(forItem: index, inSection: 0)
            })
            collectionView.reloadItemsAtIndexPaths(selectedIndexPaths + [indexPath])
        }
        else {

            if imagePickNumber > 0 && imagePickNumber <= selectedPHAsset.count {
                return
            }
            selectedPHAsset.append(asset)
            collectionView.reloadItemsAtIndexPaths([indexPath])
        }
        

    }
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? IPaImagePickerCollectionViewCell else {
            return
        }
        
        cell.highlightView.hidden = false
        //set color with animation

    }
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? IPaImagePickerCollectionViewCell else {
            return
        }
        //set color with animation
        cell.highlightView.hidden = true

    }

    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // Update cached assets for the new visible area.
        updateCachedAssets()
    }
   
}
