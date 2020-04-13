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
    
    func deviceConnected(hostname:String) {
        self.lblLogsAvailable.isHidden = false
        self.lblConnectedToGPS.isHidden = false
        self.imgIcon.isHidden = false
        self.lblConnectedToGPS.text = String(format: Strings.connectedTo, hostname)

    }
    
    func newLogsAvailable(count:Int) {
        if count == 0 {
            self.lblLogsAvailable.text = Strings.noNewLogs
        } else if count == 1 {

            self.lblLogsAvailable.text = String(format: Strings.newLogSingular, count)
        } else if (count-1)%10 == 0 && count != 11 {
            self.lblLogsAvailable.text = String(format: Strings.newLogSingular, count)
        } else {
            self.lblLogsAvailable.text = String(format: Strings.newLogPlural, count)
        }
        if count == 0 {
            self.greenButton.isHidden = true
        } else {
            self.greenButton.isHidden = false
        }
    }
    
    func searchingForLogs() {
        self.lblLogsAvailable.text = Strings.searchForLogs
    }
    
    func downloadingLogs(download:Int, parse:Int) {
        if download == 0 && parse == 0 {
            self.lblLogsAvailable.text = Strings.downloadComplete
            return
        }
        self.lblLogsAvailable.text = "Down: \(download), Parse: \(parse)"

        
    }
}
