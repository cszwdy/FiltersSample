//
//  Filter.swift
//  FiltersSample
//
//  Created by Emiaostein on 6/21/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import Foundation
import CoreImage

private typealias FilterProcess = CIImage -> CIImage

infix operator --> {associativity left}
private func --> (filter1: FilterProcess, filter2: FilterProcess) -> FilterProcess {
    return {img in filter2(filter1(img))}
}

class Filter {
    
    private var filter: FilterProcess = {$0}
    
    func blur(r: Double) -> Filter {
        filter = filter --> {img in
            let parameters = [
                kCIInputRadiusKey: r,
                kCIInputImageKey: img]
            
            guard let f = CIFilter(name: "CIGaussianBlur", withInputParameters: parameters) else { fatalError() }
            guard let outputImage = f.outputImage else { fatalError() }
            return outputImage
        }
        
        return self
    }
    
    func colorOverlay(r r: Double, g: Double, b: Double, a: Double) -> Filter {
        filter = filter --> { img in
            
            let overlay = Filter.colorGenerator(r, g, b, a)(img)
            return Filter.compositeSourceOver(overlay)(img)
        }
        
        return self
    }
    
    func start(byImage img: CIImage) -> CIImage {
        return filter(img)
    }
}

extension Filter {
    private class func colorGenerator(r: Double, _ g: Double, _ b: Double, _ a: Double) -> FilterProcess {
        return {_ in
            let c = CIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
            let parameters = [kCIInputColorKey: c]
            
            guard let f = CIFilter (name: "CIConstantColorGenerator", withInputParameters: parameters), outputImage = f.outputImage else { fatalError() }
            
            return outputImage
        }
    }
    
    private class func compositeSourceOver(overlay: CIImage) -> FilterProcess {
        return { img in
            let parameters = [
                kCIInputBackgroundImageKey: img,
                kCIInputImageKey: overlay ]
            
            guard let f = CIFilter (name: "CISourceOverCompositing", withInputParameters: parameters), outputImage = f.outputImage else { fatalError() }
            let cropRect = img.extent
            
            return outputImage.imageByCroppingToRect(cropRect)
        }
    }
}