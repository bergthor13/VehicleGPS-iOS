//
//  HistoryHeader.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGHistoryHeader: UIView {

    var sortingSegment: UISegmentedControl
    var historyTableViewController: VGHistoryTableViewController?
    
    func configure() {
        sortingSegment.addTarget(self, action: #selector(valueChanged(sender:)), for: .valueChanged)
        self.translatesAutoresizingMaskIntoConstraints = false
        sortingSegment.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(sortingSegment)
        let layoutLeft = NSLayoutConstraint(item: sortingSegment, attribute: .leading, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .leading, multiplier: 1, constant: 20)
        let layoutRight = NSLayoutConstraint(item: sortingSegment, attribute: .trailing, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .trailing, multiplier: 1, constant: -20)
        let layoutTop = NSLayoutConstraint(item: sortingSegment, attribute: .top, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 11)
        let layoutBottom = NSLayoutConstraint(item: sortingSegment, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 11)

        self.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])
        sortingSegment.insertSegment(withTitle: NSLocalizedString("Dagur", comment: ""), at: 0, animated: false)
        sortingSegment.insertSegment(withTitle: NSLocalizedString("Mánuður", comment: ""), at: 1, animated: false)
        sortingSegment.insertSegment(withTitle: NSLocalizedString("Ár", comment: ""), at: 2, animated: false)
        sortingSegment.selectedSegmentIndex = 1
        let bla = NSLayoutConstraint(item: sortingSegment, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 28)
        sortingSegment.addConstraint(bla)
    }
    
    required init?(coder: NSCoder) {
        sortingSegment = UISegmentedControl()
        super.init(coder: coder)
        configure()
    }
    
    override init(frame: CGRect) {
        sortingSegment = UISegmentedControl()
        super.init(frame: frame)
        configure()
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
