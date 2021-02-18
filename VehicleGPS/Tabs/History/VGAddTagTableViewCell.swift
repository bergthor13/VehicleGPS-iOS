//
//  VGAddTagTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 12.2.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGAddTagTableViewCell: UITableViewCell {

    
    @IBOutlet weak var txtName: UITextField!
    
    static let identifier = "AddTagCell"
    static let nibName = "VGAddTagTableViewCell"
    static let nib = UINib(nibName: VGAddTagTableViewCell.nibName, bundle: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
