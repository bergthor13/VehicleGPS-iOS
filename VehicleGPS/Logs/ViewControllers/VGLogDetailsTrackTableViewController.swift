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
            return 9
        } else {
            return 4
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 5
        }
        return 1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {return "Samantekt"}
        if section == 1 {return "Hraði"}
        if section == 2 {return "Hæð yfir sjávarmáli"}
        if section == 3 {return "PDOP"}
        if section == 4 {return "Lárétt nákvæmni"}
        if section == 5 {return "Snúningar á mínútu"}
        if section == 6 {return "Álag vélar"}
        if section == 7 {return "Throttle Position"}
        if section == 8 {return "Hiti á kælivökva"}
        if section == 9 {return "Útihiti"}
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: VGGraphTableViewCell?
        if indexPath.section > 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "GraphCell", for: indexPath) as? VGGraphTableViewCell

            if cell == nil {
                cell = VGGraphTableViewCell(style: .default, reuseIdentifier: "GraphCell", tableView: self.tableView)
            }
            
            cell?.tableView = self.tableView
            cell!.graphView.startTime = track?.timeStart
            cell!.graphView.endTime = track?.timeStart?.addingTimeInterval(track!.duration)

        }
        if indexPath.section == 0 {
            let cell1 = UITableViewCell(style: .value1, reuseIdentifier: "asdf")
            cell1.textLabel?.text = "Start Time: \(track!.timeStart!)"
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
                
                if point1.fixType <= 1 || point2.fixType <= 1 {
                    continue
                }
                
                let duration = point2.timestamp?.timeIntervalSince(point1.timestamp!)
                let coord = CLLocation(latitude: latitude2, longitude: longitude2)
                let lastCoord = CLLocation(latitude: latitude1, longitude: longitude1)
                
                let distance = coord.distance(from: lastCoord)
                
                list.append((point1.timestamp!, (distance/duration!)*3.6))
            }
            cell?.graphView.showMinMaxValue = false
            cell!.graphView.color = UIColor(red: 0, green: 0.5, blue: 1, alpha: 0.3)
            cell!.graphView.numbersList = list
            cell!.graphView.displayHorizontalLine(at: [30, 40, 50, 60, 70, 80, 90])

            
        } else if indexPath.section == 2 {
            var list = [(Date, Double)]()

            for point in track!.trackPoints {
                guard let _ = point.latitude, let _ = point.longitude else {
                    continue
                }
                if point.fixType <= 1 {
                    continue
                }
                list.append((point.timestamp!, point.elevation!))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list

        } else if indexPath.section == 3 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                guard let _ = point.latitude, let _ = point.longitude else {
                    continue
                }
                if point.fixType <= 1 {
                    continue
                }
                list.append((point.timestamp!, point.pdop))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
        } else if indexPath.section == 4 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                guard let _ = point.latitude, let _ = point.longitude else {
                    continue
                }
                if point.fixType <= 1 {
                    continue
                }
                list.append((point.timestamp!, point.horizontalAccuracy))
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
        } else if indexPath.section == 5 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if let rpm = point.rpm {
                    list.append((point.timestamp!, rpm))
                } else {
                    list.append((point.timestamp!, 0.0))
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
        } else if indexPath.section == 6 {
            var list = [(Date, Double)]()
            for point in track!.trackPoints {
                if let engineLoad = point.engineLoad {
                    list.append((point.timestamp!, engineLoad))
                }
            }
            cell!.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell!.graphView.numbersList = list
            
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
            cell!.graphView.displayHorizontalLine(at: [90])
            
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
        //cell?.contentView.addSubview(cell!.graphView)
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 30
        }
        return 150
    }
}
