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
    let distanceFormatter = VGDistanceFormatter()
    let durationFormatter = VGDurationFormatter()
    let headerDateFormatter = VGHeaderDateFormatter()
    let dateParsingFormatter = VGDateParsingFormatter()

    var mapView: VGMapView!
    var dataStore: VGDataStore!
    var mapCell: UITableViewCell!
    
    var sections = [String]()
    var logDict = [String: [VGTrack]]()
    
    func createMenu() -> UIMenu {
        let mapAction = UIAction(title: "Flytja kort út sem mynd", image: Icons.photo) { (action) in
            self.mapToImage()
        }
        return UIMenu(title: "", children: [mapAction])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let tracksSummary = self.tracksSummary {
            title = tracksSummary.dateDescription
        }
        if let tracks = tracksSummary?.tracks {
            (self.sections, self.logDict) = LogDateSplitter.splitLogsByDate(trackList: tracks)
        }
        print(sections)
        self.tableView.register(VGLogHeaderView.nib, forHeaderFooterViewReuseIdentifier: VGLogHeaderView.identifier)

        self.tableView.register(VGLogsTableViewCell.nib, forCellReuseIdentifier: VGLogsTableViewCell.identifier)
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:Icons.moreActions, primaryAction: nil, menu: createMenu())
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
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
    var didLayout = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLayout {
            mapView.tracks = tracksSummary?.tracks as! [VGTrack]
            didLayout = true
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
            let vc = UIViewController(nibName: nil, bundle: nil)
            let bigMap = VGMapView(frame: vc.view.frame)
            bigMap.translatesAutoresizingMaskIntoConstraints = false
            vc.view.addSubview(bigMap)
            let layoutLeft = NSLayoutConstraint(item: bigMap, attribute: .leading, relatedBy: .equal, toItem: vc.view, attribute: .leading, multiplier: 1, constant: 0)
            let layoutRight = NSLayoutConstraint(item: bigMap, attribute: .trailing, relatedBy: .equal, toItem: vc.view, attribute: .trailing, multiplier: 1, constant: 0)
            let layoutTop = NSLayoutConstraint(item: bigMap, attribute: .top, relatedBy: .equal, toItem: vc.view, attribute: .top, multiplier: 1, constant: 0)
            let layoutBottom = NSLayoutConstraint(item: bigMap, attribute: .bottom, relatedBy: .equal, toItem: vc.view, attribute: .bottom, multiplier: 1, constant: 0)
            vc.view.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])
            bigMap.tracks = tracksSummary?.tracks as! [VGTrack]
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
        print(section)
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
        distanceString = distanceFormatter.string(fromMeters: totalDistance*1000)
        
        let formattedDuration = durationFormatter.string(from: totalDuration)
        durationString = String(formattedDuration!)
        
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

    
    func mapToImage() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard var tracks = tracksSummary?.tracks else {
            return
        }
        let dpGroup = DispatchGroup()
        for (index, track) in tracks.enumerated() {
            dpGroup.enter()
            self.dataStore.getMapPointsForTrack(with: track.id!, onSuccess: { (mapPoints) in
                tracks[index].mapPoints = mapPoints
                dpGroup.leave()
            }) { (error) in
                print(error)
                dpGroup.leave()
            }
        }
        
        dpGroup.notify(queue: .main) {
            delegate.snapshotter.drawTracks(vgTracks: self.tracksSummary!.tracks) { (image, style) -> Void? in
                if let image = image {
                    let vc = UIActivityViewController(activityItems: [image.pngData()], applicationActivities: [])
                    DispatchQueue.main.async {
                        vc.title = "Mynd af korti"
                        self.present(vc, animated: true)
                    }
                }
                return nil
            }
            
        }
    }
}
