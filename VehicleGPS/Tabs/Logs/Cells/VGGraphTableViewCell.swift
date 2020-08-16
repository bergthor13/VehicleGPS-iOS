//
//  VGTrackStatisticsTableViewCell.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 30/05/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGGraphTableViewCell: UITableViewCell {
    static let identifier = "GraphCell"
    var graphView: TrackGraphView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initializeView()
    }
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, tableView: UITableView) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initializeView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }

    override func prepareForReuse() {
        self.graphView.displayHorizontalLine(at: [])
        self.graphView.configuration.showMinMaxValue = false
    }

    func initializeView() {
        self.graphView = TrackGraphView(frame: self.contentView.frame)
        self.contentView.addSubview(graphView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.graphView.frame = self.contentView.frame
    }
}
