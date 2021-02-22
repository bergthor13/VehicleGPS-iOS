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
    var fileManager: FileManager
    var dataStore: VGDataStore!
    var LOG_DIRECTORY = "OriginalLogs"
    var IMAGE_DIRECTORY_LIGHT = "OverviewSnapsLight"
    var IMAGE_DIRECTORY_DARK = "OverviewSnapsDark"
    var VEHICLE_IMAGE_DIRECTORY = "VehicleImages"
    
    init() {
        fileManager = FileManager.default
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
        }
        createDirectory(directoryName: LOG_DIRECTORY, in: getDocumentsFolder()!)
        createDirectory(directoryName: IMAGE_DIRECTORY_LIGHT, in: getAppSupportFolder()!)
        createDirectory(directoryName: IMAGE_DIRECTORY_DARK, in: getAppSupportFolder()!)
        createDirectory(directoryName: VEHICLE_IMAGE_DIRECTORY, in: getAppSupportFolder()!)
    }
    
    func createDirectory(directoryName: String, in folder: URL) {
        let logFolder = folder.appendingPathComponent(directoryName)
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask) as [NSURL]
        if let applicationSupportURL = urls.last {
            
            if !fileManager.fileExists(atPath: applicationSupportURL.absoluteString!) {
                do {
                    try fileManager.createDirectory(at: applicationSupportURL as URL, withIntermediateDirectories: true, attributes: nil)
                } catch let error {
                    print(error)
                }
            }
        }
        
        if !fileManager.fileExists(atPath: logFolder.path) {
            do {
                try fileManager.createDirectory(atPath: logFolder.path,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
            } catch let error {
                print(error)
            }
            
        }
    }
    
    func getParser(for url: URL) -> IVGLogParser? {
        let fileExtension = url.lastPathComponent.split(separator: ".").last?.lowercased()
        
        if fileExtension == "gpx" {
            return VGGPXParser()
        }
        _ = url.startAccessingSecurityScopedResource()
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
        url.stopAccessingSecurityScopedResource()
        return VGCSVParser()
    }
    
    func getDocumentsFolder() -> URL? {
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return dir
        }
        return nil
    }
    
    func getTemporaryFolder() -> URL? {
        return FileManager.default.temporaryDirectory
    }
    
    func getAppSupportFolder() -> URL? {
        if let dir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
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
        if var dir = getAppSupportFolder() {
            dir.appendPathComponent(VEHICLE_IMAGE_DIRECTORY)
            return dir
        }
        return nil
    }
    
    func getImageFolder(style: UIUserInterfaceStyle) -> URL? {
        if var dir = getAppSupportFolder() {
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
    
    // MARK: - VGPS Log Files
    func saveDownloaded(data: Data, filename: String) -> URL? {
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
        
    func deleteFile(for track: VGTrack) {
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
    
    func fileForTrackExists(track: VGTrack) -> Bool {
        if track.fileName == "" {
            return false
        }
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
    
    // MARK: - Track Previews
    func getPreviewPath(for track: VGTrack, with style: UIUserInterfaceStyle) -> URL? {
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
    
    func previewExists(for track: VGTrack, with style: UIUserInterfaceStyle) -> Bool {
        guard let pathUrl = getPreviewPath(for: track, with: style) else {
            return false
        }
        return self.fileManager.fileExists(atPath: pathUrl.path)
    }
    
    func savePreview(image: UIImage, for track: VGTrack, with style: UIUserInterfaceStyle) {
        guard let pathUrl = getPreviewPath(for: track, with: style) else {
            return
        }
        do {
            try image.pngData()?.write(to: pathUrl)
        } catch let error {
            print(error)
        }
    }
    
    func getPreviewImage(for track: VGTrack, with style: UIUserInterfaceStyle) -> UIImage? {
        guard let pathUrl = getPreviewPath(for: track, with: style) else {
            return nil
        }
        if fileManager.fileExists(atPath: pathUrl.path) {
            return UIImage(contentsOfFile: pathUrl.path)
        }
        return nil
    }
    
    func deletePreviewImage(for track: VGTrack, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil) {
        for style in [UIUserInterfaceStyle.light, UIUserInterfaceStyle.dark] {
            guard let pathUrl = getPreviewPath(for: track, with: style) else {
                return
            }
            do {
                try fileManager.removeItem(at: pathUrl)
            } catch let error {
                if let onFailure = onFailure {
                    onFailure(error)
                }
                return
            }
        }
        if let onSuccess = onSuccess {
            onSuccess()
        }
        
        return
    }
    
    func deleteAllPreviewImages(onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        
        var darkFileList = [String]()
        var lightFileList = [String]()
        let logPathDark = getImageFolder(style: .dark)?.path
        let logPathLight = getImageFolder(style: .light)?.path
        do {
            darkFileList = try fileManager.contentsOfDirectory(atPath: (logPathDark)!)
        } catch let error {
            print(error)
        }
        
        do {
            lightFileList = try fileManager.contentsOfDirectory(atPath: (logPathLight)!)
        } catch let error {
            print(error)
        }
        
        for dFile in darkFileList {
            do {
                try fileManager.removeItem(at: getImageFolder(style: .dark)!.appendingPathComponent(dFile))
            } catch let error {
                print(error)
            }
            
        }
        
        for lFile in lightFileList {
            do {
                try fileManager.removeItem(at: getImageFolder(style: .light)!.appendingPathComponent(lFile))
            } catch let error {
                print(error)
            }
        }
        onSuccess()
    }
    
    // MARK: - Vehicle Images
    func getImage(for vehicle: VGVehicle) -> UIImage? {
        let path = getImagePath(for: vehicle)
        guard let pathString = path?.path else {
            return nil
        }
        return UIImage(contentsOfFile: pathString)
    }
    
    func getImagePath(for vehicle: VGVehicle) -> URL? {
        var path = getVehicleImagesFolder()
        path = path!.appendingPathComponent(vehicle.id!.uuidString)
        path = path!.appendingPathExtension("png")
        return path
    }
    
    func save(image: UIImage, for vehicle: VGVehicle) -> URL? {
        let path = getImagePath(for: vehicle)

        do {
            try image.pngData()?.write(to: path!)
            return path
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func deleteImage(for vehicle: VGVehicle) -> Bool {
        let path = getImagePath(for: vehicle)
        do {
            try fileManager.removeItem(atPath: path!.path)
        } catch let error {
            print(error)
            return false
        }
        return true
    }
    
    // MARK: - Statistics
    
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
}
