//
//  VGArduinoCSVParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 23/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit
import fastCSV

class VGGPXParser: NSObject, IVGLogParser, XMLParserDelegate {
    
    let progress_update_delay = TimeInterval(0.1)
    let PNG_PADDING:CGFloat = 0.9
    var vgSnapshotMaker:VGSnapshotMaker
    
    var track = VGTrack()
    
    init(snapshotter:VGSnapshotMaker) {
        self.vgSnapshotMaker = snapshotter
    }
    
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, callback: @escaping (VGTrack) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)?) {
        
        track.fileName = fileUrl.lastPathComponent
        do {
            let resources = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                track.fileSize = fileSize
            }
        } catch {
            print("Error: \(error)")
        }
        
        //Setup the parser and initialize it with the filepath's data
        let data = NSData(contentsOf: fileUrl)
        let parser = XMLParser(data: data! as Data)
        parser.delegate = self

        //Parse the data, here the file will be read
        let success = parser.parse()
        if success {
            track.process()
            
            let mapPoints = track.trackPoints.filter { (point) -> Bool in
                return point.hasGoodFix()
            }
            track.mapPoints = VGTrack.getFilteredPointList(list:mapPoints)
            
            self.vgSnapshotMaker.drawTrack(vgTrack: track) { (image, style) in
                guard let imageCallback = imageCallback else {
                    return nil
                }
                imageCallback(self.track, style)
                return nil
            }
            callback(track)

        }
        // TODO: Allow nil.
        callback(VGTrack())
    }
    
    var currPoint = VGDataPoint()
    var foundCharacters = String()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {

        if elementName == "trkpt" || elementName == "wpt" {
            currPoint = VGDataPoint()
            currPoint.latitude = Double(attributeDict["lat"]!)!
            currPoint.longitude = Double(attributeDict["lon"]!)!
        }
    }

    // 2
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "ele" {
            let strElevation = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            currPoint.elevation = Double(strElevation)!
        }

        if elementName == "time" {
            let timeString = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            currPoint.timestamp = ISO8601DateParser.parse(timeString)
        }

        if elementName == "trkpt" || elementName == "wpt" {
            track.trackPoints.append(currPoint)
        }

        foundCharacters = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundCharacters += string;
    }

}
