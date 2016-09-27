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
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    lazy var photoLibrary = PHPhotoLibrary.shared()
    lazy var currentAssetResult:PHFetchResult = { () -> PHFetchResult<PHAsset> in 
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d",PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: allPhotosOptions)
        
    }()
    lazy var imageManager = PHCachingImageManager()
    lazy var photoCellItemSize = CGSize.zero
    var previousPreheatRect = CGRect.zero
    var imagePickNumber:Int = 0
    var selectedPHAsset = [PHAsset]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(IPaImagePickerContentViewController.onConfirm(_:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(IPaImagePickerContentViewController.onCancel(_:)))
        

        view.addSubview(contentCollectionView)
        let viewsDict:[String:UIView] = ["view": contentCollectionView]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",options:NSLayoutFormatOptions(rawValue: 0),metrics:nil,views:viewsDict))
        
        contentCollectionView.register(IPaImagePickerCollectionViewCell.self, forCellWithReuseIdentifier: "photoCell")
        
        // Store the PHFetchResult objects and localized titles for each section.

        photoLibrary.register(self)
        
        // Do any additional setup after loading the view.
    }
    deinit{
        photoLibrary.unregisterChangeObserver(self)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        refreshPhotoCellItemSize()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentCollectionView.reloadData()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        selectedPHAsset.removeAll()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onConfirm(_ sender: AnyObject) {
        guard let navigationController = navigationController as?    IPaImagePickerController else {
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
    @IBAction func onCancel(_ sender: AnyObject) {
        guard let navigationController = navigationController as?    IPaImagePickerController else {
            return
        }
        navigationController.cancelPicker()
        
    }
    func refreshPhotoCellItemSize() {
        let width = (view.bounds.width - 20.0 ) / 3.0
        photoCellItemSize = CGSize(width: width, height: width)
    }
    
    
    func getIndexPaths(_ inRect:CGRect) -> [IndexPath] {
        guard let attributes = contentCollectionView.collectionViewLayout.layoutAttributesForElements(in: inRect) , attributes.count > 0 else {
            return []
        }
        var indexPaths = [IndexPath]()
        for layoutAttribute in attributes {
            indexPaths.append(layoutAttribute.indexPath)
        }
        return indexPaths
    }
    //MARK: Asset Caching
    
    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRect.zero
    }
    func updateCachedAssets() {
        guard let _ = view.window , isViewLoaded else {
            return
        }
    
        // The preheat window is twice the height of the visible rect.
        var preheatRect = contentCollectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
    
        /*
        Check if the collection view is showing an area that is significantly
        different to the last preheated area.
        */
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > contentCollectionView.bounds.height / 3.0 {
    
            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [IndexPath]()
            var removedIndexPaths = [IndexPath]()
            computeDifference(previousPreheatRect, newRect: preheatRect, removedHandler: {
                removedRect in
                    let indexPaths = self.getIndexPaths(removedRect)
                    removedIndexPaths.append(contentsOf: indexPaths)

                }, addedHandler: {
                    addedRect in
                    let indexPaths = self.getIndexPaths(addedRect)
                    addedIndexPaths.append(contentsOf: indexPaths)
            })
            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths)

            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths)

        // Update the assets the PHCachingImageManager is caching.
            imageManager.startCachingImages(for: assetsToStartCaching, targetSize: photoCellItemSize, contentMode: .aspectFill, options: nil)
            imageManager.stopCachingImages(for: assetsToStopCaching, targetSize: photoCellItemSize, contentMode: .aspectFill, options: nil)


        // Store the preheat rect to compare against in the future.
            previousPreheatRect = preheatRect
        }
    }
    func computeDifference(_ oldRect:CGRect,newRect:CGRect,removedHandler:((CGRect) -> Void),addedHandler:((CGRect) -> Void)) {
        
        if newRect.intersects(oldRect) {
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
    
    func assetsAtIndexPaths(_ indexPaths:[IndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 {
            return []
        }
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            assets.append(currentAssetResult[(indexPath as IndexPath).item] )
        }
    
        return assets;
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK:PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange)
    {
      
        // Check if there are changes to the assets we are showing.
        //================================================
        //need to do these two command in the same thread or there will be conditional racing
        guard let collectionChanges = changeInstance.changeDetails(for: currentAssetResult) else {
            return
        }
        self.currentAssetResult = collectionChanges.fetchResultAfterChanges
        
        //================================================
        /*
        Change notifications may be made on a background queue. Re-dispatch to the
        main queue before acting on the change as we'll be updating the UI.
        */
        DispatchQueue.main.async(execute: {
            // Get the new fetch result.

          
            
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                self.contentCollectionView.reloadData()
            }
            else {
            
                /*
                Tell the collection view to animate insertions and deletions if we
                have incremental diffs.
                */
                self.contentCollectionView.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes , removedIndexes.count > 0{
                        let removedIndexPaths = removedIndexes.map({
                            index in
                            return IndexPath(item: index, section: 0)
                        })
                        self.contentCollectionView.deleteItems(at: removedIndexPaths)
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes , insertedIndexes.count > 0 {
                        let insertedIndexPaths = insertedIndexes.map({
                            index in
                            return IndexPath(item: index, section: 0)
                        })
                        self.contentCollectionView.insertItems(at: insertedIndexPaths)
                    }
                    
                    if let changedIndexes = collectionChanges.changedIndexes , changedIndexes.count > 0{
                        let changedIndexPaths = changedIndexes.map({
                            index in
                            return IndexPath(item: index, section: 0)
                        })
                        self.contentCollectionView.reloadItems(at: changedIndexPaths)
                    }
                }, completion: nil)
            }
            self.resetCachedAssets()
        });

    }
    //MARK:UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return currentAssetResult.count
    }
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let asset = currentAssetResult[(indexPath as IndexPath).item] 

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! IPaImagePickerCollectionViewCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        imageManager.requestImage(for: asset, targetSize: photoCellItemSize, contentMode: .aspectFill, options: nil, resultHandler: {
            resultImage,info in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.photoImageView.image = resultImage
            }
        })
        
        if let index = selectedPHAsset.index(of: asset) {
            cell.markerNumber = (index.advanced(by: 0) + 1)
        }
        else {
            cell.markerNumber = 0
        }
        
        return cell
    }
    //MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return photoCellItemSize
    }
    //MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    

        let asset = currentAssetResult[(indexPath as IndexPath).item] 
        if let index = selectedPHAsset.index(of: asset) {
            
            selectedPHAsset.remove(at: index)
            
            let selectedIndexPaths:[IndexPath] = selectedPHAsset.map({
                asset in
                let index = self.currentAssetResult.index(of: asset)
                return IndexPath(item: index, section: 0)
            })
            collectionView.reloadItems(at: selectedIndexPaths + [indexPath])
        }
        else {

            if imagePickNumber > 0 && imagePickNumber <= selectedPHAsset.count {
                return
            }
            selectedPHAsset.append(asset)
            collectionView.reloadItems(at: [indexPath])
        }
        

    }

    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // Update cached assets for the new visible area.
        updateCachedAssets()
    }
   
}
