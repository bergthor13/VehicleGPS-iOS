//
//  VGTrackStatisticsTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 30/05/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGGraphTableViewCell: UITableViewCell {

    var graphView: TrackGraphView!
    var tableView: UITableView? {
        didSet {
            self.graphView.tableView = tableView
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initializeView()
    }
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, tableView: UITableView) {
        self.tableView = tableView
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initializeView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }

    override func prepareForReuse() {
        self.graphView.displayHorizontalLine(at: [])
        self.graphView.showMinMaxValue = false
        self.graphView.numbersList = []
    }

    func initializeView() {
        if tableView != nil {
            self.graphView = TrackGraphView(frame: self.contentView.frame, tableView: self.tableView!)
        } else {
            self.graphView = TrackGraphView(frame: self.contentView.frame)
        }

        self.contentView.addSubview(graphView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.graphView.frame = self.contentView.frame
    }
}
