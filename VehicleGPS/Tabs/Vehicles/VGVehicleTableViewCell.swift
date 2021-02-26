//
//  VehicleTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGVehicleTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var colorBanner: UIView!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var imgVehicle: UIImageView!
    @IBOutlet weak var defaultViewBackground: UIView!
    @IBOutlet weak var defaultStarView: UIImageView!
    
    static let identifier = "VehicleCell"
    static let nibName = "VGVehicleTableViewCell"
    static let nib = UINib(nibName: VGVehicleTableViewCell.nibName, bundle: nil)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        colorBanner.layer.borderColor = UIColor.tertiaryLabel.cgColor
        colorBanner.layer.borderWidth = 0.5

        colorBanner.roundCorners(corners: [.bottomRight, .topRight], radius: 3.0)
        
        defaultViewBackground.layer.cornerRadius = defaultViewBackground.bounds.height/2
        
        imgVehicle.layer.borderWidth = 0.5
        imgVehicle.layer.borderColor = UIColor.secondaryLabel.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        imgVehicle.layer.borderColor = UIColor.secondaryLabel.cgColor
    }
}
