//
//  HistoryTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 15/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblTripCount: UILabel!
    
    static let identifier = "HistoryCell"
    static let nibName = "VGHistoryTableViewCell"
    static let nib = UINib(nibName: VGHistoryTableViewCell.nibName, bundle: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
