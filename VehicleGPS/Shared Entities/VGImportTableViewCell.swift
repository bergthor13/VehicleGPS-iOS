//
//  VGImportTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 19/04/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGImportTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblStartDate: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblComment: UILabel!
    
    static let identifier = "ImportLogCell"
    static let nibName = "VGImportTableViewCell"
    static let nib = UINib(nibName: VGImportTableViewCell.nibName, bundle: nil)
    weak var delegate: DisplaySelectVehicleProtocol!
    var vgFileManager: VGFileManager!
    var currentTrack: VGTrack?
    let formatter = VGFullDateFormatter()
        
    override func awakeFromNib() {
        super.awakeFromNib()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.vgFileManager = appDelegate.fileManager
        }
    }
    
    func show(track: VGTrack) {
        currentTrack = track
        self.lblName.text = track.name
        if track.timeStart == nil {
            if let fileDate = fileNameToDate(dateString: track.fileName) {
                self.lblStartDate!.text = formatter.string(from: fileDate)
            }
        } else {
            self.lblStartDate!.text = formatter.string(from: track.timeStart!)
        }
        
        self.lblDistance.text = (track.distance*1000).asDistanceString()
        self.lblDuration.text = track.duration.asDurationString()
        self.lblComment.text = track.comment
    }
    
    func fileNameToDate(dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HHmmss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        if let date = dateFormatter.date(from: String(dateString.prefix(17))) {
            return date
        }
        return nil
    }

}
