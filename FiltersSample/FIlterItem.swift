//
//  FIlterItem.swift
//  FiltersSample
//
//  Created by Emiaostein on 6/23/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import Foundation
import UIKit

private let queue = DispatchQueue(label: "Filter.Item.Queue")

class FilterItem {
    let name: String
    let data: NSData
    private(set) var assetIdentifier: String
    private(set) var image: UIImage?
    
    init(name: String, data: NSData) {
        self.name = name
        self.data = data
        self.assetIdentifier = NSUUID().uuidString.characters.split(separator: "-").map{String($0)}.reduce("", combine:{$0+$1})
    }
    
    func cleanImage() {
        image = nil
    }
    
    func createImage(from img: UIImage, complation:(UIImage) -> ()) {
        let ciimage = CIImage(image: img)
        queue.async { [weak self] in
            guard let sf = self else {return}
            let img2 = Filter()
                .colorLUT(colorTableData: sf.data as Data, dimension: 64)
                .start(byImage: ciimage!)
                .tocgImage()
            DispatchQueue.main.async(execute: {[weak self] in
                guard let sf = self else {return}
                sf.image = UIImage(cgImage: img2)
                complation(sf.image!)
            })
        }
    }
    
}
