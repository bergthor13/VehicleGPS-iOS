//
//  VehicleTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VehicleTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var colorBanner: UIView!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var imgVehicle: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        colorBanner.layer.borderColor = UIColor.tertiaryLabel.cgColor
        colorBanner.layer.borderWidth = 0.5

        colorBanner.roundCorners(corners: [.bottomRight, .topRight], radius: 3.0)
    }
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
