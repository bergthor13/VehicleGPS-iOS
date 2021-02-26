//
//  VGContextMenuActions.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 23.2.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGMenuActions {
    
    // MARK: - Variables
    var viewController: UIViewController
    var fileManager: VGFileManager
    var dataStore: VGDataStore
    var gpxGenerator: VGGPXGenerator
    weak var appDelegate: AppDelegate?
    
    // MARK: - Initialization
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
    
    // MARK: - Methods
    private func selectVehicle(for track: VGTrack) {
        let vehCont = VGVehiclesSelectionTableViewController(style: .insetGrouped)
        vehCont.track = track
        let navCont = UINavigationController(rootViewController: vehCont)
        DispatchQueue.main.async {
            self.viewController.present(navCont, animated: true, completion: nil)
        }
    }
    
    private func share(files: [Any]) {
        let activityVC = UIActivityViewController(activityItems: files, applicationActivities: nil)
        DispatchQueue.main.async {
            self.viewController.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func delete(track: VGTrack) {
        self.dataStore.delete(trackWith: track.id!, onSuccess: {
            self.viewController.navigationController?.popViewController(animated: true)
        }, onFailure: { (error) in
            guard let appDelegate = self.appDelegate else {
                return
            }
            appDelegate.display(error: error)
        })
    }
    
    private func mapToImage(for tracks: [VGTrack]) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let semaphore = DispatchSemaphore(value: 10)
        let dpGroup = DispatchGroup()
        for (index, track) in tracks.enumerated() {
            
            DispatchQueue.global(qos: .userInitiated).async {
                dpGroup.enter()
                semaphore.wait()
                self.dataStore.getMapPointsForTrack(with: track.id!, onSuccess: { (mapPoints) in
                    tracks[index].mapPoints = mapPoints
                    dpGroup.leave()
                    semaphore.signal()

                }, onFailure: { (error) in
                    print(error)
                    dpGroup.leave()
                    semaphore.signal()
                })
            }

        }
        
        dpGroup.notify(queue: .main) {
            var drawnTracks = [VGTrack]()
            for track in tracks where track.distance != 0.0 {
                drawnTracks.append(track)
            }
            delegate.snapshotter.drawTracks(vgTracks: drawnTracks) { (image, style) -> Void? in
                if let image = image {
                    guard let pngImageData = image.pngData() else {
                        return nil
                    }
                    self.share(files: [pngImageData])
                }
                return nil
            }
        }

    }
    
    // MARK: - Actions
    func getSelectVehicleAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.selectVehicle, image: Icons.vehicle) { action in
            self.selectVehicle(for: track)
        }
    }
    
    func getShareFileAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.shareCSV, image: Icons.share, handler: { (action) in
            self.share(files: [self.fileManager.getAbsoluteFilePathFor(track: track)!])
        })
    }
    
    func getGPXFileAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.shareGPX, image: Icons.share, handler: { (action) in
            self.share(files: [self.gpxGenerator.generateGPXFor(tracks: [track])!])
        })
    }
    
    func getDeleteAction(for track: VGTrack) -> UIAction {
        return UIAction(title: Strings.delete, image: Icons.delete, attributes: .destructive, handler: { (action) in
            self.delete(track: track)
        })
    }
    
    func getMapToImageAction(for tracks: [VGTrack]) -> UIAction {
        return UIAction(title: Strings.exportMapAsImage, image: Icons.photo) { (action) in
            self.mapToImage(for: tracks)
        }
    }
}
