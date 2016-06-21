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
    
    func colorLUT(colorTableData data: NSData, dimension: Int) -> Filter {
        filter = filter --> { img in
            let parameters = [
                kCIInputImageKey: img,
                "inputCubeData": data,
                "inputCubeDimension": dimension
            ]
            guard let f = CIFilter(name: "CIColorCube", withInputParameters: parameters), outputImage = f.outputImage else {fatalError()}
            return outputImage
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

extension Filter {
    
    class func colorLUTData(byImage img: CGImage, dimensiton d: Int) -> NSData? {
        let w = Int(CGImageGetWidth(img))
        let h = Int(CGImageGetHeight(img))
        let row = w / d
        let col = h / d
        
        guard w % d == 0 && h % d == 0 && row * col == d else { return nil }
        
        // create colorLUT image's bitmap
        let bytesPerPixel = 4 // pixel = GRBA = 4xcompoent = 4 bytes
        let bitsPerComponent = 8 //  component = R/G/B/A = 1 byte = 8 bit
        let bytesPerRow = bytesPerPixel * w
        let size = w * h * bytesPerPixel
        var bitmap = malloc(size)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo =  CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue).rawValue
        
        guard let context = CGBitmapContextCreate(&bitmap, w, h, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo) else { free(bitmap); return nil }
        
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: w, height: h), img)
        let finishedBitmap = bitmap
        
        // create RGBA data from bitmap
        let dsize = d * d * d * sizeof(CGFloat) * 4
        var data = NSMutableData(capacity: dsize)
        var bitmapOffset = 0
        var z = 0
        for _ in 0..<row {
            for y in 0..<d {
               let tmpZ = z
                for _ in 0..<col {
                    for x in 0..<d {
                        let r = unsafeBitCast(bitmap[bitmapOffset + 0], Int.self)
                        let g = unsafeBitCast(bitmap[bitmapOffset + 1], Int.self)
                        let b = unsafeBitCast(bitmap[bitmapOffset + 2], Int.self)
                        let a = unsafeBitCast(bitmap[bitmapOffset + 3], Int.self)
                        
                        let dataOffset = (z*d*d + y*d + x) * 4
                        
                        var r1 = CGFloat(r) / 255.0
                        var g1 = CGFloat(g) / 255.0
                        var b1 = CGFloat(b) / 255.0
                        var a1 = CGFloat(a) / 255.0
                        
                        data?.replaceBytesInRange(NSMakeRange(dataOffset + 0, 1), withBytes: &r1)
                        data?.replaceBytesInRange(NSMakeRange(dataOffset + 1, 1), withBytes: &g1)
                        data?.replaceBytesInRange(NSMakeRange(dataOffset + 2, 1), withBytes: &b1)
                        data?.replaceBytesInRange(NSMakeRange(dataOffset + 3, 1), withBytes: &a1)
                        
                        bitmapOffset += 4
                    }
                    z += 1
                }
                z = tmpZ
            }
            z += col
        }
        
        free(bitmap)
        
        guard let finalData = data else { return nil }
        
        return data
    }
}