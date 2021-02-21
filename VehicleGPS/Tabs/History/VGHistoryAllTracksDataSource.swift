//
//  VGHistoryAllTracksDataSource.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 11/09/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGHistoryAllTracksDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    
    let vgFileManager = VGFileManager()
    let dataStore = VGDataStore()
    let vgGPXGenerator = VGGPXGenerator()

    var tracksDictionary = [String: [VGTrack]]()
    var sections = [String]()
    
    let headerDateFormatter = VGHeaderDateFormatter()
    let dateParsingFormatter = VGDateParsingFormatter()
    var parentViewController: VGHistoryTableViewController!
    
    init(parentViewController:UITableViewController) {
        super.init()
        self.parentViewController = (parentViewController as? VGHistoryTableViewController)
        self.addObservers()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if sections.count > 0 {
            parentViewController.emptyLabel.isHidden = true
        } else {
            parentViewController.emptyLabel.isHidden = false
        }
        return sections.count
    }
    
    func addObservers() {
        addObserver(selector: #selector(onVehicleAddedToLog(_:)), name: .vehicleAddedToTrack)
        addObserver(selector: #selector(onLogsAdded(_:)), name: .logsAdded)
        addObserver(selector: #selector(onLogUpdated(_:)), name: .logUpdated)
        addObserver(selector: #selector(previewImageStarting(_:)), name: .previewImageStartingUpdate)
        addObserver(selector: #selector(previewImageStopping(_:)), name: .previewImageFinishingUpdate)
    }
    
    func addObserver(selector:Selector, name:Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tracksForSection = tracksDictionary[sections[section]] else {
            return 0
        }
        return tracksForSection.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return getViewForHeader(tableView, section: section, view:nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VGLogsTableViewCell.identifier,
            for: indexPath
            ) as? VGLogsTableViewCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        if let track = getTrackAt(indexPath: indexPath) {
            cell.show(track:track)
        }
        
        return cell
    }
    
    func showEditToolbar() {
        parentViewController.navigationController?.setToolbarHidden(false, animated: true)

    }
    
    func hideEditToolbar() {
        parentViewController.navigationController?.setToolbarHidden(true, animated: true)

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let track = getTrackAt(indexPath: indexPath) else {
            return
        }
        
//        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//            appDelegate.trackDetailsViewController.track = track
//            return
//        }
        
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
            let pulleyEditor = PulleyEditorViewController()
            pulleyEditor.track = track
            parentViewController.navigationController?.pushViewController(pulleyEditor, animated: true)
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let _ = getTrackAt(indexPath: indexPath) else {
            return
        }
        if tableView.isEditing {
            guard let _ = tableView.indexPathsForSelectedRows else {
                self.hideEditToolbar()
                return
            }

        }
    }
    
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let track = getTrackAt(indexPath: indexPath) else {
            return nil
        }
        
        let delete = UIAction(title: Strings.delete, image: Icons.delete, identifier: .none, discoverabilityTitle: nil, attributes: .destructive, state: .off) {_ in
            self.deleteTrack(at: indexPath, in:tableView)
        }
        
        let exportOriginal = UIAction(title: Strings.shareCSV, image: Icons.share, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            let activityVC = UIActivityViewController(activityItems: [self.vgFileManager.getAbsoluteFilePathFor(track: track)!], applicationActivities: nil)
            
            self.parentViewController.present(activityVC, animated: true, completion: nil)
        }
        
        let exportGPX = UIAction(title: Strings.shareGPX, image: Icons.share, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataStore.getDataPointsForTrack(with: track.id!, onSuccess: { (dataPoints) in
                    track.trackPoints = dataPoints
                    let fileUrl = self.vgGPXGenerator.generateGPXFor(tracks: [track])!
                    let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                    DispatchQueue.main.async {
                        self.parentViewController.present(activityVC, animated: true, completion: nil)

                    }
                }) { (error) in
                    //self.parentViewController.display(error: error)
                }
            }
        }
        
        let selectVehicle = UIAction(title: Strings.selectVehicle, image: Icons.vehicle, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            guard let cell = tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            if !tableView.isEditing {
                self.didTapVehicle(track: track, tappedView: cell.btnVehicle)
            }
        }
        
        let selectTags = UIAction(title: Strings.selectTags, image: Icons.tag, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            guard let cell = tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            self.didTapTags(track: track, tappedView: cell.btnVehicle)
        }
        
        let exportMenu = UIMenu(title: Strings.share, image: Icons.share, identifier: .none, options: .init(), children: [exportGPX, exportOriginal])
        
        if vgFileManager.fileForTrackExists(track: track) {
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                UIMenu(title: "", children: [selectTags, selectVehicle, exportMenu, delete])
            }
        } else {
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                UIMenu(title: "", children: [selectTags, selectVehicle, exportGPX, delete])
            }
        }
        

    }
    
    func deleteTrack(at indexPath:IndexPath, in tableView:UITableView) {
        // Delete the row from the data source
        guard let track = self.getTrackAt(indexPath: indexPath) else {
            return
        }
        self.tracksDictionary[self.sections[indexPath.section]]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)

        if self.tracksDictionary[self.sections[indexPath.section]]?.count == 0 {
            self.tracksDictionary.removeValue(forKey: self.sections[indexPath.section])
            self.sections.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        }
        self.vgFileManager.deleteFile(for: track)
        self.vgFileManager.deletePreviewImage(for: track)


        self.dataStore.delete(trackWith: track.id!, onSuccess: {
            self.parentViewController.tracks.remove(at: self.parentViewController.tracks.firstIndex(of: track)!)
        }) { (error) in
            //self.display(error: error)
        }
    }
    
    func getTrackAt(indexPath:IndexPath) -> VGTrack? {
        guard let dayFileList = tracksDictionary[sections[indexPath.section]] else {
            return nil
        }
        let file = dayFileList[indexPath.row]
        return file
    }
    
    func getViewForHeader(_ tableView:UITableView, section:Int, view:VGLogHeaderView?) -> VGLogHeaderView {
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
        guard let trackSection = tracksDictionary[day] else {
            return VGLogHeaderView()
        }
        for track in trackSection {
            totalDuration += track.duration
            totalDistance += track.distance
        }
        distanceString = (totalDistance*1000).asDistanceString()
        
        let formattedDuration = totalDuration.asDurationString()
        durationString = formattedDuration
        
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
    
    
    @objc func previewImageStarting(_ notification:Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        DispatchQueue.main.async {
            guard let indexPath = self.getIndexPath(for: newTrack) else {
                return
            }
            guard let cell = self.parentViewController.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
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
            if self.parentViewController.traitCollection.userInterfaceStyle == updatedNotification.style {
                guard let indexPath = self.getIndexPath(for: updatedNotification.track) else {
                    return
                }
                guard let cell = self.parentViewController.tableView.cellForRow(at: self.getIndexPath(for: updatedNotification.track)!) as? VGLogsTableViewCell else {
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
        guard let cell = self.parentViewController.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
            return
        }
        getTrackAt(indexPath: indexPath)?.vehicle = newTrack.vehicle
        
        cell.lblVehicle.text = vehicle.name
    }
    
    @objc func onLogsAdded(_ notification:Notification) {
        guard let newTracks = notification.object as? [VGTrack] else {
            return
        }

        DispatchQueue.main.async {
            var list = [VGTrack]()
            _ = self.tracksDictionary.map {
                for item in $1 {
                    list.append(item)
                }
            }
            (self.sections, self.tracksDictionary) = LogDateSplitter.splitLogsByDate(trackList: self.combineLists(localList: list, remoteList: newTracks))
            self.parentViewController.tableView.reloadData()
            

        }
    }
    
    @objc func onLogUpdated(_ notification:Notification) {
        guard let updatedTrack = notification.object as? VGTrack else {
            return
        }

        DispatchQueue.main.async {
            
            guard let indexPath = self.getIndexPath(for: updatedTrack) else {
                return
            }
            
            guard let cell = self.parentViewController.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            
            if self.tracksDictionary[self.sections[indexPath.section]] == nil {
                return
            }
            
            self.tracksDictionary[self.sections[indexPath.section]]![indexPath.row] = updatedTrack
            cell.show(track: updatedTrack)
        }
        
        
    }
    
    func getIndexPath(for track:VGTrack) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            guard let sectionList = tracksDictionary[section] else {
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
            guard let sectionList = tracksDictionary[section] else {
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
    
    func combineLists(localList: [VGTrack], remoteList: [VGTrack]) -> [VGTrack] {
        var result = localList

        for track in remoteList {
            if !(result.contains(track)) {
                result.append(track)
            }
        }
        return result
    }
}

extension VGHistoryAllTracksDataSource: DisplaySelectVehicleProtocol {
    func didTapVehicle(track: VGTrack, tappedView:UIView?) {
        let selectionVC = VGVehiclesSelectionTableViewController(style: .insetGrouped)
        selectionVC.track = track
        
        let navController = UINavigationController(rootViewController: selectionVC)
        navController.modalPresentationStyle = .popover
        navController.preferredContentSize = CGSize(width: 414, height: 600)
        
        let popover: UIPopoverPresentationController = navController.popoverPresentationController!
        popover.sourceView = tappedView

        self.parentViewController.present(navController, animated: true, completion: nil)
    }
}


extension VGHistoryAllTracksDataSource: DisplaySelectTagsProtocol {
    func didTapTags(track: VGTrack, tappedView:UIView?) {
        let selectionVC = VGTagsTableViewController(style: .insetGrouped)
        selectionVC.track = track
        
        let navController = UINavigationController(rootViewController: selectionVC)
        navController.modalPresentationStyle = .popover
        navController.preferredContentSize = CGSize(width: 414, height: 600)
        
        let popover: UIPopoverPresentationController = navController.popoverPresentationController!
        popover.sourceView = tappedView

        self.parentViewController.present(navController, animated: true, completion: nil)
    }
}
