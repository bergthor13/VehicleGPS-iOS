//
//  VGPulleyViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24.11.2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import Pulley

class VGEditorTrackViewController: UIViewController {
    var dlpPoint: CGPoint?
    var dlpTime: Date?

    let tvcontroller = VGLogDetailsTrackTableViewController(style: .grouped)
    var toolbar: VGEditorToolbar!
    var tracks = [VGTrack]() {
        didSet {
            self.tracks.sort()
            self.tracks.reverse()
            tvcontroller.track = tracks.first
            DispatchQueue.main.async {
                self.tvcontroller.tableView.reloadData()
            }
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tvcontroller.tableView.fill(parentView: self.view, with: .zero)
        tvcontroller.tableView.dataSource = tvcontroller
        tvcontroller.tableView.delegate = tvcontroller
        self.tvcontroller.tableView.register(VGGraphTableViewCell.self, forCellReuseIdentifier: VGGraphTableViewCell.identifier)
        tvcontroller.tableView.showsHorizontalScrollIndicator = true
        toolbar = Bundle.main.loadNibNamed("VGEditorToolbar", owner: nil, options: nil)?.first as? VGEditorToolbar
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toolbar)
        let top = NSLayoutConstraint(item: toolbar!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: toolbar!, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: toolbar!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        
        view.addConstraints([top,left,right])
        tvcontroller.tableView.contentInset = UIEdgeInsets(top: 55, left: 0, bottom: 0, right: 0)
    }
}

extension VGEditorTrackViewController: PulleyDrawerViewControllerDelegate {
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return bottomSafeArea+55
    }
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 375
    }
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: (drawer.visibleDrawerHeight-distance)-bottomSafeArea, right: 0)
        if let pulley = self.parent as? PulleyEditorViewController {
            if pulley.currentDisplayMode == .drawer {
                pulley.mapViewController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: distance-bottomSafeArea, right: 0)
            }
        }
    }
}

extension VGEditorTrackViewController: DisplayLineProtocol {
    func didTouchGraph(at point: CGPoint) {
        for graph in self.tvcontroller.tableView.visibleCells {
            if let graph1 = graph as? VGGraphTableViewCell {
                graph1.graphView.displayVerticalLine(at: point)
                dlpPoint = point
                dlpTime = graph1.graphView.getTimeOfTouched(point: point)
            }
        }
    }
}
