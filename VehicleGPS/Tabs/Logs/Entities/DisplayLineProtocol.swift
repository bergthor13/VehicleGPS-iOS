//
//  DisplayLineProtocol.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 28/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

protocol DisplayLineProtocol {
    var dlpPoint: CGPoint? { get set }
    var dlpTime: Date? { get set }
    func didTouchGraph(at point: CGPoint)
}
