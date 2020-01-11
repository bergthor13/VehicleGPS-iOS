//
//  VGHistoryTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 15/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGHistoryTableViewController: UITableViewController {
    var tracks = [VGTrack]()
    let df = DateFormatter()
    let nf = NumberFormatter()

    var historySections = [HistorySection]() {
        didSet {
            for section in historySections {
                section.summaries.sort { (summ1, summ2) -> Bool in
                    return summ1.summaryID > summ2.summaryID
                }
            }
            historySections.sort { (sect1, sect2) -> Bool in
                return sect1.sectionID > sect2.sectionID
            }
        }
    }

    fileprivate func registerCells() {
        self.tableView.register(UINib(nibName: "HistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "HistoryCell")
        self.tableView.register(UINib(nibName: "HistoryHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "HistoryHeader")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Saga"
        df.locale = Locale(identifier: "is_IS")
        
        nf.locale = Locale.current
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        nf.usesGroupingSeparator = true
        nf.numberStyle = .decimal

        registerCells()
        let dataStore = (UIApplication.shared.delegate as! AppDelegate).dataStore!
        tracks = dataStore.getAllTracks()
        historySections = getMonthDictionary(tracks: tracks)
    }
    
    func getYearDictionary(tracks:[VGTrack]) -> [HistorySection] {
        var result = [HistorySection]()
        for track in tracks {
            let sectionKey = "AllYears"
            let summaryKey = String(track.isoStartTime.prefix(4))
            
            var section: HistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = HistorySection(title:"")
                section?.sectionID = sectionKey
                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = TracksSummary(title:summaryKey)
                df.dateFormat = "yyyy"
                let date = df.date(from: summaryKey)
                df.dateFormat = "YYYY"
                summary!.dateDescription = df.string(from: date!)
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
        }
        return result
    }
    
    func getMonthDictionary(tracks:[VGTrack]) -> [HistorySection] {
        var result = [HistorySection]()
        for track in tracks {
            let sectionKey = String(track.isoStartTime.prefix(4))
            let summaryKey = String(track.isoStartTime.prefix(7))
            
            var section: HistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = HistorySection(title:sectionKey)
                df.dateFormat = "yyyy"
                let date = df.date(from: sectionKey)
                df.dateFormat = "YYYY"
                section!.dateDescription = df.string(from: date!)

                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = TracksSummary(title:summaryKey)
                df.dateFormat = "yyyy-MM"
                let date = df.date(from: summaryKey)
                df.dateFormat = "MMMM YYYY"
                summary!.dateDescription = df.string(from: date!)
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
        }
        return result
    }
    
    func getDayDictionary(tracks:[VGTrack]) -> [HistorySection] {
        var result = [HistorySection]()
        for track in tracks {
            let sectionKey = String(track.isoStartTime.prefix(7))
            let summaryKey = String(track.isoStartTime.prefix(10))
            
            var section: HistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = HistorySection(title:sectionKey)
                df.dateFormat = "yyyy-MM"
                let date = df.date(from: sectionKey)
                df.dateFormat = "MMMM YYYY"
                section!.dateDescription = df.string(from: date!)

                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = TracksSummary(title:summaryKey)
                df.dateFormat = "yyyy-MM-dd"
                let date = df.date(from: summaryKey)
                df.dateStyle = .long
                summary!.dateDescription = df.string(from: date!)
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
        }
        return result
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HistoryHeader") as! HistoryHeader
            view.historyTableViewController = self
            return view
        }
        return nil
    }
    
    func segmentChanged(id:Int) {
        if id == 0 { // Day
            historySections = getDayDictionary(tracks: tracks)
        } else if id == 1 { // Month
            historySections = getMonthDictionary(tracks: tracks)
        } else if id == 2 { // Year
            historySections = getYearDictionary(tracks: tracks)
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return historySections[section].dateDescription
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return historySections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historySections[section].summaries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryTableViewCell
        let section = historySections[indexPath.section]
        let summary = section.summaries[indexPath.row]
        
        var unformattedDistance = String(nf.string(from: NSNumber(value: summary.distance))!) + " km"
        var distanceText = NSMutableAttributedString.init(string:unformattedDistance)
        
        distanceText.setAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                                  NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel],
                                   range: NSMakeRange(unformattedDistance.count-3, 3))
        cell.lblDistance.attributedText = distanceText
        
        
        unformattedDistance = String(summary.trackCount) + " ferðir"
        distanceText = NSMutableAttributedString.init(string:unformattedDistance)
        
        distanceText.setAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                                  NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel],
                                   range: NSMakeRange(unformattedDistance.count-7, 7))
        cell.lblTripCount.attributedText = distanceText
        cell.lblDate.text = summary.dateDescription
        
        return cell
    }
}
