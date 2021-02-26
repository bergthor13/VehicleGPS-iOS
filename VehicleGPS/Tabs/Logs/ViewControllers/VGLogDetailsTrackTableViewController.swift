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
                return
            }
            semaphore.wait()
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
    var graphGenerators = [VGGraphGenerator?]()
    
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
        for index in self.tableView.visibleCells.indices {
            let cell = self.tableView.visibleCells[index] as? VGGraphTableViewCell
            cell?.graphView.removeAllDLPListeners()
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return trackConfigs.count
    }
    
    let sections = [Strings.speed, Strings.elevation, Strings.pdop, Strings.hAcc, Strings.rpm, Strings.engineLoad, Strings.throttlePos, Strings.coolTemp, Strings.ambTemp]

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if trackConfigs.count <= 0 {
            return ""
        }
        return trackConfigs[section].name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: VGGraphTableViewCell?
        
        cell = tableView.dequeueReusableCell(withIdentifier: VGGraphTableViewCell.identifier, for: indexPath) as? VGGraphTableViewCell

        if cell == nil {
            cell = VGGraphTableViewCell(style: .default, reuseIdentifier: VGGraphTableViewCell.identifier, tableView: self.tableView)
        }
        
        cell!.graphView.addDLP(listener: self)
        
        if track == nil {
            return cell!
        }
        
        if trackConfigs.count == 0 {
            return cell!
        }
        
        cell!.graphView.configuration = trackConfigs[indexPath.section]
        if let selectedPoint = dlpPoint {
            cell?.graphView.displayVerticalLine(at: selectedPoint)
        }

        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
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
