//
//  UIViewController+Extensions.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 20.2.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    var appDelegate: AppDelegate {
        // swiftlint:disable force_cast
        return UIApplication.shared.delegate as! AppDelegate
        // swiftlint:enable force_cast
   }
}
