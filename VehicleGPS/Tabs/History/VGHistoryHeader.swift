//
//  HistoryHeader.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

enum SegmentType: Int {
    case allTracks = 0
    case day = 1
    case month = 2
    case year = 3
}

class VGHistoryHeader: UIView {

    var sortingSegment: UISegmentedControl
    var historyTableViewController: VGHistoryTableViewController?
    
    struct SegmentItem {
        var title: String
        var type: SegmentType
    }
    
    var segments = [
        SegmentItem(title: Strings.allTracks, type: .allTracks),
        SegmentItem(title: Strings.day, type: .day),
        SegmentItem(title: Strings.month, type: .month),
        SegmentItem(title: Strings.year, type: .year)
    ]
    
    func configure() {
        sortingSegment.addTarget(self, action: #selector(valueChanged(sender:)), for: .valueChanged)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        sortingSegment.translatesAutoresizingMaskIntoConstraints = false
        
        sortingSegment.fill(parentView: self, layoutGuide: self.safeAreaLayoutGuide, with: UIEdgeInsets(top: 11, left: 11, bottom: 20, right: 20))
        
        for segment in segments {
            sortingSegment.insertSegment(withTitle: segment.title, at: segment.type.rawValue, animated: false)
        }
        sortingSegment.selectedSegmentIndex = SegmentType.allTracks.rawValue
        
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
    
    @objc func valueChanged(sender: UISegmentedControl) {
        guard let htvc = historyTableViewController else {
            return
        }
        htvc.segmentChanged(id: sender.selectedSegmentIndex)
    }
}
