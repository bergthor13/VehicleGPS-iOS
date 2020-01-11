//
//  HistoryHeader.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class HistoryHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var sortingSegment: UISegmentedControl!
    var historyTableViewController: VGHistoryTableViewController?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sortingSegment.addTarget(self, action: #selector(valueChanged(sender:)), for: .valueChanged)
    }
    
    
    @objc func valueChanged(sender:UISegmentedControl) {
        guard let htvc = historyTableViewController else {
            return
        }
        htvc.segmentChanged(id: sender.selectedSegmentIndex)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
