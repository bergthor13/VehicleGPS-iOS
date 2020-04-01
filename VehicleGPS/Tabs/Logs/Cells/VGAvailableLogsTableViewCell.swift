//
//  LogsTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGAvailableLogsTableViewCell: UITableViewCell {

    @IBOutlet weak var lblTimeOfDay: UILabel!
    @IBOutlet weak var lblFileSize: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var onDeviceIndicator: UIImageView!
    
    static let identifier = "AvailableLogsCell"
    static let nibName = "VGAvailableLogsTableViewCell"
    static let nib = UINib(nibName: VGAvailableLogsTableViewCell.nibName, bundle: nil)

    
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
        
    }
    
    func show(track: VGTrack) {
        currentTrack = track
        formatter.dateFormat = "HH:mm:ss"
        if track.timeStart == nil {
            if let fileDate = fileNameToDate(dateString: track.fileName) {
                self.lblTimeOfDay!.text = formatter.string(from: fileDate)
            }
        } else {
            self.lblTimeOfDay!.text = formatter.string(from: track.timeStart!)
        }
        
        let fileSizeWithUnit = ByteCountFormatter.string(
                                                  fromByteCount: Int64(truncating: NSNumber(value: track.fileSize)),
                                                  countStyle: .file)
        
        self.lblFileSize!.text = fileSizeWithUnit
        if track.isLocal {
            onDeviceIndicator.isHidden = false
        } else {
            onDeviceIndicator.isHidden = true
        }
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

        // Configure the view for the selected state
    }

}
