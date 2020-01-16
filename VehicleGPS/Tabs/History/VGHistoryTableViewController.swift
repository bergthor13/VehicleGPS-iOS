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
    let dateFormatter = DateFormatter()
    let numberFormatter = NumberFormatter()
    var dataStore: VGDataStore!
    var emptyLabel: UILabel!

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
        let historyTableViewCellNib = UINib(nibName: "HistoryTableViewCell", bundle: nil)
        let historyHeaderNib = UINib(nibName: "HistoryHeader", bundle: nil)
        
        self.tableView.register(historyTableViewCellNib, forCellReuseIdentifier: "HistoryCell")
        self.tableView.register(historyHeaderNib, forHeaderFooterViewReuseIdentifier: "HistoryHeader")
    }
    
    fileprivate func configureFormatters() {
        numberFormatter.locale = Locale.current
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = .decimal
    }
    
    fileprivate func configureEmptyListLabel() {
        var height: CGFloat = 0.0
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            height = view.frame.height-(navigationController?.navigationBar.frame.height)!
            return
        }
        height = view.frame.height-(navigationController?.navigationBar.frame.height)!-delegate.tabController.tabBar.frame.height
        let frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: height)
        
        emptyLabel = UILabel(frame: frame)
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 22)
        emptyLabel.text = "Engin saga"
        view.addSubview(emptyLabel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Saga"
        registerCells()
        configureFormatters()
        configureEmptyListLabel()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
        }
        
        tracks = dataStore.getAllTracks()
        historySections = getMonthDictionary(tracks: tracks)
        if historySections.count > 0 {
            emptyLabel.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func getYearDictionary(tracks: [VGTrack]) -> [HistorySection] {
        var result = [HistorySection]()
        for track in tracks {
            let sectionKey = "AllYears"
            let summaryKey = String(track.isoStartTime.prefix(4))
            
            var section: HistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = HistorySection(title: "")
                section?.sectionID = sectionKey
                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = TracksSummary(title:summaryKey)
                dateFormatter.dateFormat = "yyyy"
                let date = dateFormatter.date(from: summaryKey)
                dateFormatter.dateFormat = "YYYY"
                summary!.dateDescription = dateFormatter.string(from: date!)
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
            summary?.tracks.append(track)
        }
        return result
    }
    
    func getMonthDictionary(tracks: [VGTrack]) -> [HistorySection] {
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
                dateFormatter.dateFormat = "yyyy"
                let date = dateFormatter.date(from: sectionKey)
                dateFormatter.dateFormat = "YYYY"
                section!.dateDescription = dateFormatter.string(from: date!)

                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = TracksSummary(title: summaryKey)
                dateFormatter.dateFormat = "yyyy-MM"
                let date = dateFormatter.date(from: summaryKey)
                dateFormatter.dateFormat = "MMMM YYYY"
                summary!.dateDescription = dateFormatter.string(from: date!)
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
            summary?.tracks.append(track)
        }
        return result
    }
    
    func getDayDictionary(tracks: [VGTrack]) -> [HistorySection] {
        var result = [HistorySection]()
        for track in tracks {
            let sectionKey = String(track.isoStartTime.prefix(7))
            let summaryKey = String(track.isoStartTime.prefix(10))
            
            var section: HistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = HistorySection(title: sectionKey)
                dateFormatter.dateFormat = "yyyy-MM"
                let date = dateFormatter.date(from: sectionKey)
                dateFormatter.dateFormat = "MMMM YYYY"
                section!.dateDescription = dateFormatter.string(from: date!)

                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = TracksSummary(title: summaryKey)
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: summaryKey)
                dateFormatter.dateStyle = .long
                summary!.dateDescription = dateFormatter.string(from: date!)
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
            summary?.tracks.append(track)
        }
        return result
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HistoryHeader") as? HistoryHeader else {
                return UIView()
            }
            
            view.historyTableViewController = self
            return view
        }
        return nil
    }
    
    func segmentChanged(id: Int) {
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? HistoryTableViewCell else {
            return UITableViewCell()
        }
        let section = historySections[indexPath.section]
        let summary = section.summaries[indexPath.row]
        
        var unformattedDistance = String(numberFormatter.string(from: NSNumber(value: summary.distance))!) + " km"
        var distanceText = NSMutableAttributedString.init(string: unformattedDistance)
        
        distanceText.setAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                                  NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel],
                                   range: NSMakeRange(unformattedDistance.count-3, 3))
        cell.lblDistance.attributedText = distanceText
        
        unformattedDistance = String(summary.trackCount) + " ferðir"
        distanceText = NSMutableAttributedString.init(string: unformattedDistance)
        
        distanceText.setAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                                  NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel],
                                   range: NSMakeRange(unformattedDistance.count-7, 7))
        cell.lblTripCount.attributedText = distanceText
        cell.lblDate.text = summary.dateDescription
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tracksSummary = historySections[indexPath.section].summaries[indexPath.row]
        let historyDetails = HistoryDetailsTableViewController(style: .insetGrouped)
        historyDetails.tracksSummary = tracksSummary
        navigationController?.pushViewController(historyDetails, animated: true)
    }
}
