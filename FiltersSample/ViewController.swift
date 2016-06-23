//
//  ViewController.swift
//  FiltersSample
//
//  Created by Emiaostein on 6/21/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let queue = DispatchQueue(label: "Emiaostein", attributes: DispatchQueueAttributes.concurrent)
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage?
    var filteredImage: UIImage?{ didSet {imageView.image = filteredImage ?? image}}
    lazy var filterController: FiltersViewController = self.childViewControllers.first! as! FiltersViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Filters"
        
        let docmentURL = try! FileManager.default().urlForDirectory(.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let file = try! docmentURL.appendingPathComponent("filters.cur")
        if let filters = NSKeyedUnarchiver.unarchiveObject(withFile: file.path!) as? [FilterItem] {
            filterController.filters = filters
        }
        
        filterController.didSelectedHandler = { image in
            DispatchQueue.main.async(execute: { [weak self] in
                guard let sf = self else {
                    return
                }

                sf.filteredImage = image
            })
        }
        
        filterController.addHandler = {[weak self] in
            guard let sf = self else {
                return
            }
            DispatchQueue.main.async(execute: { 
                let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhtotViewController") as! PhotoViewController
                let size = CGSize(width: 512, height: 512)
                photoVC.targetSize = size
                photoVC.doneHandler = { photo in
                    UIGraphicsBeginImageContext(size)
                    photo.draw(in: CGRect(origin: CGPoint.zero, size: size))
                    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    sf.add(image: scaledImage!)
//                    sf.imageView.image = photo
//                    sf.image = photo
//                    sf.filterController.image = photo
                    sf.navigationController?.popViewController(animated: true)
                }
                
                sf.navigationController?.pushViewController(photoVC, animated: true)
            })
        }
    }
    
    var firstadd = true
    func add(image: UIImage) {
        if firstadd {
//            firstadd = false
            let data = Filter.colorLUTData(byImage: image.cgImage!, dimensiton: 64)!
            let item = FilterItem(name: "zn", data: data)
            filterController.add(filterItem: item)
        }
    }
    
    var first = true
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if first {
            first = false
            let img = UIImage(named: "1.jpeg")!
            let itemSize = imageView.bounds.size.multi(v: UIScreen.main().scale)
            let fillSize = img.size.fillTo(size: itemSize)
            UIGraphicsBeginImageContext(fillSize)
            img.draw(in: CGRect(origin: CGPoint.zero, size: fillSize))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            image = scaledImage
        }
    }
    
    var firstDidAppear = true
    override func viewDidAppear(_ animated: Bool) {

        if firstDidAppear {
            firstDidAppear = false
            imageView.image = image
            filterController.image = image
        }
        
    }
    
    @IBAction func pan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed, .began:
            ()
        default:
            imageView.image = filteredImage ?? image
        }
    }
    
    @IBAction func saveFilters(_ sender: AnyObject) {
        
        let filters = filterController.filters
        
        
        let docmentURL = try! FileManager.default().urlForDirectory(.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let file = try! docmentURL.appendingPathComponent("filters.cur")
        
        NSKeyedArchiver.archiveRootObject(filters, toFile: file.path!)
//        try! data.write(to: file, options: .dataWritingAtomic)
        
    }
    
    
    @IBAction func changePhoto(_ sender: AnyObject) {
        
        DispatchQueue.main.async(execute: { [weak self] in
            guard let sf = self else {return}
            let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhtotViewController") as! PhotoViewController
            let size = sf.imageView.bounds.size.multi(v: UIScreen.main().scale)
            photoVC.targetSize = size
            photoVC.doneHandler = { photo in
                let drawSize = photo.size.fitTo(size: size)
                UIGraphicsBeginImageContext(drawSize)
                photo.draw(in: CGRect(origin: CGPoint.zero, size: drawSize))
                let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                sf.imageView.image = scaledImage
                sf.image = scaledImage
                sf.filterController.image = scaledImage
                sf.navigationController?.popViewController(animated: true)
            }
            
            sf.navigationController?.pushViewController(photoVC, animated: true)
        })
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        imageView.image = image
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        imageView.image = filteredImage ?? image
    }
}

