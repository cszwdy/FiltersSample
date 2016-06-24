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
    let filterPath: String = {
        let docmentURL = try! FileManager.default().urlForDirectory(.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let file = try! docmentURL.appendingPathComponent("filters.cur").path!
       return file
    }()
    lazy var filterController: FiltersViewController = self.childViewControllers.first! as! FiltersViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Filters"
        
        if let filters = NSKeyedUnarchiver.unarchiveObject(withFile: filterPath) as? [FilterItem] {
            filterController.filters = filters
        } else {
            
            if let path = Bundle.main().pathForResource("filters", ofType: "cur"), let filters = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [FilterItem] {
                filterController.filters = filters
            }
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
                    
                    let alert = UIAlertController(title: "Filter Name", message: "Named for your filter.", preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addTextField(configurationHandler: { (textfield) in
                        
                    })
                    
                    let done = UIAlertAction(title: "Done", style: .default, handler: { (action) in
                        UIGraphicsBeginImageContext(size)
                        photo.draw(in: CGRect(origin: CGPoint.zero, size: size))
                        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        let title = alert.textFields?.first!.text ?? "Empty"
                        
                        sf.add(image: scaledImage!, title: title)
                        let _ = sf.navigationController?.popViewController(animated: true)
                    })
                    
                    alert.addAction(done)
                    
                    sf.navigationController?.present(alert, animated: true, completion: nil)
                }
                
                sf.navigationController?.pushViewController(photoVC, animated: true)
            })
        }
    }
    
    func add(image: UIImage, title: String) {
            let data = Filter.colorLUTData(byImage: image.cgImage!, dimensiton: 64)!
            let item = FilterItem(name: title, data: data)
            filterController.add(filterItem: item)
    }
}

// MARK: - Actions
extension ViewController {
    
    @IBAction func share(_ sender: AnyObject) {
        
        let fileURL = NSURL(fileURLWithPath: filterPath)
        
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        navigationController?.present(activityViewController, animated: true) {
        }
    }
    
    @IBAction func saveFilters(_ sender: AnyObject) {
        let filters = filterController.filters
        let docmentURL = try! FileManager.default().urlForDirectory(.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let file = try! docmentURL.appendingPathComponent("filters.cur")
        
        NSKeyedArchiver.archiveRootObject(filters, toFile: file.path!)
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
                let _ = sf.navigationController?.popViewController(animated: true)
            }
            
            sf.navigationController?.pushViewController(photoVC, animated: true)
            })
    }
    
    @IBAction func pan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed, .began:
            ()
        default:
            imageView.image = filteredImage ?? image
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        imageView.image = image
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        imageView.image = filteredImage ?? image
    }
    
    @IBAction func editFilters(_ sender: AnyObject) {
        setEditing(!isEditing, animated: false)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationItem.rightBarButtonItem!.title = editing ? "Done" : "Edit"
        filterController.editModeChanged(editing)
    }
}

