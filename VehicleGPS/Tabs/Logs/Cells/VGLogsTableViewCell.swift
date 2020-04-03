//
//  LogsTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

protocol DisplaySelectVehicleProtocol {
    func didTapVehicle(track:VGTrack)
}

class VGLogsTableViewCell: UITableViewCell {

    @IBOutlet weak var btnVehicle: UIButton!
    @IBOutlet weak var trackView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblTimeStart: UILabel!
    @IBOutlet weak var lblFileSize: UILabel!
    @IBOutlet weak var lblVehicle: UILabel!
    @IBOutlet weak var imgVehicle: UIImageView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!
    static let identifier = "LogsCell"
    static let nibName = "VGLogsTableViewCell"
    static let nib = UINib(nibName: VGLogsTableViewCell.nibName, bundle: nil)
    var delegate: DisplaySelectVehicleProtocol!
    var vgFileManager: VGFileManager!
    var currentTrack: VGTrack?
    let formatter = DateFormatter()
    let distanceFormatter = VGDistanceFormatter()
    let form = VGDurationFormatter()
    
    func update(progress: Double) {
        let viewWidth = self.frame.width
        progressViewWidthConstraint.constant = viewWidth*CGFloat(progress)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.vgFileManager = appDelegate.fileManager
        }
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onVehicleUpdated(_:)), name: .vehicleUpdated, object: nil)


    }
    
    @objc func onVehicleUpdated(_ notification:Notification) {
        guard let updatedVehicle = notification.object as? VGVehicle else {
            return
        }
        
        guard let currentTrack = currentTrack else {
            return
        }
        
        guard let vehicle = currentTrack.vehicle else {
            return
        }
        
        if vehicle.id == updatedVehicle.id {
            lblVehicle.text = updatedVehicle.name
        }
        
    }

    
    
    @objc func preferredContentSizeChanged(_ sender:Any) {
        lblVehicle.sizeToFit()
    }
    
    func show(track: VGTrack) {
        currentTrack = track
        formatter.dateFormat = "HH:mm:ss"
        if track.timeStart == nil {
            if let fileDate = fileNameToDate(dateString: track.fileName) {
                self.lblTimeStart!.text = formatter.string(from: fileDate)
            }
        } else {
            self.lblTimeStart!.text = formatter.string(from: track.timeStart!)
        }
        
        let fileSizeWithUnit = ByteCountFormatter.string(
                                                  fromByteCount: Int64(truncating: NSNumber(value: track.fileSize)),
                                                  countStyle: .file)
        
        self.lblFileSize!.text = fileSizeWithUnit
        
        self.lblDistance.text = distanceFormatter.string(fromMeters: track.distance*1000)
                
        self.lblDistance.attributedText = styleString(unstyledString: self.lblDistance.text!, substrings: [distanceFormatter.unitString(fromMeters: track.distance*1000, usedUnit: nil)])
        
        let formattedDuration = form.string(from: track.duration)
        
        self.lblDuration.attributedText = styleString(unstyledString: formattedDuration!, substrings: ["h", "m", "s"])

        trackView.image = vgFileManager.openImageFor(track: track, style: self.traitCollection.userInterfaceStyle)
        trackView.layer.borderWidth = 0.5
        trackView.layer.borderColor = UIColor.secondaryLabel.cgColor
        if let vehicle = track.vehicle {
            lblVehicle.text = vehicle.name
        } else {
            lblVehicle.text = Strings.noVehicle
        }
        lblVehicle.sizeToFit()
        
        if track.beingProcessed {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }

    }
    
    @IBAction func didTapVehicle(_ sender: Any) {
        delegate.didTapVehicle(track: currentTrack!)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard let track = currentTrack else {return}
        trackView.layer.borderColor = UIColor.secondaryLabel.cgColor
        trackView.image = vgFileManager.openImageFor(track: track, style: self.traitCollection.userInterfaceStyle)
    }
    
    func styleString(unstyledString: String, substrings: [String]) -> NSAttributedString {
        let styledText = NSMutableAttributedString.init(string: unstyledString)

        for subs in substrings {
            let index = find(char: subs, in: unstyledString)

            if let index = index {
                setStyle(text: styledText, range: NSMakeRange(index, subs.count))
            }
        }
        return styledText
    }
    
    func setStyle(text: NSMutableAttributedString, range: NSRange) {
        text.setAttributes([ .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                                  .foregroundColor: UIColor.secondaryLabel],
                                   range: range)
    }
    
    func find(char: String, in string: String) -> Int? {
        let range = string.range(of: char)
        guard let newRange = range else {
            return nil
        }
        let index: Int = string.distance(from: string.startIndex, to: newRange.lowerBound)
        return index
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
