//
//  PhotoViewController.swift
//  NewsIniOS10
//
//  Created by Emiaostein on 6/20/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit
import Photos

class PhotoViewController: UIViewController {
    
    private var authorized = false
    private var manager = PHCachingImageManager()
    private var fetchResult: PHFetchResult<PHAsset>?
    var targetSize: CGSize!
    var doneHandler: ((UIImage) -> ())?

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        checkLibraryStatus {[weak self] (success) in
            self?.authorized = success
            if success {
                self?.beganFetchPhotos()
            }
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(PhotoViewController.done))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
//        if let vc = segue.destinationViewController as? PhotoDetailViewController {
//            if let result = fetchResult, let cell = sender as? UICollectionViewCell, let i = collectionView.indexPath(for: cell)?.item {
//                let asset = result[i]
//                vc.manager = manager
//                vc.asset = asset
//            }
//        }
    }
    
    func done(sender: AnyObject) {
        
        if let indexPath = collectionView.indexPathsForSelectedItems()?.first {
            if authorized, let result = fetchResult, let item = indexPath.item {
                let asset = result[item]
                let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).fitTo(size: targetSize).multi(v: UIScreen.main().scale)
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                manager.requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFit, options: options, resultHandler: {[weak self] (image, info) in
                    self?.doneHandler?(image!)
                })
            }
        }
    }
    
    
    // MARK: - Authorzied Status
    private func checkLibraryStatus(completed: ((Bool) -> ())?) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completed?(true)
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (requestedStatus) in
                DispatchQueue.main.async(execute: { 
                    if requestedStatus == .authorized {
                        completed?(true)
                    } else {
                        completed?(false)
                    }
                })
            })
            
        case .denied, .restricted:
            completed?(false)
        }
    }
    
    private func beganFetchPhotos() {
        guard authorized else {
            return
        }
        
        // 1. fetch options
        let allPhotos = PHFetchOptions()
        let dateSortDescritor = SortDescriptor(key: "modificationDate", ascending: false)
        allPhotos.sortDescriptors = [dateSortDescritor]
        
        // 2. fetch result and collection
        let result = PHAsset.fetchAssets(with: allPhotos)
        guard result.count > 0 else {return}
        fetchResult = result
        collectionView.reloadData()
    }
}

// MARK: - CollectionView Datasource
extension PhotoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath)
        if let imgview = cell.viewWithTag(1000) as? UIImageView {
            if authorized, let result = fetchResult, let item = indexPath.item {
                let asset = result[item]
                let identifier = asset.localIdentifier
                let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).fillTo(size: imgview.bounds.size).multi(v: UIScreen.main().scale)
                cell.restorationIdentifier = identifier
                manager.requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFit, options: nil, resultHandler: { (image, info) in
                    if cell.restorationIdentifier == identifier, let img = image {
                        imgview.image = img
                    }
                })
            }
        }
        
        return cell
    }
}

extension PhotoViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        navigationItem.rightBarButtonItem?.isEnabled = collectionView.indexPathsForSelectedItems()?.count > 0
    }
}

extension PhotoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let s = CGFloat(2)
        let n = CGFloat(4)
        let l = (view.bounds.width - s * 2 - s * (n - 1)) / n
        return CGSize(width: l, height: l)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let s = CGFloat(2)
        return UIEdgeInsets(top: s, left: s, bottom: s, right: s)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}


