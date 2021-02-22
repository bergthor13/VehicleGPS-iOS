import Foundation
import UIKit

protocol IVGLogParser {
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, onSuccess: @escaping (VGTrack) -> Void, onFailure:@escaping(Error) -> Void)
    
}
