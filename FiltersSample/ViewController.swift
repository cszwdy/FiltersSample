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
//                .colorOverlay(r: 0.5, g: 0.5, b: 0.5, a: 0.5)
//                .blur(5)
                .colorLUT(colorTableData: data, dimension: 64)
                .start(byImage: img)
            
            let context = CIContext(options: [
                kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()!
                ])
            let cgimg = context.createCGImage(img2, fromRect: img2.extent)
            
            dispatch_async(dispatch_get_main_queue(), { 
                let image = UIImage(CGImage: cgimg)
                if let imgview = self.view.viewWithTag(1000) as? UIImageView {
                    imgview.image = image
                }
            })
        }
    }
}

