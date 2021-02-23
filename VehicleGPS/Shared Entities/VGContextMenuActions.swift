//
//  VGContextMenuActions.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 23.2.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGContextMenuActions {
    
    var viewController: UIViewController
    var fileManager: VGFileManager
    var dataStore: VGDataStore
    var gpxGenerator: VGGPXGenerator
    weak var appDelegate: AppDelegate?
    
    func getSelectVehicleAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.selectVehicle, image: Icons.vehicle, handler: { (action) in
            let vehCont = VGVehiclesSelectionTableViewController(style: .insetGrouped)
            vehCont.track = track
            let navCont = UINavigationController(rootViewController: vehCont)
            self.viewController.present(navCont, animated: true, completion: nil)
        })
    }
    
    func getFileAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.shareCSV, image: Icons.share, handler: { (action) in
            let activityVC = UIActivityViewController(activityItems: [self.fileManager.getAbsoluteFilePathFor(track: track)!], applicationActivities: nil)
            self.viewController.present(activityVC, animated: true, completion: nil)
        })
    }
    
    func getGPXFileAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.shareGPX, image: Icons.share, handler: { (action) in
            let activityVC = UIActivityViewController(activityItems: [self.gpxGenerator.generateGPXFor(tracks: [track])!], applicationActivities: nil)
            self.viewController.present(activityVC, animated: true, completion: nil)
        })
    }
    
    func getDeleteAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.delete, image: Icons.delete, attributes: .destructive, handler: { (action) in
            self.dataStore.delete(trackWith: track.id!, onSuccess: {
                self.viewController.navigationController?.popViewController(animated: true)
            }, onFailure: { (error) in
                guard let appDelegate = self.appDelegate else {
                    return
                }
                appDelegate.display(error: error)
            })
        })
    }
    
    func getMapToImageAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.exportMapAsImage, image: Icons.photo) { (action) in
            self.dataStore.getMapPointsForTrack(with: track.id!, onSuccess: { (mapPoints) in
                track.mapPoints = mapPoints
                
                var drawnTracks = [VGTrack]()
            
                if track.distance != 0.0 {
                    drawnTracks.append(track)
                }
            
                self.appDelegate!.snapshotter.drawTracks(vgTracks: drawnTracks) { (image, style) -> Void? in
                    if let image = image {
                        guard let pngImageData = image.pngData() else {
                            return nil
                        }
                        let vc = UIActivityViewController(activityItems: [pngImageData], applicationActivities: [])
                        DispatchQueue.main.async {
                            self.viewController.present(vc, animated: true)
                        }
                    }
                    return nil
                }
            }, onFailure: { (error) in
                print(error)
            })

        }
    }
    init(viewController: UIViewController) {
        self.viewController = viewController
        self.gpxGenerator = VGGPXGenerator()
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            self.fileManager = VGFileManager()
            self.dataStore = VGDataStore()
            return
        }
        self.fileManager = delegate.fileManager
        self.dataStore = delegate.dataStore
        self.appDelegate = delegate
    }
}
