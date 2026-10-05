import AppKit
import CoreGraphics
import Foundation

// trim <in.png> <out.png> [padPixels]
let a = CommandLine.arguments
guard a.count >= 3,
      let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil),
      let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("ERR load"); exit(2) }
let rep = NSBitmapImageRep(cgImage: cg)
let w = cg.width, h = cg.height
let pad = a.count > 3 ? (Int(a[3]) ?? 30) : 30

guard let bg = rep.colorAt(x: w/2, y: h - 40) else { print("ERR bg"); exit(2) }
func differs(_ c: NSColor?) -> Bool {
    guard let c = c else { return false }
    return abs(c.redComponent   - bg.redComponent)   > 0.06
        || abs(c.greenComponent - bg.greenComponent) > 0.06
        || abs(c.blueComponent  - bg.blueComponent)  > 0.06
}

var lastContent = 0
var y = h - 30
while y >= 0 {
    var found = false, x = 40
    while x < w - 40 { if differs(rep.colorAt(x: x, y: y)) { found = true; break }; x += 2 }
    if found { lastContent = y; break }
    y -= 1
}

let newH = min(h, lastContent + pad)
let outURL = URL(fileURLWithPath: a[2]) as CFURL
if newH >= h {
    try? FileManager.default.removeItem(atPath: a[2])
    try? FileManager.default.copyItem(atPath: a[1], toPath: a[2])
    print("kept \(w)x\(h)"); exit(0)
}
guard let cropped = cg.cropping(to: CGRect(x: 0, y: 0, width: w, height: newH)),
      let dest = CGImageDestinationCreateWithURL(outURL, "public.png" as CFString, 1, nil)
else { print("ERR crop"); exit(2) }
CGImageDestinationAddImage(dest, cropped, nil)
guard CGImageDestinationFinalize(dest) else { print("ERR write"); exit(2) }
print("trimmed \(w)x\(h) -> \(w)x\(newH)")
