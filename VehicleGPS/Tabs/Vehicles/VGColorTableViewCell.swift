//
//  ColorTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 17/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGColorTableViewCell: UITableViewCell {

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var lblColorTitle: UILabel!
    static let identifier = "colorCell"
    static let nibName = "VGColorTableViewCell"
    static let nib = UINib(nibName: VGColorTableViewCell.nibName, bundle: nil)

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
