import CoreGraphics
import Foundation

guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
    FileHandle.standardError.write("ERR: cannot enumerate windows\n".data(using: .utf8)!)
    exit(2)
}
for w in list {
    let wid   = (w[kCGWindowNumber as String] as? Int) ?? -1
    let owner = (w[kCGWindowOwnerName as String] as? String) ?? "?"
    let pid   = (w[kCGWindowOwnerPID as String] as? Int) ?? -1
    let layer = (w[kCGWindowLayer as String] as? Int) ?? -1
    var x = 0, y = 0, cw = 0, ch = 0
    if let b = w[kCGWindowBounds as String] as? [String: Any] {
        x  = Int((b["X"] as? Double) ?? 0);      y  = Int((b["Y"] as? Double) ?? 0)
        cw = Int((b["Width"] as? Double) ?? 0);  ch = Int((b["Height"] as? Double) ?? 0)
    }
    // tab-separated: wid, owner, pid, layer, x, y, w, h
    print("\(wid)\t\(owner)\t\(pid)\t\(layer)\t\(x)\t\(y)\t\(cw)\t\(ch)")
}
