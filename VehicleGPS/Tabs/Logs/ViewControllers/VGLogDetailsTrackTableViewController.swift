//
//  VGLogDetailsTrackTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 30/07/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import CoreLocation

class VGLogDetailsTrackTableViewController: UITableViewController, DisplayLineProtocol {
    var dlpPoint: CGPoint?
    var dlpTime: Date?
    
    func didTouchGraph(at point: CGPoint) {
        for graph in self.tableView.visibleCells {
            if let graph1 = graph as? VGGraphTableViewCell {
                graph1.graphView.displayVerticalLine(at: point)
                dlpPoint = point
                dlpTime = graph1.graphView.getTimeOfTouched(point: point)
            }
        }
    }
    
    var track: VGTrack?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(VGGraphTableViewCell.self, forCellReuseIdentifier: "GraphCell")
        self.tableView.allowsSelection = false
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if track!.hasOBDData {
            return sections.count
        } else {
            return 5
        }
    }
    
    let sections = [NSLocalizedString("Samantekt", comment: ""), NSLocalizedString("Hraði", comment: ""), NSLocalizedString("Hæð yfir sjávarmáli", comment: ""), "PDOP", NSLocalizedString("Lárétt nákvæmni", comment: ""), NSLocalizedString("Snúningar á mínútu", comment: ""), NSLocalizedString("Álag vélar", comment: ""), NSLocalizedString("Eldsneytisgjöf", comment: ""), NSLocalizedString("Hiti á kælivökva", comment: ""), NSLocalizedString("Útihiti", comment: "")]

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
            cell = tableView.dequeueReusableCell(withIdentifier: "GraphCell", for: indexPath) as? VGGraphTableViewCell

            if cell == nil {
                cell = VGGraphTableViewCell(style: .default, reuseIdentifier: "GraphCell", tableView: self.tableView)
            }
            
            cell?.tableView = self.tableView
            cell!.graphView.dlpList.append(self)
            cell!.graphView.startTime = track?.timeStart
            cell!.graphView.endTime = track?.timeStart?.addingTimeInterval(track!.duration)

        }
        if indexPath.section == 0 {
            guard let track = track else {
                let cell1 = UITableViewCell(style: .value1, reuseIdentifier: "asdf")
                cell1.textLabel?.text = "No Track"
                return cell1
            }
            guard let timeStart = track.timeStart else {
                let cell1 = UITableViewCell(style: .value1, reuseIdentifier: "asdf")
                cell1.textLabel?.text = "No Start Time"
                return cell1
            }
            let cell1 = UITableViewCell(style: .value2, reuseIdentifier: "asdf")
            cell1.tintColor = UIApplication.shared.delegate?.window!!.tintColor
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .medium
            cell1.textLabel?.text = NSLocalizedString("Byrjunartími", comment: "")
            cell1.detailTextLabel?.text = dateFormatter.string(from: timeStart)
            
            if indexPath.row == 1 {
                cell1.textLabel?.text = NSLocalizedString("Endatími", comment: "")
                cell1.detailTextLabel?.text = dateFormatter.string(from: timeStart.addingTimeInterval(track.duration))
            }
            if indexPath.row == 2 {
                cell1.textLabel?.text = NSLocalizedString("Vegalengd", comment: "")
                let lengthFormatter = LengthFormatter()
                
                lengthFormatter.unitStyle = .medium
                cell1.detailTextLabel?.text = lengthFormatter.string(fromMeters: track.distance*1000)

            }
            if indexPath.row == 3 {
                cell1.textLabel?.text = NSLocalizedString("Tímalengd", comment: "")
                let dcFormatter = DateComponentsFormatter()
                dcFormatter.allowedUnits = [.hour, .minute, .second]
                dcFormatter.unitsStyle = .short
                cell1.detailTextLabel?.text = dcFormatter.string(from: track.duration)
            }
            if indexPath.row == 4 {
                cell1.textLabel?.text = NSLocalizedString("Gagnapunktar", comment: "")
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
                
                let duration = point2.timestamp?.timeIntervalSince(point1.timestamp!)
                let coord = CLLocation(latitude: latitude2, longitude: longitude2)
                let lastCoord = CLLocation(latitude: latitude1, longitude: longitude1)
                
                let distance = coord.distance(from: lastCoord)
                let speed = (distance/duration!)*3.6
                if speed < 1200 {
                    list.append((point1.timestamp!, (distance/duration!)*3.6))
                }
            }
            cell?.graphView.showMinMaxValue = false
            cell!.graphView.color = UIColor(red: 0, green: 0.5, blue: 1, alpha: 0.3)
            cell!.graphView.numbersList = list
            cell!.graphView.horizontalLineMarkers = [30, 40, 50, 60, 70, 80, 90]

        } else if indexPath.section == 2 {
            var list = [(Date, Double)]()

            for point in track!.trackPoints {
                if point.latitude == nil && point.longitude == nil {
                    continue
                }
                if !point.hasGoodFix() {
                    continue
                }
                list.append((point.timestamp!, point.elevation!))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list

        } else if indexPath.section == 3 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if point.latitude == nil && point.longitude == nil {
                    continue
                }
                if !point.hasGoodFix() {
                    continue
                }
                guard let pdop = point.pdop else {
                    continue
                }
                list.append((point.timestamp!, pdop))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
        } else if indexPath.section == 4 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if point.latitude == nil && point.longitude == nil {
                    continue
                }
                if !point.hasGoodFix() {
                    continue
                }
                
                guard let horizontalAccuracy = point.horizontalAccuracy else {
                    continue
                }
                
                list.append((point.timestamp!, horizontalAccuracy))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
        } else if indexPath.section == 5 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if let rpm = point.rpm {
                    list.append((point.timestamp!, rpm))
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list

        } else if indexPath.section == 6 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if let engineLoad = point.engineLoad {
                    if !engineLoad.isNaN {
                        list.append((point.timestamp!, engineLoad))
                    }
                    
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            cell!.graphView.horizontalLineMarkers = [30, 40, 50, 60, 70, 80, 90]
            
        } else if indexPath.section == 7 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if let throttlePosition = point.throttlePosition {
                    list.append((point.timestamp!, throttlePosition))
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
        } else if indexPath.section == 8 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if let coolantTemperature = point.coolantTemperature {
                    list.append((point.timestamp!, coolantTemperature))
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
            for point in track!.trackPoints {
                if let ambientTemperature = point.ambientTemperature {
                    list.append((point.timestamp!, ambientTemperature))
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
}
