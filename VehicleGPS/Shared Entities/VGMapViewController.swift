//
//  VGMapViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/07/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGMapViewController: UIViewController {

    var tracks = [VGTrack]()
    var dataStore = VGDataStore()
    var barsHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.map
        let bigMap = VGMapView(frame: self.view.frame)
        bigMap.fill(parentView: self.view, with: .zero)
        bigMap.tracks = tracks
        if #available(iOS 14.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icons.moreActions, primaryAction: nil, menu: createMenu())
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icons.moreActions, style: .plain, target: self, action: #selector(showMoreMenu))
        }
        bigMap.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTapped)))
    }
    
    override var prefersStatusBarHidden: Bool {
        return barsHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    @objc func mapTapped() {
        if barsHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            barsHidden = false
            self.showTabBar()
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            barsHidden = true
            self.hideTabBar()

        }
        
    }
    
    func hideTabBar() {
        guard var frame = self.tabBarController?.tabBar.frame else {
            return
        }
        frame.origin.y = self.view.frame.size.height + frame.size.height
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = frame
            self.setNeedsStatusBarAppearanceUpdate()
        })

    }

    func showTabBar() {
        guard var frame = self.tabBarController?.tabBar.frame else {
            return
        }
        frame.origin.y = self.view.frame.size.height - frame.size.height
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = frame
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func createMenu() -> UIMenu {
        return UIMenu(title: "", children: [VGMenuActions(viewController: self).getMapToImageAction(for: tracks)])
    }
    
    @objc func showMoreMenu() {
        let alertController = UIAlertController()
        alertController.addAction(VGMenuActions(viewController: self).getMapToImageAction(for: tracks))
        present(alertController, animated: true)
    }
}
