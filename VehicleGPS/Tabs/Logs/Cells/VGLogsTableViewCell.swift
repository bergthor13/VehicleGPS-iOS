//
//  LogsTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

protocol DisplaySelectVehicleProtocol: AnyObject {
    func didTapVehicle(track: VGTrack, tappedView: UIView?)
}

protocol DisplaySelectTagsProtocol: AnyObject {
    func didTapTags(track: VGTrack, tappedView: UIView?)
}

class VGLogsTableViewCell: UITableViewCell {

    @IBOutlet weak var recDotView: UIView!
    @IBOutlet weak var recView: UIView!
    @IBOutlet weak var btnVehicle: UIButton!
    @IBOutlet weak var trackView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblTimeStart: UILabel!
    @IBOutlet weak var lblFileSize: UILabel!
    @IBOutlet weak var lblVehicle: UILabel!
    @IBOutlet weak var imgVehicle: UIImageView!
    @IBOutlet weak var vehicleHeight: NSLayoutConstraint!
    
    static let identifier = "LogsCell"
    static let nibName = "VGLogsTableViewCell"
    static let nib = UINib(nibName: VGLogsTableViewCell.nibName, bundle: nil)
    weak var delegate: DisplaySelectVehicleProtocol!
    var vgFileManager: VGFileManager!
    var vgDataStore: VGDataStore!
    var currentTrack: VGTrack?
    let formatter = DateFormatter()
    let form = VGDurationFormatter()
    let distanceFormatter = VGDistanceFormatter()
    var showVehicle = true {
        didSet {
            if showVehicle {
                vehicleHeight.constant = 20
                imgVehicle.isHidden = false
                lblVehicle.isHidden = false
            } else {
                vehicleHeight.constant = 0
                imgVehicle.isHidden = true
                lblVehicle.isHidden = true
            }
        }
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.vgFileManager = appDelegate.fileManager
            self.vgDataStore = appDelegate.dataStore
        }
        recView.layer.cornerRadius = recView.frame.width/2.0
        recDotView.layer.cornerRadius = recView.frame.width/2.0
            
        addObserver(selector: #selector(previewImageStarting(_:)), name: .previewImageStartingUpdate)
        addObserver(selector: #selector(previewImageStopping(_:)), name: .previewImageFinishingUpdate)
        addObserver(selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification)
        addObserver(selector: #selector(onVehicleUpdated(_:)), name: .vehicleUpdated)

    }
    
    func addObserver(selector: Selector, name: Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    @objc func previewImageStarting(_ notification: Notification) {
        guard let track = notification.object as? VGTrack else {
            return
        }
        if track.id != currentTrack?.id {
            return
        }
        
        DispatchQueue.main.async {
            if let track = self.currentTrack {
                track.beingProcessed = true
            }
            self.activityView.startAnimating()
        }
    }
    
    @objc func previewImageStopping(_ notification: Notification) {
        guard let updatedNotification = notification.object as? ImageUpdatedNotification else {
            return
        }
        if currentTrack?.id != updatedNotification.track.id {
            return
        }

        DispatchQueue.main.async {
            if self.traitCollection.userInterfaceStyle != updatedNotification.style {
                return
            }
            
            if let track = self.currentTrack {
                track.beingProcessed = false
            }
            self.activityView.stopAnimating()
            self.trackView.image = updatedNotification.image
        }

    }
    
    @objc func onVehicleUpdated(_ notification: Notification) {
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

    @objc func preferredContentSizeChanged(_ sender: Any) {
        lblVehicle.sizeToFit()
    }
    
    func show(track: VGTrack) {
        if #available(iOS 14, *) {
            imgVehicle.image = Icons.vehicle
        } else {
            imgVehicle.image = Icons.vehicleiOS13
        }
        currentTrack = track
        formatter.dateFormat = "HH:mm:ss"
        if track.timeStart == nil {
            if let fileDate = fileNameToDate(dateString: track.fileName) {
                self.lblTimeStart!.text = formatter.string(from: fileDate)
            }
        } else {
            self.lblTimeStart!.text = formatter.string(from: track.timeStart!)
        }
                
        self.lblFileSize!.text = String(track.dataPointCount)
        
        self.lblDistance.text = distanceFormatter.string(fromMeters: track.distance*1000)
                
        self.lblDistance.attributedText = styleString(unstyledString: self.lblDistance.text!, substrings: [distanceFormatter.unitString(fromMeters: track.distance*1000, usedUnit: nil)])
        
        let formattedDuration = form.string(from: track.duration)
        
        self.lblDuration.attributedText = styleString(unstyledString: formattedDuration!, substrings: ["h", "m", "s"])

        trackView.image = vgFileManager.getPreviewImage(for: track, with: self.traitCollection.userInterfaceStyle)
        if trackView.image == nil {
            loadPreviewImage(for: track)
        }
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
        if track.isRecording {
            animateRecording()
        } else {
            self.recView.isHidden = true
            self.recDotView.isHidden = true
        }
    }
    
    func loadPreviewImage(for track: VGTrack) {
        if track.mapPoints.count == 0 {
            VGSnapshotMaker(fileManager: self.vgFileManager, dataStore: self.vgDataStore).drawTrack(vgTrack: track) { image, style in
                DispatchQueue.main.async {
                    if style == self.traitCollection.userInterfaceStyle {
                        self.trackView.image = image
                    }
                }
                return nil
            }
        }
    }
    
    func animateRecording() {
        self.recView.isHidden = false
        self.recDotView.isHidden = false
        self.recView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        self.recView.alpha = 1
        
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .repeat], animations: {
            self.recView.transform = CGAffineTransform(scaleX: 3, y: 3)
            self.recView.alpha = 0
        }, completion: nil)

    }
    
    @IBAction func didTapVehicle(_ sender: Any) {
        guard let track = currentTrack else {
            return
        }
        
        guard let delegate = delegate else {
            return
        }
        delegate.didTapVehicle(track: track, tappedView: self.btnVehicle)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard let track = currentTrack else {return}
        trackView.layer.borderColor = UIColor.secondaryLabel.cgColor
        trackView.image = vgFileManager.getPreviewImage(for: track, with: self.traitCollection.userInterfaceStyle)
    }
    
    func styleString(unstyledString: String, substrings: [String]) -> NSAttributedString {
        let styledText = NSMutableAttributedString.init(string: unstyledString)

        for subs in substrings {
            let index = find(char: subs, in: unstyledString)

            if let index = index {
                setStyle(text: styledText, range: NSRange(location: index, length: subs.count))
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
}
