//
//  IVGLogParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 21/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

protocol IVGLogParser {
    func fileToTrack(fileUrl:URL, progress:@escaping (UInt, UInt) -> Void, callback:@escaping (VGTrack) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)?)
}
