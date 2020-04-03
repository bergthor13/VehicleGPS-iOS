//
//  DeviceConnectedHeaderView.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGDeviceConnectedHeaderView: UIView {

    @IBOutlet weak var greenBackground: UIView!
    @IBOutlet weak var greenButton: UIView!
    @IBOutlet weak var lblConnectedToGPS: UILabel!
    @IBOutlet weak var lblLogsAvailable: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    
    static let nibName = "VGDeviceConnectedHeaderView"
    
    class func loadFromNibNamed(nibNamed: String, bundle: Bundle? = nil) -> VGDeviceConnectedHeaderView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
        ).instantiate(withOwner: nil, options: nil)[0] as? VGDeviceConnectedHeaderView
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.greenBackground.layer.cornerRadius = 5
        self.greenButton.layer.cornerRadius = 5
        self.greenBackground.layer.borderColor = UIColor.init(named: "appColor")?.cgColor
        self.greenButton.layer.borderColor = UIColor.init(named: "appColor")?.cgColor
        self.greenBackground.layer.borderWidth = 0.5
        self.greenButton.layer.borderWidth = 0.5
    }
}
