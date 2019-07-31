//
//  VGDownloadManager.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 30/05/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import NMSSH

class VGSFTPManager {
    let session: NMSFTP
    let remoteFolder = "/home/pi/Tracks/"
    let deleteFolder = "/home/pi/DeletedTracks/"
    init(session:NMSFTP) {
        self.session = session
        self.session.connect()
    }
    
    func downloadFile(filename:String, progress:@escaping (UInt, UInt)->Bool, callback:@escaping (Data?)->Void) {
        DispatchQueue.global(qos: .background).async {
            let data = self.session.contents(atPath: self.remoteFolder+filename, progress: { (got, totalBytes) -> Bool in
                return progress(got, totalBytes)
            })
            callback(data)
        }
    }
    
    func getRemoteFiles() -> [NMSFTPFile]? {
        var result = [NMSFTPFile]()

        guard let files = self.session.contentsOfDirectory(atPath: remoteFolder) else {
            return nil
        }
        
        for file in files {
            if file.isDirectory {
                continue
            }
            
            if file.filename.prefix(1) == "." {
                continue
            }
            
            if file.filename.suffix(3) != "csv" {
                continue
            }
            
            result.append(file)
            
        }
        return result
    }
    
    func deleteFile(filename:String, callback:@escaping (Bool)->Void) {
        DispatchQueue.global(qos: .background).async {
            self.downloadFile(filename: filename, progress: { (asdf, fdsa) in
                return true
            }, callback: { (data) in
                guard let data = data else {
                    if !self.session.fileExists(atPath: filename) {
                        callback(true)
                        return
                    }
                    callback(false)
                    return
                }
                
                var isCopySuccess = self.session.writeContents(data, toFileAtPath: self.deleteFolder + filename)
                if data.count == 0 {
                    isCopySuccess = true
                }
                
                if isCopySuccess {
                    let isRemoveSuccess = self.session.removeFile(atPath: self.remoteFolder + filename)
                    callback(isRemoveSuccess)
                } else {

                    callback(isCopySuccess)
                }
            })
            
        }
    }
}
