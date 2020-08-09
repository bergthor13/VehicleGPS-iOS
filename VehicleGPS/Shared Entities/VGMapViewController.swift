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
        bigMap.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bigMap)
        let layoutLeft = NSLayoutConstraint(item: bigMap, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
        let layoutRight = NSLayoutConstraint(item: bigMap, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        let layoutTop = NSLayoutConstraint(item: bigMap, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
        let layoutBottom = NSLayoutConstraint(item: bigMap, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])
        bigMap.tracks = tracks
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:Icons.moreActions, primaryAction: nil, menu: createMenu())

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
        let mapAction = UIAction(title: Strings.exportMapAsImage, image: Icons.photo) { (action) in
            self.mapToImage()
        }
        return UIMenu(title: "", children: [mapAction])
    }
    
    func mapToImage() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let dpGroup = DispatchGroup()
        for (index, track) in tracks.enumerated() {
            dpGroup.enter()
            self.dataStore.getMapPointsForTrack(with: track.id!, onSuccess: { (mapPoints) in
                self.tracks[index].mapPoints = mapPoints
                dpGroup.leave()
            }) { (error) in
                print(error)
                dpGroup.leave()
            }
        }
        
        dpGroup.notify(queue: .main) {
            delegate.snapshotter.drawTracks(vgTracks: self.tracks) { (image, style) -> Void? in
                if let image = image {
                    guard let pngImageData = image.pngData() else {
                        return nil
                    }
                    let vc = UIActivityViewController(activityItems: [pngImageData], applicationActivities: [])
                    DispatchQueue.main.async {
                        self.present(vc, animated: true)
                    }
                }
                return nil
            }
            
        }
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
