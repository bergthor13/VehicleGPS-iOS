import Foundation
import UIKit

protocol IVGLogParser {
    func fileToTrack(fileUrl:URL, progress:@escaping (UInt, UInt) -> Void, callback:@escaping (VGTrack) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)?)
}
