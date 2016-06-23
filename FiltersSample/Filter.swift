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
    
    static let context = CIContext(options: [
        kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()!
        ])
    
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
        let size = bytesPerRow * h
        let bitmapBuffer = NSMutableData(bytes: malloc(size), length: size)
        let bitmap = bitmapBuffer.mutableBytes
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo =  CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue).rawValue
        
        guard let context = CGBitmapContextCreate(bitmap, w, h, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo) else { return nil }
        
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: w, height: h), img)
        // http://stackoverflow.com/questions/24049313/how-do-i-load-and-edit-a-bitmap-file-at-the-pixel-level-in-swift-for-ios
        let data:COpaquePointer = COpaquePointer(CGBitmapContextGetData(context))
        let dataType = UnsafePointer<UInt8>(data)
        
        // create RGBA data from bitmap
        let dsize = d * d * d * 4 * sizeof(Float32)
        let ddata = NSMutableData(bytes: malloc(dsize), length: dsize)
        
        let ndata:COpaquePointer = COpaquePointer(ddata.mutableBytes)
        let ndataType = UnsafeMutablePointer<Float32>(ndata)
        
        var bitmapOffset = 0
        var z = 0
        for _ in 0..<row {
            for y in 0..<d {
               let tmpZ = z
                for _ in 0..<col {
                    for x in 0..<d {
                        let a = dataType[bitmapOffset + 0]
                        let r = dataType[bitmapOffset + 1]
                        let g = dataType[bitmapOffset + 2]
                        let b = dataType[bitmapOffset + 3]
                        
                        let dataOffset = (z*d*d + y*d + x) * 4
                        
                        let a1 = Float32(a) / 255.0
                        let r1 = Float32(r) / 255.0
                        let g1 = Float32(g) / 255.0
                        let b1 = Float32(b) / 255.0
                        
                        ndataType[dataOffset + 0] = Float32(r1)
                        ndataType[dataOffset + 1] = Float32(g1)
                        ndataType[dataOffset + 2] = Float32(b1)
                        ndataType[dataOffset + 3] = Float32(a1)
                        
                        bitmapOffset += 4
                    }
                    z += 1
                }
                z = tmpZ
            }
            z += col
        }
        
        return ddata
    }
}