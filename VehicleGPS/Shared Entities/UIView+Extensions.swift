//
//  UIView+Extensions.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 01/04/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
