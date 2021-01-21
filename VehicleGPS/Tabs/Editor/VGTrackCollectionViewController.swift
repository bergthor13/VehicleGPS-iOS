//
//  VGTrackCollectionViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 3.12.2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

private let reuseIdentifier = "graphCell"

class VGTrackCollectionDataSourceDelegate: NSObject, UICollectionViewDataSource {
    
    var tracks = [VGTrack]()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return tracks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? GraphCollectionViewCell else {
            return UICollectionViewCell()
        }
        let config = VGSpeedGraphGenerator().generate(from: tracks[indexPath.section])
        config.showMinMaxValue = false
        config.horizontalLineMarkers = []
        config.inset = UIEdgeInsets.zero
        cell.trackGraphView.configuration = config
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "trackHeader", for: indexPath) as? VGTrackEditorHeaderView else {
            return UICollectionReusableView()
        }
        view.trackColorView.backgroundColor = tracks[indexPath.section].vehicle?.mapColor
        view.trackNameLabel.text = tracks[indexPath.section].vehicle?.name
        return view
    }
    
}

extension VGTrackCollectionDataSourceDelegate: UICollectionViewDelegate {
    
}

extension VGTrackCollectionDataSourceDelegate: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let track = tracks[indexPath.section]
        let startTime = tracks.first?.timeStart!
        let endTime = tracks.last?.timeStart?.addingTimeInterval(tracks.last!.duration)
        let totalTime = endTime!.timeIntervalSince(startTime!)

        let width = CGFloat(track.duration/totalTime)
        
        return CGSize(width: collectionView.bounds.width*width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        if tracks.count <= 1 {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        let track = tracks[section]
        let prevTrack = tracks.first!
        
        let bla = track.timeStart?.timeIntervalSince(prevTrack.timeStart!)
        let totalTime = tracks.last!.timeStart?.timeIntervalSince(tracks.first!.timeStart!)

        let width = (CGFloat(CGFloat(bla!)/CGFloat(totalTime!))*collectionView.bounds.width)
        
        return UIEdgeInsets(top: 0, left: width, bottom: 0, right: 0)
    }
}
