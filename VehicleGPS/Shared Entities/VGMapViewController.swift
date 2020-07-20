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

    
    override func viewDidLoad() {
        super.viewDidLoad()

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

    }
    
    func createMenu() -> UIMenu {
        let mapAction = UIAction(title: "Flytja kort út sem mynd", image: Icons.photo) { (action) in
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
                    let vc = UIActivityViewController(activityItems: [image.pngData()], applicationActivities: [])
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
