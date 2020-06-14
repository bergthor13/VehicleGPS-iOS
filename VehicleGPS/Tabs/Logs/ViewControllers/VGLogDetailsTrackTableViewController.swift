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
    
    var track: VGTrack?
    let dateFormatter = VGFullDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(VGGraphTableViewCell.self, forCellReuseIdentifier: VGGraphTableViewCell.identifier)
        self.tableView.allowsSelection = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dlpTime = nil
        dlpPoint = nil
        track = nil
        for (index, graph) in self.tableView.visibleCells.enumerated() {
            let cell = self.tableView.visibleCells[index] as? VGGraphTableViewCell
            cell?.graphView.removeAllDLPListeners()
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        guard let track = track else {
            return 5
        }
        if track.hasOBDData {
            return sections.count
        } else {
            return 5
        }
    }
    
    let sections = [Strings.summary, Strings.speed, Strings.elevation, Strings.pdop, Strings.hAcc, Strings.rpm, Strings.engineLoad, Strings.throttlePos, Strings.coolTemp, Strings.ambTemp]

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 5
        }
        return 1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: VGGraphTableViewCell?
        if indexPath.section > 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: VGGraphTableViewCell.identifier, for: indexPath) as? VGGraphTableViewCell

            if cell == nil {
                cell = VGGraphTableViewCell(style: .default, reuseIdentifier: VGGraphTableViewCell.identifier, tableView: self.tableView)
            }
            
            cell!.graphView.addDLP(listener: self)
            cell!.graphView.startTime = track?.timeStart
            cell!.graphView.endTime = track?.timeStart?.addingTimeInterval(track!.duration)

        }
        if indexPath.section == 0 {
            guard let track = track else {
                let cell1 = UITableViewCell(style: .value1, reuseIdentifier: Strings.dummyIdentifier)
                cell1.textLabel?.text = Strings.noTrack
                return cell1
            }
            guard let timeStart = track.timeStart else {
                let cell1 = UITableViewCell(style: .value1, reuseIdentifier: Strings.dummyIdentifier)
                cell1.textLabel?.text = Strings.noStartTime
                return cell1
            }
            let cell1 = UITableViewCell(style: .value2, reuseIdentifier: Strings.dummyIdentifier)
            cell1.tintColor = UIApplication.shared.delegate?.window!!.tintColor
            cell1.textLabel?.text = Strings.startTime
            
            cell1.detailTextLabel?.text = dateFormatter.string(from: timeStart)
            
            if indexPath.row == 1 {
                cell1.textLabel?.text = Strings.endtime
                cell1.detailTextLabel?.text = dateFormatter.string(from: timeStart.addingTimeInterval(track.duration))
            }
            if indexPath.row == 2 {
                cell1.textLabel?.text = Strings.distance
                let lengthFormatter = VGDistanceFormatter()
                
                lengthFormatter.unitStyle = .medium
                cell1.detailTextLabel?.text = lengthFormatter.string(fromMeters: track.distance*1000)

            }
            if indexPath.row == 3 {
                cell1.textLabel?.text = Strings.duration
                let dcFormatter = DateComponentsFormatter()
                dcFormatter.allowedUnits = [.hour, .minute, .second]
                dcFormatter.unitsStyle = .short
                cell1.detailTextLabel?.text = dcFormatter.string(from: track.duration)
            }
            if indexPath.row == 4 {
                cell1.textLabel?.text = Strings.datapoints
                cell1.detailTextLabel?.text = String(track.trackPoints.count)
            }
            
            return cell1
        } else if indexPath.section == 1 {
            var list = [(Date, Double)]()
            for (point1, point2) in zip(track!.trackPoints, track!.trackPoints.dropFirst()) {
                guard let latitude1 = point1.latitude, let longitude1 = point1.longitude else {
                    continue
                }
                guard let latitude2 = point2.latitude, let longitude2 = point2.longitude else {
                    continue
                }
                
                if !point1.hasGoodFix() || !point2.hasGoodFix() {
                    continue
                }
                
                guard let time1 = point1.timestamp, let time2 = point2.timestamp else {
                    continue
                }
                
                let duration = time2.timeIntervalSince(time1)
                let coord = CLLocation(latitude: latitude2, longitude: longitude2)
                let lastCoord = CLLocation(latitude: latitude1, longitude: longitude1)
                
                let distance = coord.distance(from: lastCoord)
                let speed = (distance/duration)*3.6
                if speed < 1200 {
                    list.append((point1.timestamp!, (distance/duration)*3.6))
                }
            }
            cell?.graphView.showMinMaxValue = false
            cell!.graphView.color = UIColor(red: 0, green: 0.5, blue: 1, alpha: 0.3)
            cell!.graphView.numbersList = list
            cell!.graphView.horizontalLineMarkers = [30, 40, 50, 60, 70, 80, 90]

        } else if indexPath.section == 2 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if point.latitude == nil && point.longitude == nil {
                    continue
                }
                if !point.hasGoodFix() {
                    continue
                }
                guard let time = point.timestamp, let ele = point.elevation else {
                    continue
                }
                list.append((time, ele))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list

        } else if indexPath.section == 3 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if point.latitude == nil && point.longitude == nil {
                    continue
                }
                if !point.hasGoodFix() {
                    continue
                }
                guard let time = point.timestamp, let pdop = point.pdop else {
                    continue
                }
                list.append((time, pdop))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
        } else if indexPath.section == 4 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if point.latitude == nil && point.longitude == nil {
                    continue
                }
                if !point.hasGoodFix() {
                    continue
                }
                
                guard let time = point.timestamp, let horizontalAccuracy = point.horizontalAccuracy else {
                    continue
                }
                
                list.append((time, horizontalAccuracy))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
        } else if indexPath.section == 5 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if let rpm = point.rpm, let time = point.timestamp {
                    list.append((time, rpm))
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list

        } else if indexPath.section == 6 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if let engineLoad = point.engineLoad, let time = point.timestamp {
                    if !engineLoad.isNaN {
                        list.append((time, engineLoad))
                    }
                    
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            cell!.graphView.horizontalLineMarkers = [30, 40, 50, 60, 70, 80, 90]
            
        } else if indexPath.section == 7 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if let throttlePosition = point.throttlePosition, let time = point.timestamp {
                    list.append((time, throttlePosition))
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
        } else if indexPath.section == 8 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if let coolantTemperature = point.coolantTemperature, let time = point.timestamp {
                    list.append((time, coolantTemperature))
                }
            }
            cell?.graphView.graphMinValue = 0
            cell?.graphView.graphMaxValue = 100
            cell?.graphView.showMinMaxValue = true
            cell!.graphView.color = UIColor(red: 165/255.0, green: 50/255.0, blue: 45/255.0, alpha: 0.3)
            cell!.graphView.numbersList = list
            cell!.graphView.horizontalLineMarkers = [90]
        } else if indexPath.section == 9 {
            var list = [(Date, Double)]()
            guard let track = track else {
                return cell!
            }
            for point in track.trackPoints {
                if let ambientTemperature = point.ambientTemperature, let time = point.timestamp {
                    list.append((time, ambientTemperature))
                }
            }
            cell!.graphView.color = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.3)
            cell!.graphView.numbersList = list
        }
        if let selectedPoint = dlpPoint {
            cell?.graphView.displayVerticalLine(at: selectedPoint)
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
            }
        }
    }
}
