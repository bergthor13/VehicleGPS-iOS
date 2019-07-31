//
//  LogsTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class LogsTableViewCell: UITableViewCell {

    @IBOutlet weak var trackView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblTimeStart: UILabel!
    @IBOutlet weak var lblFileSize: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var fileOnGPSIndicator: UIImageView!
    @IBOutlet weak var fileOnDeviceIndicator: UIImageView!
    var vgFileManager: VGFileManager!
    
    
    
    func update(progress:Double) {
        let viewWidth = self.frame.width
        progressViewWidthConstraint.constant = viewWidth*CGFloat(progress)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        vgFileManager = VGFileManager()
        
    }
    
    func show(track:VGTrack) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        self.lblTimeStart!.text = formatter.string(from: fileNameToDate(dateString: track.fileName))
        
        let fileSizeWithUnit = ByteCountFormatter.string(fromByteCount: Int64(truncating: NSNumber(value: track.fileSize)), countStyle: .file)
        
        
        self.lblFileSize!.text = fileSizeWithUnit
        let distanceFormatter = LengthFormatter()
        distanceFormatter.numberFormatter.maximumFractionDigits = 2
        distanceFormatter.numberFormatter.minimumFractionDigits = 2
        if track.distance > 1 {
            self.lblDistance.text = distanceFormatter.string(fromValue: track.distance, unit: .kilometer)
        } else {
            self.lblDistance.text = distanceFormatter.string(fromValue: track.distance*1000, unit: .meter)
        }
        
        let form = DateComponentsFormatter()
        form.unitsStyle = .abbreviated
        form.allowedUnits = [ .hour, .minute, .second ]
        form.zeroFormattingBehavior = [ .default ]
        
        let formattedDuration = form.string(from: track.duration)
        self.lblDuration.text = String(formattedDuration!)
        if vgFileManager.fileForTrackExists(track: track) {
            self.fileOnDeviceIndicator.isHidden = false
        } else {
            self.fileOnDeviceIndicator.isHidden = true
        }
        
        if track.isRemote {
            self.fileOnGPSIndicator.isHidden = false
        } else {
            self.fileOnGPSIndicator.isHidden = true
        }
        trackView.image = vgFileManager.openImageFor(track: track)
        trackView.layer.borderWidth = 0.5
        trackView.layer.borderColor = UIColor.black.cgColor
        if track.beingProcessed {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }

    }
    
    
    
    func fileNameToDate(dateString:String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HHmmss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        let date = dateFormatter.date(from:String(dateString.prefix(17)))
        return date!
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
