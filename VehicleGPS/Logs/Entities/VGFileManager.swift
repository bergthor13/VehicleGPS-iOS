//
//  VGFileManager.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

class VGFileManager {
    var fileManager:FileManager
    var LOG_DIRECTORY = "OriginalLogs"
    var IMAGE_DIRECTORY = "ImageFiles"
    init() {
        fileManager = FileManager.default
        createDirectory(directoryName: LOG_DIRECTORY)
        createDirectory(directoryName: IMAGE_DIRECTORY)
    }
    
    func createDirectory(directoryName:String) {
        let logFolder = getDocumentsFolder()?.appendingPathComponent(directoryName)
        if !fileManager.fileExists(atPath: logFolder!.path) {
            do {
                try fileManager.createDirectory(atPath: logFolder!.path, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                print(error)
            }
            
        }
    }
    
    func dataToFile(data:Data, filename:String) -> URL? {
        do {
            let destFileName = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(LOG_DIRECTORY).appendingPathComponent(filename)
            try data.write(to: destFileName)
            return destFileName
        } catch let error {
            print("ERROR")
            print(error)
            return nil
        }
    }
    
    func deleteFileFor(track:VGTrack) {
        let logPath = getLogsFolder()?.appendingPathComponent(track.fileName).path
        let imagePath = getImageFolder()?.appendingPathComponent(track.fileName).path
        do {
            try fileManager.removeItem(atPath: logPath!)
            try fileManager.removeItem(atPath: imagePath!)
        } catch let error {
            print(error)
        }
        
    }
    
    func getDocumentsFolder() -> URL? {
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return dir
        }
        return nil
    }
    
    func getLogsFolder() -> URL? {
        if var dir = getDocumentsFolder() {
            dir.appendPathComponent(LOG_DIRECTORY)
            return dir
        }
        return nil
    }
    
    func getImageFolder() -> URL? {
        if var dir = getDocumentsFolder() {
            dir.appendPathComponent(IMAGE_DIRECTORY)
            return dir
        }
        return nil
    }
    
    func getAbsoluteFilePathFor(track:VGTrack) -> URL? {
        if !fileForTrackExists(track: track) {
            return nil
        }
        
        var folder = getLogsFolder()
        folder!.appendPathComponent(track.fileName)
        return folder
    }
    
    func getTrackLogs() -> [VGTrack]? {
        var fileList = [String]()
        var result = [VGTrack]()
        let docUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let logPath = docUrl?.appendingPathComponent(LOG_DIRECTORY).path
        do {
            fileList = try fileManager.contentsOfDirectory(atPath: (logPath)!)
            for item in fileList {
                let track = VGTrack()
                track.fileName = item
                let path = docUrl?.appendingPathComponent(LOG_DIRECTORY).appendingPathComponent(item).path
                var attr = try fileManager.attributesOfItem(atPath: path!) as Dictionary
                track.fileSize = Int(attr[FileAttributeKey.size] as! UInt64)
                result.append(track)
            }
            return result
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func fileForTrackExists(track:VGTrack) -> Bool {
        let logFolder = getLogsFolder()
        let filePath = logFolder!.appendingPathComponent(track.fileName).path
        return fileManager.fileExists(atPath: filePath)
    }
    func logFilePathFor(track:VGTrack) -> URL? {
        let logsFolder = self.getLogsFolder()
        let fileNameWithoutExt = track.fileName.split(separator: ".")[0]
        return (logsFolder?.appendingPathComponent(String(fileNameWithoutExt)).appendingPathExtension("csv"))

    }
    
    func getTemporaryGPXPathFor(track:VGTrack) -> URL? {
        let tempFolder = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileNameWithoutExt = track.fileName.split(separator: ".")[0]
        return (tempFolder.appendingPathComponent(String(fileNameWithoutExt)).appendingPathExtension("gpx"))
        
    }
    
    func getPNGPathFor(track:VGTrack) -> URL {
        let imageFolder = self.getImageFolder()
        let fileNameWithoutExt = track.fileName.split(separator: ".")[0]
        return (imageFolder?.appendingPathComponent(String(fileNameWithoutExt)).appendingPathExtension("png"))!
    }
    
    func pngForTrackExists(track:VGTrack) -> Bool {
        return self.fileManager.fileExists(atPath: getPNGPathFor(track: track).path)
    }
    
    func savePNG(image:UIImage, for track:VGTrack) {
        let path = getPNGPathFor(track: track)
        do {
            try image.pngData()?.write(to: path)
        } catch let error {
            print(error)
        }
    }
    
    func openImageFor(track:VGTrack) -> UIImage? {
        let path = getPNGPathFor(track: track)
        if fileManager.fileExists(atPath: path.path) {
            return UIImage(contentsOfFile: path.path)
        }
        return nil
    }
}
