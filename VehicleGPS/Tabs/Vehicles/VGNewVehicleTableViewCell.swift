//
//  VGNewVehicleTableViewCell2.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 6.3.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGNewVehicleTableViewCell: UITableViewCell {

    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var colorContainer: UIView!
    @IBOutlet weak var colorBox: UIView!
        
    static let identifier = "NewVehicleCell"
    static let nibName = "VGNewVehicleTableViewCell"
    static let nib = UINib(nibName: VGNewVehicleTableViewCell.nibName, bundle: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
        colorBox.layer.cornerRadius = colorBox.bounds.height/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setColor(color: UIColor) {
        colorBox.backgroundColor = color
    }

}
