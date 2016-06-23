//
//  ViewController.swift
//  FiltersSample
//
//  Created by Emiaostein on 6/21/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let queue = dispatch_queue_create("Emiaostein", DISPATCH_QUEUE_CONCURRENT)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let img = CIImage(image: UIImage(named: "1.jpeg")!)!
        let colorLUTImage = UIImage(named: "k2.jpeg")!
        let data = Filter.colorLUTData(byImage: colorLUTImage.CGImage!, dimensiton: 64)!
        dispatch_async(queue) {
            let img2 = Filter()
                .colorLUT(colorTableData: data, dimension: 64)
                .start(byImage: img)
            
            let cgimg = Filter.context.createCGImage(img2, fromRect: img2.extent)
            
            dispatch_async(dispatch_get_main_queue(), { 
                let image = UIImage(CGImage: cgimg)
                if let imgview = self.view.viewWithTag(1000) as? UIImageView {
                    imgview.image = image
                }
            })
        }
    }
}

