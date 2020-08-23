//
//  HistoryDetailsTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 13/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import MapKit

class VGHistoryDetailsTableViewController: UITableViewController {
    var tracksSummary: VGTracksSummary? {
        didSet {
            tracksSummary!.tracks.sort { (first, second) -> Bool in
                if first.timeStart != nil && second.timeStart != nil {
                    return first.timeStart! > second.timeStart!
                }
                return first.fileName > second.fileName
            }
        }
    }
    
    // MARK: Formatters
    let headerDateFormatter = VGHeaderDateFormatter()
    let dateParsingFormatter = VGDateParsingFormatter()

    var mapView: VGMapView!
    var dataStore: VGDataStore!
    var vgFileManager: VGFileManager!
    let vgGPXGenerator = VGGPXGenerator()

    var mapCell: UITableViewCell!
    
    var sections = [String]()
    var logDict = [String: [VGTrack]]()
    
    func addObserver(selector:Selector, name:Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObserver(selector: #selector(onVehicleAddedToLog(_:)), name: .vehicleAddedToTrack)
        addObserver(selector: #selector(onLogUpdated(_:)), name: .logUpdated)
        addObserver(selector: #selector(previewImageStarting(_:)), name: .previewImageStartingUpdate)
        addObserver(selector: #selector(previewImageStopping(_:)), name: .previewImageFinishingUpdate)

        if let tracksSummary = self.tracksSummary {
            title = tracksSummary.dateDescription
        }
        if let tracks = tracksSummary?.tracks {
            (self.sections, self.logDict) = LogDateSplitter.splitLogsByDate(trackList: tracks)
        }
        self.tableView.register(VGLogHeaderView.nib, forHeaderFooterViewReuseIdentifier: VGLogHeaderView.identifier)

        self.tableView.register(VGLogsTableViewCell.nib, forCellReuseIdentifier: VGLogsTableViewCell.identifier)
        navigationController?.navigationBar.prefersLargeTitles = false
        
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
            self.vgFileManager = appDelegate.fileManager
        }
        
        mapCell = UITableViewCell()
        mapView = VGMapView(frame: mapCell.contentView.frame)
        //mapView.activity
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapCell.contentView.addSubview(mapView)
        let layoutLeft = NSLayoutConstraint(item: mapView!, attribute: .leading, relatedBy: .equal, toItem: mapCell.contentView, attribute: .leading, multiplier: 1, constant: 0)
        let layoutRight = NSLayoutConstraint(item: mapView!, attribute: .trailing, relatedBy: .equal, toItem: mapCell.contentView, attribute: .trailing, multiplier: 1, constant: 0)
        let layoutTop = NSLayoutConstraint(item: mapView!, attribute: .top, relatedBy: .equal, toItem: mapCell.contentView, attribute: .top, multiplier: 1, constant: 0)
        let layoutBottom = NSLayoutConstraint(item: mapView!, attribute: .bottom, relatedBy: .equal, toItem: mapCell.contentView, attribute: .bottom, multiplier: 1, constant: 0)
        mapCell.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])

    }
    
    @objc func previewImageStarting(_ notification:Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        DispatchQueue.main.async {
            guard let indexPath = self.getIndexPath(for: newTrack) else {
                return
            }
            guard let cell = self.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            let track = self.getTrackAt(indexPath: indexPath)
            track?.beingProcessed = true
            cell.activityView.startAnimating()
        }

    }
    
    @objc func previewImageStopping(_ notification:Notification) {
        guard let updatedNotification = notification.object as? ImageUpdatedNotification else {
            return
        }
        DispatchQueue.main.async {
            if self.traitCollection.userInterfaceStyle == updatedNotification.style {
                guard let indexPath = self.getIndexPath(for: updatedNotification.track) else {
                    return
                }
                guard let cell = self.tableView.cellForRow(at: self.getIndexPath(for: updatedNotification.track)!) as? VGLogsTableViewCell else {
                    return
                }
                let track = self.getTrackAt(indexPath: indexPath)
                track?.beingProcessed = false
                cell.activityView.stopAnimating()
                cell.trackView.image = updatedNotification.image
            }
        }


    }
    
    @objc func onVehicleAddedToLog(_ notification:Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        guard let vehicle = newTrack.vehicle else {
            return
        }
        guard let indexPath = getIndexPath(for: newTrack) else {
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
            return
        }
        getTrackAt(indexPath: indexPath)?.vehicle = newTrack.vehicle
        
        cell.lblVehicle.text = vehicle.name
    }
    
    @objc func onLogUpdated(_ notification:Notification) {
        guard let updatedTrack = notification.object as? VGTrack else {
            return
        }

        DispatchQueue.main.async {
            
            guard let indexPath = self.getIndexPath(for: updatedTrack) else {
                return
            }
            
            guard let cell = self.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            
            if self.logDict[self.sections[indexPath.section]] == nil {
                return
            }
            
            self.logDict[self.sections[indexPath.section]]![indexPath.row] = updatedTrack
            cell.show(track: updatedTrack)
        }
        
        
    }
    
    func getIndexPath(for track:VGTrack) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            guard let sectionList = logDict[section] else {
                continue
            }
            for (rowIndex, trk) in sectionList.enumerated() {
                if track.id == trk.id {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }
    
    func getIndexPath(for fileName:String) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            guard let sectionList = logDict[section] else {
                continue
            }
            for (rowIndex, trk) in sectionList.enumerated() {
                if fileName == trk.fileName {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }

    var didLayout = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLayout {
            didLayout = true
            guard let tracks = tracksSummary?.tracks else {
                return
            }
            mapView.tracks = tracks
            
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        guard let tracksForSection = logDict[sections[section-1]] else {
            return 0
        }
        return tracksForSection.count
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 300
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let vc = VGMapViewController(nibName: nil, bundle: nil)
            vc.tracks = tracksSummary!.tracks
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let track = getTrackAt(indexPath: indexPath)
            let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
            logDetailsView.dataStore = self.dataStore
            logDetailsView.track = track
            self.navigationController?.pushViewController(logDetailsView, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            return mapCell
        }
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VGLogsTableViewCell.identifier,
            for: indexPath
            ) as? VGLogsTableViewCell else {
            return UITableViewCell()
        }
        
        if let track = getTrackAt(indexPath: indexPath) {
            cell.show(track:track)
        }
        return cell
    }
    
    
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 0 {
            return nil
        }
        
        let track = getTrackAt(indexPath: indexPath)
        
        let delete = UIAction(title: Strings.delete, image: Icons.delete, identifier: .none, discoverabilityTitle: nil, attributes: .destructive, state: .off) {_ in
            self.deleteTrack(at: indexPath)
        }
        
        let exportOriginal = UIAction(title: Strings.shareCSV, image: Icons.share, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            let activityVC = UIActivityViewController(activityItems: [self.vgFileManager!.getAbsoluteFilePathFor(track: track!)!], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
        
        let exportGPX = UIAction(title: Strings.shareGPX, image: Icons.share, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataStore.getDataPointsForTrack(with: track!.id!, onSuccess: { (dataPoints) in
                    track!.trackPoints = dataPoints
                    let fileUrl = self.vgGPXGenerator.generateGPXFor(tracks: [track!])!
                    let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                    self.present(activityVC, animated: true, completion: nil)
                }) { (error) in
                    //self.display(error: error)
                }
            }
        }
        
        let selectVehicle = UIAction(title: Strings.selectVehicle, image: Icons.vehicle, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            let cell = tableView.cellForRow(at: indexPath) as! VGLogsTableViewCell
            self.didTapVehicle(track: track!, tappedView: cell.btnVehicle)
        }
        
        let exportMenu = UIMenu(title: Strings.share, image: Icons.share, identifier: .none, options: .init(), children: [exportGPX, exportOriginal])
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: [selectVehicle, exportMenu, delete])
        }
    }
    
    func deleteTrack(at indexPath:IndexPath) {
        // Delete the row from the data source
        guard let track = self.getTrackAt(indexPath: indexPath) else {
            return
        }
        
        self.logDict[self.sections[indexPath.section-1]]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)

        if self.logDict[self.sections[indexPath.section-1]]?.count == 0 {
            self.logDict.removeValue(forKey: self.sections[indexPath.section-1])
            self.sections.remove(at: indexPath.section-1)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        }
        self.vgFileManager?.deleteFile(for: track)
        if self.logDict.count > 0 {
            //self.emptyLabel.isHidden = true
            self.tableView.separatorStyle = .singleLine
        } else {
            //self.emptyLabel.isHidden = false
            self.tableView.separatorStyle = .none
        }

        self.dataStore.delete(trackWith: track.id!, onSuccess: {
            
        }) { (error) in
            //self.display(error: error)
        }
    }
    
    func getTrackAt(indexPath:IndexPath) -> VGTrack? {
        guard let dayFileList = logDict[sections[indexPath.section-1]] else {
            return nil
        }
        let file = dayFileList[indexPath.row]
        return file
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView()
        }
        return getViewForHeader(section: section-1, view:nil)
    }
    
    func getViewForHeader(section:Int, view:VGLogHeaderView?) -> VGLogHeaderView {
        var hdrView = view
        
        if hdrView == nil {
            hdrView = tableView.dequeueReusableHeaderFooterView(withIdentifier: VGLogHeaderView.identifier) as? VGLogHeaderView
        }
        
        guard let view = hdrView else {
            return VGLogHeaderView()
        }
        
        let day = sections[section]
        view.dateLabel.text = " "
        view.detailsLabel.text = " "

        let dateString = headerDateFormatter.sectionKeyToDateString(sectionKey: day)
        var totalDuration = 0.0
        var totalDistance = 0.0
        var distanceString = ""
        var durationString = ""
        guard let trackSection = logDict[day] else {
            return VGLogHeaderView()
        }
        for track in trackSection {
            totalDuration += track.duration
            totalDistance += track.distance
        }
        distanceString = (totalDistance*1000).asDistanceString()
        durationString = totalDuration.asDurationString()
        
        view.dateLabel.text = dateString
        view.detailsLabel.text = distanceString + " - " + durationString
        
        
        var frame1 = view.dateLabel.frame
        frame1.size.height = dateString.height(withConstrainedWidth: view.bounds.width-40, font: view.dateLabel.font)
        view.dateLabel.frame = frame1
        
        var frame2 = view.detailsLabel.frame
        frame2.origin.y = frame1.size.height+2+2
        frame2.size.height = durationString.height(withConstrainedWidth: view.bounds.width-40, font: view.detailsLabel.font)
        view.detailsLabel.frame = frame2
        
        
        return view
    }
}

extension VGHistoryDetailsTableViewController: DisplaySelectVehicleProtocol {
    func didTapVehicle(track: VGTrack, tappedView:UIView?) {
        let selectionVC = VGVehiclesSelectionTableViewController(style: .insetGrouped)
        selectionVC.track = track
        
        let navController = UINavigationController(rootViewController: selectionVC)
        navController.modalPresentationStyle = .popover
        navController.preferredContentSize = CGSize(width: 414, height: 600)
        
        let popover: UIPopoverPresentationController = navController.popoverPresentationController!
        popover.sourceView = tappedView

        present(navController, animated: true, completion: nil)
    }
}
