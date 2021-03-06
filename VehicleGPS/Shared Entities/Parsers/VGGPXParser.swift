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
    let PNG_PADDING: CGFloat = 0.9
    
    var tracks = [VGTrack]()
    
    var currTrack: VGTrack?
    
    func fileToTracks(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, callback: @escaping ([VGTrack]) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)?) {
        tracks = []
        //Setup the parser and initialize it with the filepath's data

        _ = fileUrl.startAccessingSecurityScopedResource()

        do {
            let data = try Data(contentsOf: fileUrl)
            fileUrl.stopAccessingSecurityScopedResource()
            let parser = XMLParser(data: data)
            parser.delegate = self

            //Parse the data, here the file will be read
            let success = parser.parse()
            if success {
                for track in tracks {
                    track.process()
                    let mapPoints = track.trackPoints.filter { (point) -> Bool in
                        return point.hasGoodFix()
                    }
                    track.mapPoints = VGTrack.getFilteredPointList(list: mapPoints)
                    
                    callback(tracks)
                }
                return

            }

        } catch let error {
            // TODO: Allow nil.
            print(error)
            fileUrl.stopAccessingSecurityScopedResource()
            callback([VGTrack()])
            return
        }
    }
    
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, onSuccess: @escaping(VGTrack) -> Void, onFailure: @escaping(Error) -> Void) {
    }
    
    var currPoint = VGDataPoint()
    var foundCharacters = String()
    
    func getDouble(from key: String, in dict: [String: String]) -> Double? {
        guard let value = dict[key] else {
            return nil
        }
        guard let doubleValue = Double(value) else {
            return nil
        }
        return doubleValue
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {

        if elementName == "trkpt" || elementName == "wpt" {
            currPoint = VGDataPoint()
            
            currPoint.latitude = getDouble(from: "lat", in: attributeDict)
            currPoint.longitude = getDouble(from: "lon", in: attributeDict)
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
        
        if elementName == "gpxtpx:atemp" {
            let temp = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            currPoint.ambientTemperature = Double(temp)!
        }
        
        if elementName == "gpxtpx:hr" {
            let hr = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            currPoint.heartRate = Int(hr)!
        }
        
        if elementName == "gpxtpx:cad" {
            let cad = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            currPoint.cadence = Int(cad)!
        }
        
        if elementName == "trkpt" || elementName == "wpt" {
            if let track = currTrack {
                track.trackPoints.append(currPoint)
            }
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
        self.foundCharacters += string
    }

}
