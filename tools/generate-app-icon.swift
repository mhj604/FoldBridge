import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
let context = CGContext(data:nil,width:1024,height:1024,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(red:9/255,green:15/255,blue:21/255,alpha:1));context.fill(CGRect(x:0,y:0,width:1024,height:1024))
let outlineWidth: CGFloat = 39
let mint = CGColor(red:130/255,green:230/255,blue:209/255,alpha:1)
let light = CGColor(red:229/255,green:249/255,blue:244/255,alpha:1)
context.setLineWidth(outlineWidth);context.setLineCap(.round);context.setLineJoin(.round)
context.setStrokeColor(mint)
context.addPath(CGPath(roundedRect:CGRect(x:237,y:267,width:226,height:490),cornerWidth:49,cornerHeight:49,transform:nil));context.strokePath()
context.move(to:CGPoint(x:317,y:319));context.addLine(to:CGPoint(x:383,y:319));context.strokePath()
context.setFillColor(CGColor(red:26/255,green:52/255,blue:53/255,alpha:1))
context.addPath(CGPath(roundedRect:CGRect(x:586,y:263,width:77,height:498),cornerWidth:24,cornerHeight:24,transform:nil));context.fillPath()
context.setFillColor(CGColor(red:9/255,green:15/255,blue:21/255,alpha:1))
context.addPath(CGPath(roundedRect:CGRect(x:520,y:347,width:216,height:330),cornerWidth:66,cornerHeight:66,transform:nil));context.fillPath()
context.setStrokeColor(light)
context.addPath(CGPath(roundedRect:CGRect(x:520,y:347,width:216,height:330),cornerWidth:66,cornerHeight:66,transform:nil));context.strokePath()
context.setStrokeColor(mint);context.setLineWidth(32)
context.move(to:CGPoint(x:432,y:512));context.addCurve(to:CGPoint(x:561,y:512),control1:CGPoint(x:480,y:562),control2:CGPoint(x:513,y:562));context.strokePath()
// Balance the visible artwork rather than just its bounding rectangle. The phone
// and watch have different shapes and brightness, so equal margins looked left-heavy.
let pixels=context.data!.assumingMemoryBound(to:UInt8.self)
var total=0.0, weightedX=0.0
for y in 0..<1024 { for x in 0..<1024 {
    let i=y*context.bytesPerRow+x*4
    let weight=max(0,0.2126*(Double(pixels[i])-9)+0.7152*(Double(pixels[i+1])-15)+0.0722*(Double(pixels[i+2])-21))
    total+=weight;weightedX+=Double(x)*weight
} }
let centered=CGContext(data:nil,width:1024,height:1024,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
centered.setFillColor(CGColor(red:9/255,green:15/255,blue:21/255,alpha:1));centered.fill(CGRect(x:0,y:0,width:1024,height:1024))
centered.interpolationQuality = .high
centered.draw(context.makeImage()!,in:CGRect(x:511.5-weightedX/total,y:0,width:1024,height:1024))
let original = centered.makeImage()!
func save(_ image:CGImage,_ path:String){let url=URL(fileURLWithPath:path);let out=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!;CGImageDestinationAddImage(out,image,nil);CGImageDestinationFinalize(out)}
save(original,CommandLine.arguments[1])
let small=CGContext(data:nil,width:256,height:256,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
small.interpolationQuality = .high;small.draw(original,in:CGRect(x:0,y:0,width:256,height:256));save(small.makeImage()!,CommandLine.arguments[2])
