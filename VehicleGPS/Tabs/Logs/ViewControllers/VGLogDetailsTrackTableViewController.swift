//
//  VGLogDetailsTrackTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 30/07/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import CoreLocation

class VGLogDetailsTrackTableViewController: UITableViewController {
    var dlpPoint: CGPoint?
    var dlpTime: Date?
    var semaphore = DispatchSemaphore(value: 1)
    
    var track: VGTrack? {
        didSet {
            guard let track = track else {
                summary.append((Strings.noTrack,""))
                return
            }
            semaphore.wait()
            self.summarize(track: track)
            graphGenerators = track.graphTypes
            trackConfigs.removeAll()
            for generator in graphGenerators {
                guard let generator = generator else {
                    continue
                }
                trackConfigs.append(generator.generate(from: track))
            }
            semaphore.signal()

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    let dateFormatter = VGFullDateFormatter()
    var trackConfigs = [TrackGraphViewConfig]()
    var summary = [(String, String)]()
    var graphGenerators = [VGGraphGenerator?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(VGGraphTableViewCell.self, forCellReuseIdentifier: VGGraphTableViewCell.identifier)
        self.tableView.allowsSelection = false

        
    }
    
    func summarize(track:VGTrack) {
        summary.removeAll()
        guard let timeStart = track.timeStart else {
            summary.append((Strings.noStartTime,""))
            return
        }

        summary.append((Strings.startTime, dateFormatter.string(from: timeStart)))
        summary.append((Strings.endtime, dateFormatter.string(from: timeStart.addingTimeInterval(track.duration))))
        summary.append((Strings.distance, (track.distance*1000).asDistanceString()))
        let dcFormatter = DateComponentsFormatter()
        dcFormatter.allowedUnits = [.hour, .minute, .second]
        dcFormatter.unitsStyle = .short

        summary.append((Strings.duration, dcFormatter.string(from: track.duration) ?? ""))

        summary.append((Strings.datapoints, String(track.trackPoints.count)))
        let speed = Measurement(value: track.averageSpeed, unit: UnitSpeed.kilometersPerHour)
        let formatter = VGSpeedFormatter()
        summary.append((Strings.averageSpeed, formatter.string(from: speed)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dlpTime = nil
        dlpPoint = nil
        track = nil
        for (index, _) in self.tableView.visibleCells.enumerated() {
            let cell = self.tableView.visibleCells[index] as? VGGraphTableViewCell
            cell?.graphView.removeAllDLPListeners()
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return trackConfigs.count+1
    }
    
    let sections = [Strings.summary, Strings.speed, Strings.elevation, Strings.pdop, Strings.hAcc, Strings.rpm, Strings.engineLoad, Strings.throttlePos, Strings.coolTemp, Strings.ambTemp]

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return summary.count
        }
        return 1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return Strings.summary
        }
        if trackConfigs.count <= 0 {
            return ""
        }
        return trackConfigs[section-1].name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: VGGraphTableViewCell?
        
        if indexPath.section > 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: VGGraphTableViewCell.identifier, for: indexPath) as? VGGraphTableViewCell

            if cell == nil {
                cell = VGGraphTableViewCell(style: .default, reuseIdentifier: VGGraphTableViewCell.identifier, tableView: self.tableView)
            }
            
            cell!.graphView.addDLP(listener: self)
            guard let _ = track else {
                return cell!
            }
            if trackConfigs.count == 0 {
                return cell!
            }
            
            cell!.graphView.configuration = trackConfigs[indexPath.section-1]
            if let selectedPoint = dlpPoint {
                cell?.graphView.displayVerticalLine(at: selectedPoint)
            }
        } else {
            let cell1 = UITableViewCell(style: .value2, reuseIdentifier: Strings.dummyIdentifier)
            cell1.tintColor = UIApplication.shared.delegate?.window!!.tintColor
            cell1.textLabel?.text = summary[indexPath.row].0
            cell1.detailTextLabel?.text = summary[indexPath.row].1
            return cell1

        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 30
        }
        return 200
    }
    
    deinit {

    }
}

extension VGLogDetailsTrackTableViewController: DisplayLineProtocol {
    func didTouchGraph(at point: CGPoint) {
        for graph in self.tableView.visibleCells {
            if let graph1 = graph as? VGGraphTableViewCell {
                graph1.graphView.displayVerticalLine(at: point)
                dlpPoint = point
                dlpTime = graph1.graphView.getTimeOfTouched(point: point)
                if let time = dlpTime {
                    print(time)
                }
                
            }
        }
    }
}
