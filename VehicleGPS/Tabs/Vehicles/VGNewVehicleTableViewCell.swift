//
//  NewVehicleTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGNewVehicleTableViewCell: UITableViewCell {

    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var colorContainer: UIView!
    @IBOutlet weak var colorBox: UIView!
    
    var colorWell: VGColorWell!
    
    static let identifier = "NewVehicleCell"
    static let nibName = "VGNewVehicleTableViewCell"
    static let nib = UINib(nibName: VGNewVehicleTableViewCell.nibName, bundle: nil)

    
    override func awakeFromNib() {
        super.awakeFromNib()
        colorWell = VGColorWell(frame: self.colorBox.frame)
        self.colorContainer.addSubview(colorWell)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
