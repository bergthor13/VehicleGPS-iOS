//
//  DeviceConnectedHeaderView.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class DeviceConnectedHeaderView: UIView {

    @IBOutlet weak var greenBackground: UIView!
    @IBOutlet weak var greenButton: UIView!
    @IBOutlet weak var lblConnectedToGPS: UILabel!
    @IBOutlet weak var lblLogsAvailable: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    
    class func loadFromNibNamed(nibNamed: String, bundle: Bundle? = nil) -> DeviceConnectedHeaderView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
        ).instantiate(withOwner: nil, options: nil)[0] as? DeviceConnectedHeaderView
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.greenBackground.layer.cornerRadius = 5
        self.greenButton.layer.cornerRadius = 5
    }
}
