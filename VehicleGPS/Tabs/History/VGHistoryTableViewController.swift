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
    var historyHeader: VGHistoryHeader!

    var historySections = [VGHistorySection]() {
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
        let historyTableViewCellNib = UINib(nibName: "VGHistoryTableViewCell", bundle: nil)
        self.tableView.register(historyTableViewCellNib, forCellReuseIdentifier: "HistoryCell")
    }
    
    fileprivate func configureFormatters() {
        numberFormatter.locale = Locale.current
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = .decimal
    }
    
    fileprivate func configureEmptyListLabel() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            emptyLabel = VGListEmptyLabel(text: NSLocalizedString("Engin saga", comment: ""),
                                          containerView: self.view,
                                          navigationBar: navigationController!.navigationBar,
                                          tabBar: delegate.tabController.tabBar)
        }
        view.addSubview(emptyLabel)
    }
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        initializeTableViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeTableViewController()

    }

    func initializeTableViewController() {
        title = NSLocalizedString("Saga", comment: "Vehicles Title")
        self.navigationController?.navigationBar.prefersLargeTitles = true
        tabBarItem = UITabBarItem(title: NSLocalizedString("Saga", comment: "Vehicles Title"),
                                  image: UIImage(systemName: "memories"),
                                  tag: 0)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        configureFormatters()
        configureEmptyListLabel()
        
        historyHeader = VGHistoryHeader(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        historyHeader.historyTableViewController = self
        
        tableView.tableHeaderView = historyHeader
        
        // 3.
        historyHeader.centerXAnchor.constraint(equalTo: self.tableView.centerXAnchor).isActive = true
        historyHeader.widthAnchor.constraint(equalTo: self.tableView.widthAnchor).isActive = true
        historyHeader.topAnchor.constraint(equalTo: self.tableView.topAnchor).isActive = true
        // 4.
        self.tableView.tableHeaderView?.layoutIfNeeded()
        self.tableView.tableHeaderView = self.tableView.tableHeaderView

        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
        }
        
        tracks = dataStore.getAllTracks()
        historySections = getMonthDictionary(tracks: tracks)
        if historySections.count > 0 {
            emptyLabel.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tracks = dataStore.getAllTracks()
        historySections = getMonthDictionary(tracks: tracks)
        segmentChanged(id: historyHeader.sortingSegment.selectedSegmentIndex)
        if historySections.count > 0 {
            emptyLabel.isHidden = true
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.tableHeaderView?.frame.size = CGSize(width: tableView.frame.width, height: 50)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func getYearDictionary(tracks: [VGTrack]) -> [VGHistorySection] {
        var result = [VGHistorySection]()
        for track in tracks {
            let sectionKey = "AllYears"
            let summaryKey = String(track.isoStartTime.prefix(4))
            
            var section: VGHistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = VGHistorySection(title: "")
                section?.sectionID = sectionKey
                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = VGTracksSummary(title:summaryKey)
                dateFormatter.dateFormat = "yyyy"
                let date = dateFormatter.date(from: summaryKey)
                dateFormatter.dateFormat = "yyyy"
                if let date = date {
                    summary!.dateDescription = dateFormatter.string(from: date)
                }
                
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
            summary?.tracks.append(track)
        }
        return result
    }
    
    func getMonthDictionary(tracks: [VGTrack]) -> [VGHistorySection] {
        var result = [VGHistorySection]()
        for track in tracks {
            let sectionKey = String(track.isoStartTime.prefix(4))
            let summaryKey = String(track.isoStartTime.prefix(7))
            
            var section: VGHistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = VGHistorySection(title:sectionKey)
                dateFormatter.dateFormat = "yyyy"
                let date = dateFormatter.date(from: sectionKey)
                dateFormatter.dateFormat = "yyyy"
                if let date = date {
                    section!.dateDescription = dateFormatter.string(from: date)
                }
                

                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = VGTracksSummary(title: summaryKey)
                dateFormatter.dateFormat = "yyyy-MM"
                let date = dateFormatter.date(from: summaryKey)
                dateFormatter.dateFormat = "MMMM yyyy"
                if let date = date {
                    summary!.dateDescription = dateFormatter.string(from: date)
                }
                
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
            summary?.tracks.append(track)
        }
        return result
    }
    
    func getDayDictionary(tracks: [VGTrack]) -> [VGHistorySection] {
        var result = [VGHistorySection]()
        for track in tracks {
            let sectionKey = String(track.isoStartTime.prefix(7))
            let summaryKey = String(track.isoStartTime.prefix(10))
            
            var section: VGHistorySection?
            section = result.filter { (sect) -> Bool in
                return sect.sectionID == sectionKey
            }.first
            
            if section == nil {
                section = VGHistorySection(title: sectionKey)
                dateFormatter.dateFormat = "yyyy-MM"
                let date = dateFormatter.date(from: sectionKey)
                dateFormatter.dateFormat = "MMMM yyyy"
                if let date = date {
                    section!.dateDescription = dateFormatter.string(from: date)
                }
                

                result.append(section!)
            }
            
            var summary = section?.summaries.filter({ (summ) -> Bool in
                return summ.summaryID == summaryKey
                }).first
            
            if summary == nil {
                summary = VGTracksSummary(title: summaryKey)
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: summaryKey)
                dateFormatter.dateStyle = .long
                if let date = date {
                    summary!.dateDescription = dateFormatter.string(from: date)
                }
                
                section?.summaries.append(summary!)
            }
            
            summary!.distance   += track.distance
            summary!.trackCount += 1
            summary?.tracks.append(track)
        }
        return result
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? VGHistoryTableViewCell else {
            return UITableViewCell()
        }
        let section = historySections[indexPath.section]
        let summary = section.summaries[indexPath.row]
        
        var unformattedDistance = String(numberFormatter.string(from: NSNumber(value: summary.distance))!) + " km"
        var distanceText = NSMutableAttributedString.init(string: unformattedDistance)
        
        
        let scaledFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)

        distanceText.setAttributes([NSAttributedString.Key.font: fontMetrics.scaledFont(for: scaledFont),
                                  NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel],
                                   range: NSMakeRange(unformattedDistance.count-3, 3))
        cell.lblDistance.attributedText = distanceText
        
        unformattedDistance = String(summary.trackCount) + " ferlar"
        distanceText = NSMutableAttributedString.init(string: unformattedDistance)
        
        let scaledTrackFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let fontTrackMetrics = UIFontMetrics(forTextStyle: .body)
        
        distanceText.setAttributes([NSAttributedString.Key.font: fontTrackMetrics.scaledFont(for: scaledTrackFont),
                                  NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel],
                                   range: NSMakeRange(unformattedDistance.count-7, 7))
        cell.lblTripCount.attributedText = distanceText
        cell.lblDate.text = summary.dateDescription
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tracksSummary = historySections[indexPath.section].summaries[indexPath.row]
        let historyDetails = VGHistoryDetailsTableViewController(style: .insetGrouped)
        historyDetails.tracksSummary = tracksSummary
        navigationController?.pushViewController(historyDetails, animated: true)
    }
}
