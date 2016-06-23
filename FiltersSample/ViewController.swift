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
                sf.add()
            })
        }
    }
    
    var firstadd = true
    func add() {
        if firstadd {
//            firstadd = false
            let data = Filter.colorLUTData(byImage: (UIImage(named: "zn_512x512.JPG")?.cgImage!)!, dimensiton: 64)!
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
    
    override func viewDidAppear(_ animated: Bool) {

        imageView.image = image
        filterController.image = image
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
}

