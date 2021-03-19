//
//  NewVehicleTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

@available(iOS 14.0, *)
class VGNewVehicleColorWellTableViewCell: VGNewVehicleTableViewCell {
    var colorWell: VGColorWell!

    //static let identifier = "NewVehicleColorWellCell"
    //static let nib = UINib(nibName: VGNewVehicleColorWellTableViewCell.nibName, bundle: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        colorWell = VGColorWell(frame: self.colorBox.frame)
        self.colorContainer.addSubview(colorWell)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setColor(color: UIColor) {
        colorWell.selectedColor = color
    }

}
