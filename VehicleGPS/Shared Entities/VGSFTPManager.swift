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
    init(session:NMSFTP) {
        self.session = session
        self.session.connect()
    }
    let semaphore = DispatchSemaphore(value: 1)
    
    func downloadFile(filename: String, progress: @escaping (UInt, UInt) -> Bool, callback:@escaping (Data?) -> Void) {
        self.semaphore.wait()
        let data = self.session.contents(atPath: Constants.sftp.remoteFolder+filename, progress: { (got, totalBytes) -> Bool in
            return progress(got, totalBytes)
        })
        self.semaphore.signal()
        callback(data)
    }
    
    func getRemoteFiles() -> [NMSFTPFile]? {
        var result = [NMSFTPFile]()

        guard let files = self.session.contentsOfDirectory(atPath: Constants.sftp.remoteFolder) else {
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
    
    func deleteFile(filename: String, callback: @escaping (Bool) -> Void) {
        self.downloadFile(filename: filename, progress: { (_, _) in
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
            
            var isCopySuccess = self.session.writeContents(data, toFileAtPath: Constants.sftp.deleteFolder + filename)
            if data.count == 0 {
                isCopySuccess = true
            }
            
            if isCopySuccess {
                let isRemoveSuccess = self.session.removeFile(atPath: Constants.sftp.remoteFolder + filename)
                callback(isRemoveSuccess)
            } else {

                callback(isCopySuccess)
            }
        })
            
        
    }
}
