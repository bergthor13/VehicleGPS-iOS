//
//  VGHistoryTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 15/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers


class VGHistoryTableViewController: UITableViewController {
    var tracks = [VGTrack]() {
        didSet {
            DispatchQueue.main.async {
                self.segmentChanged(id: self.historyHeader.sortingSegment.selectedSegmentIndex)
            }
        }
    }
    let dateFormatter = DateFormatter()
    let numberFormatter = NumberFormatter()
    var dataStore: VGDataStore!
    var emptyLabel: UILabel!
    var historyHeader: VGHistoryHeader!
    var allTracksDataSource: VGHistoryAllTracksDataSource!
    
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
        self.tableView.register(VGHistoryTableViewCell.nib, forCellReuseIdentifier: VGHistoryTableViewCell.identifier)
        self.tableView.register(VGLogsTableViewCell.nib, forCellReuseIdentifier: VGLogsTableViewCell.identifier)
        self.tableView.register(VGLogHeaderView.nib, forHeaderFooterViewReuseIdentifier: VGLogHeaderView.identifier)
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
            emptyLabel = VGListEmptyLabel(text: Strings.noLogs,
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
        title = Strings.titles.logs
        self.navigationController?.navigationBar.prefersLargeTitles = true
        tabBarItem = UITabBarItem(title: Strings.titles.logs,
                                  image: Icons.history,
                                  tag: 0)
        allTracksDataSource = VGHistoryAllTracksDataSource(parentViewController: self)
        allTracksDataSource.tracks = self.tracks
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
        let importButtonItem = UIBarButtonItem(image: Icons.importFiles, style: .plain, target: self, action: #selector(self.importFiles))
        self.navigationItem.rightBarButtonItem = importButtonItem
        addObserver(selector: #selector(onLogsAdded(_:)), name: .logsAdded)


        
    }
    
    func addObserver(selector:Selector, name:Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    @objc func onLogsAdded(_ notification:Notification) {
        guard let newTracks = notification.object as? [VGTrack] else {
            return
        }
        
        for track in newTracks {
            self.tracks.append(track)
        }
        

//        DispatchQueue.main.async {
//            self.tableView.reloadData()
//            if self.tracks.count > 0 {
//                self.emptyLabel.isHidden = true
//                self.tableView.separatorStyle = .singleLine
//            } else {
//                self.emptyLabel.isHidden = false
//                self.tableView.separatorStyle = .none
//            }
//        }
        
        
    }

    
    @objc func importFiles(_ sender:UIBarButtonItem) {
        let supportedTypes: [UTType] = [UTType(filenameExtension: "gpx")!, UTType(filenameExtension: "csv")!]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        dataStore.getAllTracks(
            onSuccess: { (tracks) in
                self.tracks = tracks
                if self.historySections.count > 0 {
                    self.emptyLabel.isHidden = true
                }
            },
            onFailure: { (error) in
                print(error)
            }
        )
        super.viewWillAppear(animated)
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            switch id {
                case SegmentType.day.rawValue:
                    self.historySections = self.getDayDictionary(tracks: self.tracks)
                case SegmentType.month.rawValue:
                    self.historySections = self.getMonthDictionary(tracks: self.tracks)
                case SegmentType.year.rawValue:
                    self.historySections = self.getYearDictionary(tracks: self.tracks)
                case SegmentType.allTracks.rawValue:
                    self.allTracksDataSource.tracks = self.tracks
                    break
                default:
                    break
            }
            DispatchQueue.main.async {
                if id == SegmentType.allTracks.rawValue {
                    self.tableView.dataSource = self.allTracksDataSource
                    self.tableView.delegate = self.allTracksDataSource
                } else {
                    self.tableView.dataSource = self
                    self.tableView.delegate = self
                }
                self.tableView.reloadData()
            }
        }

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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGHistoryTableViewCell.identifier, for: indexPath) as? VGHistoryTableViewCell else {
            return UITableViewCell()
        }
        
        if historyHeader.sortingSegment.selectedSegmentIndex == SegmentType.allTracks.rawValue {
            return VGLogsTableViewCell()
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
        
        let localizedText = Strings.logs
        let localizedSize = localizedText.count
        unformattedDistance = String(summary.trackCount) + " " + localizedText
        distanceText = NSMutableAttributedString.init(string: unformattedDistance)
        
        let scaledTrackFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let fontTrackMetrics = UIFontMetrics(forTextStyle: .body)
        
        distanceText.setAttributes([NSAttributedString.Key.font: fontTrackMetrics.scaledFont(for: scaledTrackFont),
                                  NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel],
                                   range: NSMakeRange(unformattedDistance.count-localizedSize, localizedSize))
        cell.lblTripCount.attributedText = distanceText
        cell.lblDate.text = summary.dateDescription
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tracksSummary = historySections[indexPath.section].summaries[indexPath.row]
        let historyDetails = VGHistoryDetailsTableViewController(style: .plain)
        historyDetails.tracksSummary = tracksSummary
        navigationController?.pushViewController(historyDetails, animated: true)
    }
}

extension VGHistoryTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let importController = VGImportFileTableViewController(style: .insetGrouped, fileUrls: urls)
        let navController = UINavigationController(rootViewController: importController)
        present(navController, animated: true)
    }
}
