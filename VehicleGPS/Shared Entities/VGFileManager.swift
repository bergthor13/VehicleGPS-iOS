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
    var dataStore:VGDataStore!
    var LOG_DIRECTORY = "OriginalLogs"
    var IMAGE_DIRECTORY_LIGHT = "OverviewSnapsLight"
    var IMAGE_DIRECTORY_DARK = "OverviewSnapsDark"
    var VEHICLE_IMAGE_DIRECTORY = "VehicleImages"
    
    init() {
        fileManager = FileManager.default
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
        }
        createDirectory(directoryName: LOG_DIRECTORY)
        createDirectory(directoryName: IMAGE_DIRECTORY_LIGHT)
        createDirectory(directoryName: IMAGE_DIRECTORY_DARK)
        createDirectory(directoryName: VEHICLE_IMAGE_DIRECTORY)
    }
    
    func createDirectory(directoryName:String) {
        let logFolder = getDocumentsFolder()?.appendingPathComponent(directoryName)
        if !fileManager.fileExists(atPath: logFolder!.path) {
            do {
                try fileManager.createDirectory(atPath: logFolder!.path,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
            } catch let error {
                print(error)
            }
            
        }
    }
    
    func dataToFile(data: Data, filename: String) -> URL? {
        do {
            let folder = try fileManager.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: false)
            let destFileName = folder.appendingPathComponent(LOG_DIRECTORY).appendingPathComponent(filename)
            try data.write(to: destFileName)
            return destFileName
        } catch let error {
            print(error)
            return nil
        }
    }
    
    func getImage(for vehicle:VGVehicle) -> UIImage? {
        let path = getPathToImage(for: vehicle)
        guard let pathString = path?.path else {
            return nil
        }
        return UIImage(contentsOfFile: pathString)
    }
    
    func getPathToImage(for vehicle: VGVehicle) -> URL? {
        var path = getVehicleImagesFolder()
        path = path!.appendingPathComponent(vehicle.id!.uuidString)
        path = path!.appendingPathExtension("png")
        return path
    }
    
    func imageToFile(image:UIImage, for vehicle:VGVehicle) -> URL? {
        let path = getPathToImage(for: vehicle)

        do {
            try image.pngData()?.write(to: path!)
            return path
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func deleteImage(for vehicle:VGVehicle) -> Bool{
        let path = getPathToImage(for: vehicle)
        do {
            try fileManager.removeItem(atPath: path!.path)
        } catch let error {
            print(error)
            return false
        }
        return true
    }
    
    func deleteFileFor(track: VGTrack) {
        let logPath = getLogsFolder()?.appendingPathComponent(track.fileName).path

        do {
            try fileManager.removeItem(atPath: logPath!)
        } catch let error {
            print(error)
        }
        
        let imagePathDark = getImageFolder(style: .dark)?.appendingPathComponent(track.fileName.prefix(18)+"png").path
        do {
            try fileManager.removeItem(atPath: imagePathDark!)
        } catch let error {
            print(error)
        }
        
        let imagePathLight = getImageFolder(style: .light)?.appendingPathComponent(track.fileName.prefix(18)+"png").path
        do {
            try fileManager.removeItem(atPath: imagePathLight!)
        } catch let error {
            print(error)
        }
        
    }
    
    func getParser(for url:URL) -> IVGLogParser? {
        let fileExtension = url.lastPathComponent.split(separator: ".").last?.lowercased()
        
        if fileExtension == "gpx" {
            return VGGPXParser()
        }
        if let aStreamReader = StreamReader(path: url) {
            defer {
                aStreamReader.close()
            }
            guard let firstLine = aStreamReader.nextLine() else {
                return nil
            }
            var colCount = firstLine.split(separator: ",").count
            
            if colCount == 1 {
                colCount = firstLine.split(separator: ";").count
            }
            
            if colCount == 16 {
                return VGCSVParser()
            }
            
            if colCount == 15 {
                return VGShortCSVParser()
            }
            
            if colCount == 5 {
                return VGArduinoCSVParser()
            }
        }
        return VGCSVParser()
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
    
    func getVehicleImagesFolder() -> URL? {
        if var dir = getDocumentsFolder() {
            dir.appendPathComponent(VEHICLE_IMAGE_DIRECTORY)
            return dir
        }
        return nil
    }
    
    func getImageFolder(style: UIUserInterfaceStyle) -> URL? {
        if var dir = getDocumentsFolder() {
            if style == .dark {
                dir.appendPathComponent(IMAGE_DIRECTORY_DARK)
            } else if style == .light {
                dir.appendPathComponent(IMAGE_DIRECTORY_LIGHT)
            } else {
                dir.appendPathComponent(IMAGE_DIRECTORY_LIGHT)
            }
            return dir
        }
        return nil
    }
    
    func getAbsoluteFilePathFor(track: VGTrack) -> URL? {
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
                let attr = try fileManager.attributesOfItem(atPath: path!) as Dictionary
                if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    track.fileSize = Int(fileSize)
                }
                result.append(track)
            }
            return result
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func getTrackFileCount() -> Int {
        var fileList = [String]()
        let docUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let logPath = docUrl?.appendingPathComponent(LOG_DIRECTORY).path
        do {
            fileList = try fileManager.contentsOfDirectory(atPath: (logPath)!)
            return fileList.count
        } catch let error {
            print(error)
            return 0
        }
    }
    
    func getTrackImageCount() -> Int {
        var fileList = [String]()
        let logPathDark = getImageFolder(style: .dark)?.path
        let logPathLight = getImageFolder(style: .light)?.path
        var fileCount = 0
        do {
            fileList = try fileManager.contentsOfDirectory(atPath: (logPathDark)!)
            fileCount += fileList.count
        } catch let error {
            print(error)
        }
        
        do {
            fileList = try fileManager.contentsOfDirectory(atPath: (logPathLight)!)
            fileCount += fileList.count
        } catch let error {
            print(error)
        }
        return fileCount
    }
    
    func fileForTrackExists(track: VGTrack) -> Bool {
        let logFolder = getLogsFolder()
        let filePath = logFolder!.appendingPathComponent(track.fileName).path
        return fileManager.fileExists(atPath: filePath)
    }
    func logFilePathFor(track: VGTrack) -> URL? {
        let logsFolder = self.getLogsFolder()
        let fileNameWithoutExt = track.fileName.split(separator: ".")[0]
        return (logsFolder?.appendingPathComponent(String(fileNameWithoutExt)).appendingPathExtension("csv"))

    }
    
    func getTemporaryGPXPathFor(track: VGTrack?) -> URL? {
        let tempFolder = URL(fileURLWithPath: NSTemporaryDirectory())
        guard let timeStart = track?.getStartTime() else {
            return tempFolder.appendingPathComponent("gpx_file.gpx")
        }
        let fileNameWithoutExt = VGFileNameDateFormatter().string(from: timeStart)
        return (tempFolder.appendingPathComponent(String(fileNameWithoutExt)).appendingPathExtension("gpx"))
        
    }
    
    func getPNGPathFor(track: VGTrack, style: UIUserInterfaceStyle) -> URL? {
        let imageFolder = self.getImageFolder(style: style)

        if track.fileName == "" {
            if track.id != nil {
                return (imageFolder?.appendingPathComponent(track.id!.uuidString).appendingPathExtension("png"))!
            }
            return nil
        }
        
        
        let fileNameWithoutExt = track.fileName.split(separator: ".")[0]
        
        return (imageFolder?.appendingPathComponent(String(fileNameWithoutExt)).appendingPathExtension("png"))!
    }
    
    func pngForTrackExists(track: VGTrack, style: UIUserInterfaceStyle) -> Bool {
        guard let pathUrl = getPNGPathFor(track: track, style: style) else {
            return false
        }
        return self.fileManager.fileExists(atPath: pathUrl.path)
    }
    
    func savePNG(image: UIImage, for track: VGTrack, style: UIUserInterfaceStyle) {
        guard let pathUrl = getPNGPathFor(track: track, style: style) else {
            return
        }
        do {
            try image.pngData()?.write(to: pathUrl)
        } catch let error {
            print(error)
        }
    }
    
    func openImageFor(track: VGTrack, style: UIUserInterfaceStyle) -> UIImage? {
        guard let pathUrl = getPNGPathFor(track: track, style: style) else {
            return nil
        }
        if fileManager.fileExists(atPath: pathUrl.path) {
            return UIImage(contentsOfFile: pathUrl.path)
        }
        return nil
    }
}
