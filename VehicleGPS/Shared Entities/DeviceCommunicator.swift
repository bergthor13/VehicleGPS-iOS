////
////  DeviceCommunicator.swift
////  VehicleGPS
////
////  Created by Bergþór Þrastarson on 04/04/2020.
////  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
////
//
//import Foundation
//import NMSSH
//
//
//class DeviceCommunicator {
//    
//    var session: NMSSHSession?
//    var sftpSession: NMSFTP?
//    var downloadManager: VGSFTPManager?
//    
//    func combineLists(localList: [VGTrack], remoteList: [VGTrack]) -> [VGTrack] {
//        var result = localList
//        
//        for track in result {
//            if remoteList.contains(track) {
//                track.isRemote = true
//            }
//        }
//        
//        for track in remoteList {
//            track.isRemote = true
//            if !(result.contains(track)) {
//                result.append(track)
//            }
//        }
//        return result
//    }
//    
//    fileprivate func startConnectionToVGPS() {
//        DispatchQueue.global(qos: .background).async {
//            self.session = NMSSHSession.init(host: Constants.sftp.host, andUsername: Constants.sftp.username)
//            if self.session != nil {
//                self.fetchLogList()
//            }
//        }
//    }
//    
//    func connectToVehicleGPS(session:NMSSHSession) -> Bool {
//        if tryToConnectSSH(session: session) != true {
//            return false
//        }
//        
//        if tryToAuthenticate(session: session) != true {
//            return false
//        }
//        
//        if tryToConnectSFTP(session: session) != true {
//            return false
//        }
//        
//        self.downloadManager = VGSFTPManager(session: self.sftpSession!)
//        return true
//    }
//    
//    
//    func reconnectToVehicleGPS(session: NMSSHSession) {
//        if !session.isConnected || !session.isAuthorized || !sftpSession!.isConnected {
//            if connectToVehicleGPS(session: session) {
//                DispatchQueue.main.async {
//                    // TODO: Device Is Connected
//
////                    self.headerView.lblLogsAvailable.isHidden = false
////                    self.headerView.lblConnectedToGPS.isHidden = false
////                    self.headerView.imgIcon.isHidden = false
////                    self.headerView.lblConnectedToGPS.text = String(format: Strings.connectedTo, self.session!.host)
////
////                    self.headerView.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 51)
////                    self.tableView.tableHeaderView = self.headerView
//                }
//                return
//            }
//            return
//        }
//        
//        DispatchQueue.main.async {
//            // TODO: Device is not connected
//            //self.tableView.tableHeaderView = nil
//        }
//    }
//    
//    func tryToConnectSSH(session: NMSSHSession) -> Bool {
//        if !session.connect() {
//            DispatchQueue.main.async {
//                //self.displayErrorAlert(title: "SSH Connection Error", message: self.session?.lastError?.localizedDescription)
//            }
//            return false
//        }
//        return true
//    }
//    
//    func tryToAuthenticate(session: NMSSHSession) -> Bool {
//        if !session.authenticate(byPassword: Constants.sftp.password) {
//            DispatchQueue.main.async {
//                // TODO: Maybe display an error to the user
//                //self.displayErrorAlert(title: Strings.authorizationError, message: self.session?.lastError?.localizedDescription)
//            }
//            return false
//        }
//        return true
//    }
//    
//    func tryToConnectSFTP(session: NMSSHSession) -> Bool {
//        sftpSession = NMSFTP(session: session)
//        guard let sftpSession = sftpSession else {
//            return false
//        }
//        self.sftpSession = sftpSession
//        
//        sftpSession.connect()
//        
//        if !sftpSession.isConnected {
//            DispatchQueue.main.async {
//                self.displayErrorAlert(title: Strings.sftpConnError, message: self.session?.lastError?.localizedDescription)
//            }
//            return false
//        }
//        return true
//    }
//    
//    @objc func fetchLogList() {
//        var trackList = [VGTrack]()
//        
//        DispatchQueue.global(qos: .background).async {
//            if self.downloadManager == nil {
//                self.reconnectToVehicleGPS(session: self.session!)
//                if self.downloadManager == nil {
//                    DispatchQueue.main.async {
//                        self.tableView.refreshControl?.endRefreshing()
//                    }
//                    return
//                }
//            }
//            DispatchQueue.main.async {
//                self.tableView.refreshControl?.beginRefreshing()
//            }
//            guard let fileList = self.downloadManager!.getRemoteFiles() else {
//                // TODO: Show Error Message
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                    if self.tracksDict.count > 0 {
//                        self.emptyLabel.isHidden = true
//                        self.tableView.separatorStyle = .singleLine
//                    } else {
//                        self.emptyLabel.isHidden = false
//                        self.tableView.separatorStyle = .none
//                    }
//                    self.tableView.refreshControl?.endRefreshing()
//                }
//                return
//            }
//            var newFileCount = 0
//            
//            for file in fileList {
//                let track = VGTrack()
//                track.fileName = file.filename
//                if let fileSize = file.fileSize as? Int {
//                    track.fileSize = fileSize
//                }
//                if !self.vgFileManager!.fileForTrackExists(track: track) {
//                    newFileCount += 1
//                }
//                self.remoteList.append(track)
//                track.isRemote = true
//                trackList.append(track)
//            }
//            
//            let combinedList = self.combineLists(localList: self.dataStore.getAllTracks(), remoteList: trackList)
//            self.tracksDict = self.tracksToDictionary(trackList: combinedList)
//            
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//                if newFileCount == 0 {
//                    self.headerView.lblLogsAvailable.text = Strings.noNewLogs
//                } else if newFileCount == 1 {
//                    
//                    self.headerView.lblLogsAvailable.text = String(format: Strings.newLogSingular, newFileCount)
//                } else if (newFileCount-1)%10 == 0 && newFileCount != 11 {
//                    self.headerView.lblLogsAvailable.text = String(format: Strings.newLogSingular, newFileCount)
//                } else {
//                    self.headerView.lblLogsAvailable.text = String(format: Strings.newLogPlural, newFileCount)
//                }
//                if newFileCount == 0 {
//                    self.headerView.greenButton.isHidden = true
//                } else {
//                    self.headerView.greenButton.isHidden = false
//                }
//                
//                if self.tracksDict.count > 0 {
//                    self.emptyLabel.isHidden = true
//                    self.tableView.separatorStyle = .singleLine
//                } else {
//                    self.emptyLabel.isHidden = false
//                    self.tableView.separatorStyle = .none
//                }
//                self.tableView.refreshControl?.endRefreshing()
//            }
//        }
//    }


//}


//self.downloadFileFor(track: track, progress: { (received, total) in
//    DispatchQueue.main.async {
//        cell.update(progress: Double(received)/Double(total))
//        cell.layoutSubviews()
//    }
//    return true
//}) { (data) in
//    guard let data = data else {
//        return
//    }
//    
//    _ = self.vgFileManager!.dataToFile(data: data, filename: track.fileName)
//    self.dataStore.update(vgTrack: track)
//    
//    DispatchQueue.main.async {
//        let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
//        logDetailsView.dataStore = self.dataStore
//        logDetailsView.track = track
//        
//        cell.update(progress: 0.0)
//        self.navigationController?.pushViewController(logDetailsView, animated: true)
//    }
//}
