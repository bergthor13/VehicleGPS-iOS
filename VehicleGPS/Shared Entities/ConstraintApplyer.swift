//
//  ConstraintApplyer.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 09/09/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

extension UIView {
    func fill(parentView:UIView, with insets:UIEdgeInsets) {
        parentView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        parentView.translatesAutoresizingMaskIntoConstraints = false
        let layoutLeft = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: parentView, attribute: .leading, multiplier: 1, constant: insets.left)
        let layoutRight = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: parentView, attribute: .trailing, multiplier: 1, constant: -insets.right)
        let layoutTop = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: insets.top)
        let layoutBottom = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: parentView, attribute: .bottom, multiplier: 1, constant: insets.bottom)
        parentView.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])
    }
    
    func fill(parentView:UIView, layoutGuide:UILayoutGuide, with insets:UIEdgeInsets) {
        parentView.addSubview(self)
        let layoutLeft = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: layoutGuide, attribute: .leading, multiplier: 1, constant: insets.left)
        let layoutRight = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: layoutGuide, attribute: .trailing, multiplier: 1, constant: -insets.right)
        let layoutTop = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: layoutGuide, attribute: .top, multiplier: 1, constant: insets.top)
        let layoutBottom = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: layoutGuide, attribute: .bottom, multiplier: 1, constant: insets.bottom)
        parentView.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])
    }
}
