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
    var currentTrack:VGTrack?
    let formatter = DateFormatter()
    
    
    func update(progress:Double) {
        let viewWidth = self.frame.width
        progressViewWidthConstraint.constant = viewWidth*CGFloat(progress)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        vgFileManager = (UIApplication.shared.delegate as! AppDelegate).fileManager!
        
    }
    
    func show(track:VGTrack) {
        currentTrack = track
        formatter.dateFormat = "HH:mm:ss"
        if track.timeStart == nil {
            self.lblTimeStart!.text = formatter.string(from: fileNameToDate(dateString: track.fileName))
        } else {
            self.lblTimeStart!.text = formatter.string(from: track.timeStart!)
        }
        
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
        
        self.lblDistance.attributedText = styleString(unstyledString: self.lblDistance.text!, substrings: [" km", " m"])
        
        let form = DateComponentsFormatter()
        form.unitsStyle = .abbreviated
        form.allowedUnits = [ .hour, .minute, .second ]
        form.zeroFormattingBehavior = [ .default ]
        
        let formattedDuration = form.string(from: track.duration)
        
        self.lblDuration.attributedText = styleString(unstyledString: formattedDuration!, substrings: ["h","m","s"])
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
        trackView.image = vgFileManager.openImageFor(track: track, style: self.traitCollection.userInterfaceStyle)
        trackView.layer.borderWidth = 0.5
        trackView.layer.borderColor = UIColor.black.cgColor
        if track.beingProcessed {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }

    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard let track = currentTrack else {return}
        trackView.image = vgFileManager.openImageFor(track: track, style: self.traitCollection.userInterfaceStyle)
    }
    
    func styleString(unstyledString:String, substrings:[String]) -> NSAttributedString {
        let styledText = NSMutableAttributedString.init(string:unstyledString)

        for subs in substrings {
            let index = find(char: subs, in: unstyledString)

            if let index = index {
                setStyle(text: styledText, range: NSMakeRange(index, subs.count))
            }
        }
        return styledText
    }
    
    func setStyle(text:NSMutableAttributedString, range:NSRange) {
        text.setAttributes([ .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                                  .foregroundColor: UIColor.secondaryLabel],
                                   range: range)

    }
    
    func find(char:String, in string:String) -> Int? {
        let range = string.range(of: char)
        guard let newRange = range else {
            return nil
        }
        let index: Int = string.distance(from: string.startIndex, to: newRange.lowerBound)
        return index
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
