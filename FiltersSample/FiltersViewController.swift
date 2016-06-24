//
//  FiltersViewController.swift
//  FiltersSample
//
//  Created by Emiaostein on 6/23/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

extension CGSize {
    func fillTo(size: CGSize) -> CGSize {
        let scale = max(size.width / width, size.height / height)
        return CGSize(width: width * scale, height: height * scale)
    }
    
    func fitTo(size: CGSize) -> CGSize {
        let scale = min(size.width / width, size.height / height)
        return CGSize(width: width * scale, height: height * scale)
    }
    
    func multi(v: CGFloat) -> CGSize {
        return CGSize(width: width * v, height: height * v)
    }
}

class FiltersViewController: UIViewController {
    
    let queue = DispatchQueue(label: "CoreImage.Queue", attributes: DispatchQueueAttributes.concurrent, target: nil)
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addButton: UIButton!
    var image: UIImage? {didSet{updatePreviewImage()}}
    private var previewImage: UIImage?
    var filters = [FilterItem]()
    var didSelectedHandler: ((UIImage) -> ())?
    var addHandler: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 86, bottom: 0, right: 0)
        addButton.center.x = 84 / 2 + 2
    }
    
    private func updatePreviewImage() {
        // generate preview image
        if let image = image {
            let itemSize = CGSize(width: 84, height: 84).multi(v: UIScreen.main().scale)
            let fillSize = image.size.fillTo(size: itemSize)
            UIGraphicsBeginImageContext(fillSize)
            image.draw(in: CGRect(origin: CGPoint.zero, size: fillSize))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            previewImage = scaledImage
            filters.forEach{$0.cleanImage()}
            collectionView.reloadData()
        }
    }
    
    func add(filterItem item: FilterItem) {
        filters.insert(item, at: 0)
        let i = IndexPath(item: 0, section: 0)
        collectionView.insertItems(at: [i])
    }
    
    
    @IBAction func add(_ sender: AnyObject) {
        addHandler?()
    }
    
    func editModeChanged(_ editing: Bool) {
        setEditing(editing, animated: false)
        collectionView.reloadData()
    }
}

extension FiltersViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath)
    
        let item = filters[indexPath.item!]
        if let imgView = cell.viewWithTag(1000) as? UIImageView {
            
            if let img = item.image {
                imgView.image = img
            } else {
                if let cache = previewImage {
                    let ID = item.assetIdentifier
                    cell.restorationIdentifier = ID
                    item.createImage(from: cache, complation: { (filteredImage) in
                        DispatchQueue.main.async(execute: {
                            if cell.restorationIdentifier == ID {
                                if let aimgView = cell.viewWithTag(1000) as? UIImageView {
                                    aimgView.image = filteredImage
                                }
                            }
                        })
                    })
                }
            }
        }
        
        if let label = cell.viewWithTag(2000) as? UILabel {
            label.text = item.name
        }
        
        if cell.selectedBackgroundView == nil {
            let selectedv = UIView(frame: CGRect(origin: CGPoint.zero, size: cell.bounds.size))
            selectedv.backgroundColor = UIColor.yellow()
            cell.selectedBackgroundView = selectedv
        }
        
        if let delete = cell.viewWithTag(100) as? UIImageView {
            delete.isHidden = !isEditing
        }
        
        return cell
    }
}

extension FiltersViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let i = indexPath.item where isEditing {
            filters.remove(at: i)
            collectionView.deleteItems(at: [indexPath])
            
        } else {
            if  let i = indexPath.item, image = image {
                let filter = filters[i]
                queue.async(execute: {
                    let img = CIImage(cgImage: image.cgImage!)
                    let cgimg = Filter()
                        .colorLUT(colorTableData: filter.data as Data, dimension: 64)
                        .start(byImage: img)
                        .tocgImage()
                    let filterImage = UIImage(cgImage: cgimg)
                    DispatchQueue.main.async(execute: { [weak self] in
                        self?.didSelectedHandler?(filterImage)
                        })
                })
            }
        }
        }
        
        
    
}

extension FiltersViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let s = CGFloat(2)
        let n = CGFloat(1)
        let l = (view.bounds.height - s * 2 - s * (n - 1)) / n
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
