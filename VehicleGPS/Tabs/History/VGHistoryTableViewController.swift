//
//  VGHistoryTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 15/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import Pulley
import EventKit


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
    let vgGPXGenerator = VGGPXGenerator()
    
    var importTapRecognizer: UITapGestureRecognizer!
    
    // MARK: Toolbar Buttons
    var toolbarButtonShare: UIBarButtonItem!
    var toolbarButtonDelete: UIBarButtonItem!
    var toolbarButtonSelectVehicle: UIBarButtonItem!
    var toolbarButtonStartEditor: UIBarButtonItem!

    
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
            
            emptyLabel = VGListEmptyLabel(text: Strings.noLogs + "\n\n" + Strings.tapHereImport,
                                          containerView: self.view,
                                          navigationBar: navigationController!.navigationBar,
                                          tabBar: delegate.tabController.tabBar)
            emptyLabel.numberOfLines = 0
        }
        view.addSubview(emptyLabel)
        emptyLabel.isEnabled = true
        importTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImportFiles(_:)))
        importTapRecognizer.numberOfTapsRequired = 1
        emptyLabel.isUserInteractionEnabled = true
        emptyLabel.addGestureRecognizer(importTapRecognizer)

    }
    
    
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        initializeTableViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeTableViewController()

    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if !editing {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    func showEditToolbar() {
        navigationController?.setToolbarHidden(false, animated: true)

    }
    
    func hideEditToolbar() {
        navigationController?.setToolbarHidden(true, animated: true)

    }

    func initializeTableViewController() {
        title = Strings.titles.logs
        self.navigationController?.navigationBar.prefersLargeTitles = false
        tabBarItem = UITabBarItem(title: Strings.titles.logs,
                                  image: Icons.history,
                                  tag: 0)
        allTracksDataSource = VGHistoryAllTracksDataSource(parentViewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        configureFormatters()
        configureEmptyListLabel()
        self.toolbarButtonShare = UIBarButtonItem(title: nil, image: Icons.share, primaryAction: nil, menu: shareTracks())
        self.toolbarButtonDelete = UIBarButtonItem(image: Icons.delete, style: .plain, target: self, action: #selector(deleteTracks(_:)))
        self.toolbarButtonSelectVehicle = UIBarButtonItem(image: Icons.vehicle, style: .plain, target: self, action: #selector(selectVehicle(_:)))
        self.toolbarButtonStartEditor = UIBarButtonItem(image: Icons.editor, style: .plain, target: self, action: #selector(startEditor(_:)))

        
        configureToolbar()
        
        
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
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(image:Icons.moreActions, primaryAction: nil, menu: createMenu()), UIBarButtonItem(image:Icons.filter, primaryAction: nil, menu: createFilterMenu())]
        self.navigationItem.leftBarButtonItem = editButtonItem
        addObserver(selector: #selector(onLogsAdded(_:)), name: .logsAdded)

        
        tableView.allowsMultipleSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    func createFilterMenu() -> UIMenu {
        let tagFilter = UIAction(title: Strings.filterByTags, image: Icons.tag) { (action) in
            
        }
        let dateFilter = UIAction(title: Strings.filterByDate, image: Icons.calendar) { (action) in
            
        }
        return UIMenu(title: Strings.filterBy, children: [tagFilter, dateFilter])

    }
    
    // MARK: - Button Actions
    // MARK: Toolbar
    
    @objc func selectVehicle(_ sender:UIBarButtonItem) {
        print("Selecting Vehicle")
    }
    
    @objc func deleteTracks(_ sender:UIBarButtonItem) {
        print("DELETING SELECTED TRACKS")
    }
    
    @objc func didTapImportFiles(_ sender:Any) {
        importFiles()
    }
    
    
    @objc func startEditor(_ sender:UIBarButtonItem) {
        let selTracks = getSelectedTracks()
        for (index, track) in selTracks.enumerated() {
            dataStore.getDataPointsForTrack(with: track.id!) { (points) in
                selTracks[index].trackPoints = points
                //editor.tracks = selTracks
            } onFailure: { (error) in
                self.appDelegate.display(error: error)
            }

        }
        
    }
    
    func getSelectedTracks() -> [VGTrack]{
        guard let dataSource = tableView.dataSource as? VGHistoryAllTracksDataSource else {
            return []
        }
        
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return []
        }
        
        var selectedTracks = [VGTrack]()
        for indexPath in indexPaths {
            guard let track = dataSource.getTrackAt(indexPath: indexPath) else {
                continue
            }
            selectedTracks.append(track)
        }
        return selectedTracks
    }
    
    func shareTracks() -> UIMenu? {
        let exportGPX = UIAction(title: "Export to GPX file", image: Icons.share, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { (action) in
            self.exportTracks()
        }
        let addToCalendar = UIAction(title: "Add to Calendar", image: Icons.calendar, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { (action) in
            self.exportToCalendar()
        }

        return UIMenu(title: "Share tracks", image: nil, identifier: nil, options: .displayInline, children: [exportGPX, addToCalendar])
    }
    
    func insertEvent(store: EKEventStore) {
        DispatchQueue.main.async {
            guard let dataSource = self.tableView.dataSource as? VGHistoryAllTracksDataSource else {
                return
            }
            guard let indexPaths = self.tableView.indexPathsForSelectedRows else {
                return
            }
            for indexPath in indexPaths {
                
                guard let track = dataSource.getTrackAt(indexPath: indexPath) else {
                    continue
                }
                let event:EKEvent = EKEvent(eventStore: store)
                let startDate = track.timeStart
                let endDate = startDate!.addingTimeInterval(track.duration)
                event.title = "Track"
                event.startDate = startDate
                event.endDate = endDate
                event.location = track.prettyDescription()
                event.calendar = store.defaultCalendarForNewEvents
                
                do {
                    try store.save(event, span: .thisEvent)
                } catch let error as NSError {
                print("failed to save event with error : \(error)")
                }
                print("Saved Event")

            }
        }
        
        
    }
    
    func exportToCalendar() {
            // 1
            let eventStore = EKEventStore()
                
            // 2
            switch EKEventStore.authorizationStatus(for: .event) {
            case .authorized:
                insertEvent(store: eventStore)
                case .denied:
                    print("Access denied")
                case .notDetermined:
                // 3
                    eventStore.requestAccess(to: .event, completion:
                      {[weak self] (granted: Bool, error: Error?) -> Void in
                          if granted {
                            self!.insertEvent(store: eventStore)
                          } else {
                                print("Access denied")
                          }
                    })
                    default:
                        print("Case default")
            }
    }
    
    @objc func exportTracks(_ sender:UIBarButtonItem? = nil) {
        guard let dataSource = tableView.dataSource as? VGHistoryAllTracksDataSource else {
            return
        }
        var tracks = [VGTrack]()
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        for indexPath in indexPaths {
            
            guard let track = dataSource.getTrackAt(indexPath: indexPath) else {
                continue
            }
            tracks.append(track)
        }
        
        let dpGroup = DispatchGroup()
        for track in tracks {
            dpGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataStore.getDataPointsForTrack(with: track.id!) { (dataPoints) in
                    track.trackPoints = dataPoints
                    dpGroup.leave()
                } onFailure: { (error) in
                    self.appDelegate.display(error: error)
                    dpGroup.leave()
                }
            }
        }
        dpGroup.wait()
        if let fileUrl = self.vgGPXGenerator.generateGPXFor(tracks: tracks) {
            let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = self.toolbarButtonShare
            self.present(activityVC, animated: true, completion: nil)
        } else {
            //displayErrorAlert(title: "Could not generate GPX", message: "An error occurred and generating a GPX file failed.")
        }
    }
    
    fileprivate func configureToolbar() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarButtonDelete.tintColor = .red
        setToolbarItems([toolbarButtonShare, space, toolbarButtonSelectVehicle, space, toolbarButtonStartEditor, space, toolbarButtonDelete], animated: false)
        
    }
    
    func createMenu() -> UIMenu {
        let mapAction = UIAction(title: Strings.titles.importFiles, image: Icons.importFiles) { (action) in
            self.importFiles()
        }
        return UIMenu(title: "", children: [mapAction])
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

    
    func importFiles() {
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
                self.appDelegate.display(error: error)
            }
        )
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.tableHeaderView?.frame.size = CGSize(width: tableView.frame.width, height: 50)
        var height: CGFloat = 0.0
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            height = view.frame.height-(navigationController?.navigationBar.frame.height)!
            return
        }
        height = view.frame.height-(navigationController?.navigationBar.frame.height)!-delegate.tabController.tabBar.frame.height
        let frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: height)
        
        emptyLabel.frame = frame
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
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
                    break
                default:
                    break
            }
            DispatchQueue.main.async {
                if id == SegmentType.allTracks.rawValue {
                    self.tableView.dataSource = self.allTracksDataSource
                    self.tableView.delegate = self.allTracksDataSource
                    self.allTracksDataSource.tableView = self.tableView
                    (self.allTracksDataSource.sections, self.allTracksDataSource.tracksDictionary) = LogDateSplitter.splitLogsByDate(trackList: self.tracks)

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
        if self.historySections.count > 0 {
            self.emptyLabel.isHidden = true
        } else {
            self.emptyLabel.isHidden = false
        }
        return self.historySections.count
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
        
        if tableView.isEditing {
            guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
                return
            }
            
            if selectedIndexPaths.count == 0 {
                self.hideEditToolbar()
            } else {
                self.showEditToolbar()
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let tracksSummary = historySections[indexPath.section].summaries[indexPath.row]
            let historyDetails = VGHistoryDetailsTableViewController(style: .plain)
            historyDetails.tracksSummary = tracksSummary
            navigationController?.pushViewController(historyDetails, animated: true)
        }        
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            guard let _ = tableView.indexPathsForSelectedRows else {
                self.hideEditToolbar()
                return
            }

        }
    }
    
}

extension VGHistoryTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let importController = VGImportFileTableViewController(style: .insetGrouped, fileUrls: urls)
        let navController = UINavigationController(rootViewController: importController)
        present(navController, animated: true)
    }
}

extension VGHistoryTableViewController: PulleyDrawerViewControllerDelegate {
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 50.0
    }
}
