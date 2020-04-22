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
    
    var tracks = [VGTrack]()
    
    var currTrack:VGTrack?
    
    func fileToTracks(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, callback: @escaping ([VGTrack]) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)?) {
        tracks = []
        //Setup the parser and initialize it with the filepath's data
        let data = NSData(contentsOf: fileUrl)
        let parser = XMLParser(data: data! as Data)
        parser.delegate = self

        //Parse the data, here the file will be read
        let success = parser.parse()
        if success {
            for track in tracks {
                track.process()
                let mapPoints = track.trackPoints.filter { (point) -> Bool in
                    return point.hasGoodFix()
                }
                track.mapPoints = VGTrack.getFilteredPointList(list:mapPoints)
                
                callback(tracks)
            }
            
            return

        }
        // TODO: Allow nil.
        callback([VGTrack()])
    }
    
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, onSuccess: @escaping (VGTrack) -> (), onFailure:@escaping(Error)->()) {
    }
    
    var currPoint = VGDataPoint()
    var foundCharacters = String()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {

        if elementName == "trkpt" || elementName == "wpt" {
            currPoint = VGDataPoint()
            currPoint.latitude = Double(attributeDict["lat"]!)!
            currPoint.longitude = Double(attributeDict["lon"]!)!
        }
        if elementName == "trk" {
            currTrack = VGTrack()
        }
    }

    // 2
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "ele" {
            let strElevation = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            guard let ele = Double(strElevation) else {
                return
            }
            currPoint.elevation = ele
        }

        if elementName == "time" {
            let timeString = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            currPoint.timestamp = ISO8601DateParser.parse(timeString)
            if currTrack?.timeStart == nil {
                currTrack?.timeStart = currPoint.timestamp
            }
        }

        if elementName == "trkpt" || elementName == "wpt" {
            currTrack!.trackPoints.append(currPoint)
        }
        
        if elementName == "trk" {
            tracks.append(currTrack!)
        }
        
        if elementName == "name" {
            currTrack?.name = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }
        
        if elementName == "cmt" {
            currTrack?.comment = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }

        foundCharacters = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundCharacters += string;
    }

}
