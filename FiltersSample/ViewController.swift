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
        
        let img = CIImage(image: UIImage(named: "m.jpeg")!)!
        let colorLUTImage = UIImage(named: "zn_512x512.JPG")!.CGImage
        let data = Filter.colorLUTData(byImage: colorLUTImage!, dimensiton: 64)!
        dispatch_async(queue) {
            let img2 = Filter()
//                .colorOverlay(r: 0.5, g: 0.5, b: 0.5, a: 0.5)
//                .blur(5)
                .colorLUT(colorTableData: data, dimension: 64)
                .start(byImage: img)
            
            dispatch_async(dispatch_get_main_queue(), { 
                let image = UIImage(CIImage: img2)
                if let imgview = self.view.viewWithTag(1000) as? UIImageView {
                    imgview.contentMode = .ScaleAspectFill
                    imgview.image = image
                }
            })
        }
    }
}

