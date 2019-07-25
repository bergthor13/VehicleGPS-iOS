//
//  VGLogsTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import NMSSH
import CoreData

class VGLogsTableViewController: UITableViewController {
    
    var tracksDict = Dictionary<String, [VGTrack]>()
    var sectionKeys = [String]()
    var cdTracks: [NSManagedObject] = []
    var session: NMSSHSession?
    var sftpSession: NMSFTP?
    var downloadManager: VGSFTPManager?
    var vgFileManager: VGFileManager?
    var vgLogParser: VGLogParser?
    let host = "vehicle-gps-dev.local"
    let username = "pi"
    let password = "easyprintsequence"
    var dataStore:VGDataStore!
    var isDownloadingFile = false
    var isInDownloadingState = false
    var shouldStopDownloading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "LogsTableViewCell", bundle: nil), forCellReuseIdentifier: "LogsCell")
        self.title = "Logs"
        // Add Refresh Control to Table View
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchLogList), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        dataStore = VGDataStore()
        DispatchQueue.global(qos: .background).async {
            self.session = NMSSHSession.init(host: self.host, andUsername: self.username)
            if let session = self.session {
                self.connectToVehicleGPS(session: session)
                self.fetchLogList()
            }
        }
        
        let button = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(self.downloadFiles))
        let button1 = UIBarButtonItem(title: "Parse", style: .plain, target: self, action: #selector(self.processFiles))

        
        self.navigationItem.rightBarButtonItem = button
        self.navigationItem.leftBarButtonItem = button1
        vgLogParser = VGLogParser()
        vgFileManager = VGFileManager()
        tracksDict = tracksToDictionary(trackList: dataStore.getAllTracks())
        tableView.reloadData()
    }
    
    @objc func downloadFiles() {
        if self.isInDownloadingState {
            shouldStopDownloading = true
            self.navigationItem.rightBarButtonItem?.title = "Download"
            self.navigationItem.rightBarButtonItem?.style = .plain
            self.isInDownloadingState = false

            return
        }
        self.isInDownloadingState = true
        self.navigationItem.rightBarButtonItem?.title = "Stop"
        self.navigationItem.rightBarButtonItem?.style = .done
        DispatchQueue.global(qos: .background).async {
            for (sectionIndex, sectionKey) in self.sectionKeys.enumerated() {
                guard let trackList = self.tracksDict[sectionKey] else {
                    continue
                }
                for (rowIndex, track) in trackList.enumerated() {
                    if self.vgFileManager?.getAbsoluteFilePathFor(track: track) == nil {
                    while self.isDownloadingFile {}
                    self.isDownloadingFile = true

                        self.downloadFileFor(track: track, progress: { (received, total) in
                            DispatchQueue.main.async {
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? LogsTableViewCell else {
                                    return
                                }
                                cell.progressView.backgroundColor = UIColor(rgb: 0x007F00).withAlphaComponent(0.2)
                                cell.update(progress: Double(received)/(Double(total)))
                            }
                            return !self.shouldStopDownloading
                        }) { (data) in
                            self.isDownloadingFile = false
                            guard let data = data else {
                                return
                            }
                            _ = self.vgFileManager!.dataToFile(data: data, filename: track.fileName)
                            DispatchQueue.main.async {
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? LogsTableViewCell else {
                                    return
                                }
                                cell.fileOnDeviceIndicator.isHidden = false
                                cell.update(progress:0)
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    @objc func processFiles() {
        DispatchQueue.global(qos: .background).async {
            for (sectionIndex, sectionKey) in self.sectionKeys.enumerated() {
                guard let trackList = self.tracksDict[sectionKey] else {
                    continue
                }
                for (rowIndex, track) in trackList.enumerated() {
                    if !track.processed && self.vgFileManager?.getAbsoluteFilePathFor(track: track) != nil {
                        DispatchQueue.main.async {
                            guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? LogsTableViewCell else {
                                return
                            }
                            cell.activityView.startAnimating()
                            track.beingProcessed = true
                        }
                        self.vgLogParser?.fileToTrack(fileUrl: (self.vgFileManager?.getAbsoluteFilePathFor(track: track))!, progress: { (current, total) in
                            DispatchQueue.main.async {
                                track.beingProcessed = false
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? LogsTableViewCell else {
                                    return
                                }
                                cell.activityView.stopAnimating()
                                cell.update(progress: Double(current)/Double(total))
                            }
                        }, callback: { (track) in
                            self.dataStore.update(vgTrack: track)
                            DispatchQueue.main.async {
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? LogsTableViewCell else {
                                    return
                                }
                                cell.show(track: track)
                                cell.update(progress:0)
                            }
                        })
                    }
                }
            }
        }
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func fetchLogList() {
        var trackList = [VGTrack]()


        DispatchQueue.global(qos: .background).async {
            if self.downloadManager == nil {
                self.reconnectToVehicleGPS(session: self.session!)
                if self.downloadManager == nil {
                    DispatchQueue.main.async {
                        self.tableView.refreshControl?.endRefreshing()
                    }
                    return
                }
            }
            self.reconnectToVehicleGPS(session: self.session!)
            DispatchQueue.main.async {
                self.tableView.refreshControl?.beginRefreshing()
            }
            guard let fileList = self.downloadManager!.getRemoteFiles() else {
                // TODO: Show Error Message
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
                return
            }
            
            for file in fileList {
                let track = VGTrack()
                track.fileName = file.filename
                track.fileSize = file.fileSize as! Int
                track.isRemote = true
                trackList.append(track)
            }
            
            let combinedList = self.combineLists(localList: self.dataStore.getAllTracks(), remoteList: trackList)
            self.tracksDict = self.tracksToDictionary(trackList: combinedList)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            }
        }

    }
    
    func combineLists(localList:[VGTrack], remoteList:[VGTrack]) -> [VGTrack] {
        var result = localList
        
        for track in result {
            if remoteList.contains(track) {
                track.isRemote = true
            }
        }
        
        for track in remoteList {
            track.isRemote = true
            if !(result.contains(track)) {
                result.append(track)
            }
        }
        return result
    }
    func displayErrorAlert(title:String?, message:String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func reconnectToVehicleGPS(session:NMSSHSession) {
        if !session.isConnected || !session.isAuthorized || !sftpSession!.isConnected {
            connectToVehicleGPS(session: session)
        }
    }
    
    func tryToConnectSSH(session:NMSSHSession) -> Bool {
        session.connect()
        if !session.isConnected {
            DispatchQueue.main.async {
                self.displayErrorAlert(title: "SSH Connection Error", message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func tryToAuthenticate(session:NMSSHSession) -> Bool {
        session.authenticate(byPassword: self.password)
        
        if !session.isAuthorized {
            DispatchQueue.main.async {
                self.displayErrorAlert(title: "Authorization Error", message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func tryToConnectSFTP(session:NMSSHSession) -> Bool {
        sftpSession = NMSFTP(session: session)
        guard let sftpSession = sftpSession else {
            return false
        }
        self.sftpSession = sftpSession
        
        sftpSession.connect()
        
        if !sftpSession.isConnected {
            DispatchQueue.main.async {
                self.displayErrorAlert(title: "SFTP Connection Error", message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func connectToVehicleGPS(session:NMSSHSession) {
        if tryToConnectSSH(session: session) != true {
            return
        }
        
        if tryToAuthenticate(session: session) != true {
            return
        }
        
        if tryToConnectSFTP(session: session) != true {
            return
        }
        
        self.downloadManager = VGSFTPManager(session: self.sftpSession!)
    }
    
    func tracksToDictionary(trackList:[VGTrack]) -> Dictionary<String, [VGTrack]>{
        var result = Dictionary<String, [VGTrack]>()
        for track in trackList {
            let day = String(track.fileName.prefix(10))
            
            if result[day] == nil {
                result[day] = [VGTrack]()
            }
            if !sectionKeys.contains(day) {
                sectionKeys.append(day)
            }
            result[day]!.append(track)
        }
        
        // Reorder the sections and lists to display the newest log first.
        self.sectionKeys = self.sectionKeys.sorted().reversed()
        
        for (day, list) in result {
            result[day] = list.sorted(by: { $0.fileName > $1.fileName })
        }
        
        return result
    }
    
    func getTrackAt(indexPath:IndexPath) -> VGTrack {
        var dayFileList = tracksDict[sectionKeys[indexPath.section]]
        let file = dayFileList![indexPath.row]
        return file
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionKeys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tracksDict[sectionKeys[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let day = sectionKeys[section]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        let date = dateFormatter.date(from:day)!
        
        dateFormatter.dateStyle = .full
        dateFormatter.locale = Locale(identifier: "is_IS")
        var dateString = dateFormatter.string(from: date)
        var totalDuration = 0.0
        var totalDistance = 0.0
        var distanceString = ""
        var durationString = ""
        for track in tracksDict[day]! {
            totalDuration += track.duration
            totalDistance += track.distance
        }
        let distanceFormatter = LengthFormatter()
        distanceFormatter.numberFormatter.maximumFractionDigits = 2
        distanceFormatter.numberFormatter.minimumFractionDigits = 2
        if totalDistance > 1 {
            distanceString = distanceFormatter.string(fromValue: totalDistance, unit: .kilometer)
        } else {
            distanceString = distanceFormatter.string(fromValue: totalDistance*1000, unit: .meter)
        }
        
        let form = DateComponentsFormatter()
        form.unitsStyle = .positional
        form.allowedUnits = [ .hour, .minute, .second ]
        form.zeroFormattingBehavior = [ .default ]
        
        let formattedDuration = form.string(from: totalDuration)
        durationString = String(formattedDuration!)


        
        dateString += " - " + distanceString + " - " + durationString
        return dateString
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "LogsCell",
            for: indexPath
            ) as? LogsTableViewCell else {
            return UITableViewCell()
        }
        cell.update(progress: 0.0)
        
        let track = getTrackAt(indexPath: indexPath)
        cell.show(track:track)
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = getTrackAt(indexPath: indexPath)
        let cell = self.tableView.cellForRow(at: indexPath) as! LogsTableViewCell
        
        if vgFileManager!.getAbsoluteFilePathFor(track:track) == nil {
            self.downloadFileFor(track: track, progress: { (received, total) in
                DispatchQueue.main.async {
                    cell.update(progress: Double(received)/Double(total))
                    cell.layoutSubviews()
                }
                return true
            }) { (data) in
                guard let data = data else {
                    return
                }
                
                _ = self.vgFileManager!.dataToFile(data: data, filename: track.fileName)

                let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
                logDetailsView.dataStore = self.dataStore
                logDetailsView.track = track
                
                DispatchQueue.main.async {
                    cell.update(progress: 0.0)
                    self.navigationController?.pushViewController(logDetailsView, animated: true)
                }
            }
        } else {
            let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
            logDetailsView.dataStore = self.dataStore
            logDetailsView.track = track
            self.navigationController?.pushViewController(logDetailsView, animated: true)
            
        }
        
        
    }
    
    func downloadFileFor(track: VGTrack, progress:@escaping (UInt, UInt)->Bool, callback:@escaping (Data?)->Void) {
        
        self.downloadManager?.downloadFile(filename: track.fileName, progress: { (received, total) in
            progress(received, total)
        }, callback: { (data) in
            callback(data)
        })
    }
    

    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
 

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let track = self.getTrackAt(indexPath: indexPath)
            
            self.downloadManager?.deleteFile(filename: track.fileName, callback: { (success) in
                if success {
                    DispatchQueue.main.async {
                        self.tracksDict[self.sectionKeys[indexPath.section]]?.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)

                        if self.tracksDict[self.sectionKeys[indexPath.section]]?.count == 0 {
                            self.sectionKeys.remove(at: indexPath.section)
                            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
                        }
                        
                        self.vgFileManager?.deleteFileFor(track: track)
                        self.dataStore.delete(vgTrack: track)
                    }
                }
            })
        }
    }
}
