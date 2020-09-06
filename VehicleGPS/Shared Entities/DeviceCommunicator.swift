import Foundation
import NMSSH

class DeviceCommunicator {
    
    var session: NMSSHSession?
    var sftpSession: NMSFTP?
    var downloadManager: VGSFTPManager?
    var fileManager = VGFileManager()
    var dataStore = VGDataStore()
    
    init() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let host = self.dataStore.getHost(), let username = self.dataStore.getUsername() else {
                return
            }
            self.session = NMSSHSession.init(host: host, andUsername: username)
            self.reconnectToVehicleGPS(session: self.session!)
        }
    }
    
    func connectToVehicleGPS(session:NMSSHSession) -> Bool {
        if tryToConnectSSH(session: session) != true {
            return false
        }
        
        if tryToAuthenticate(session: session) != true {
            return false
        }
        
        if tryToConnectSFTP(session: session) != true {
            return false
        }
        
        self.downloadManager = VGSFTPManager(session: self.sftpSession!)
        return true
    }
    
    func disconnectFromVehicleGPS() {
        
        if sftpSession != nil {
            if sftpSession!.isConnected {
                sftpSession!.disconnect()
            }
        }
        
        if session != nil {
            if session!.isConnected {
                session!.disconnect()
            }
        }
        
        NotificationCenter.default.post(name: .deviceDisconnected, object: nil)

    }
    
    func reconnectToVehicleGPS() {
        guard let session = self.session else {
            return
        }
        reconnectToVehicleGPS(session: session)

    }
    fileprivate func reconnectToVehicleGPS(session: NMSSHSession) {
        if !session.isConnected || !session.isAuthorized || !sftpSession!.isConnected {
            if connectToVehicleGPS(session: session) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .deviceConnected, object: session)
                }
                return
            }
            return
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .deviceDisconnected, object: nil)
        }
    }
    
    func tryToConnectSSH(session: NMSSHSession) -> Bool {
        if !session.connect(withTimeout: 5) {
            DispatchQueue.main.async {
                //self.displayErrorAlert(title: "SSH Connection Error", message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func tryToAuthenticate(session: NMSSHSession) -> Bool {
        if !session.authenticate(byPassword: Constants.sftp.password) {
            DispatchQueue.main.async {
                // TODO: Maybe display an error to the user
                //self.displayErrorAlert(title: Strings.authorizationError, message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func tryToConnectSFTP(session: NMSSHSession) -> Bool {
        sftpSession = NMSFTP(session: session)
        guard let sftpSession = sftpSession else {
            return false
        }
        self.sftpSession = sftpSession
        
        sftpSession.connect()
        
        if !sftpSession.isConnected {
            DispatchQueue.main.async {
                //self.displayErrorAlert(title: Strings.sftpConnError, message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func getAvailableFiles(onSuccess:@escaping([NMSFTPFile])->(), onFailure:@escaping(String)->()) {
        // Reconnect if not connected.
        if self.downloadManager == nil {
            self.reconnectToVehicleGPS(session: self.session!)
            if self.downloadManager == nil {
                DispatchQueue.main.async {
                    onSuccess([])
                }
                return
            }
            DispatchQueue.main.async {
                onFailure("Could not establish a connection to the VGPS")
            }
        }
        
        // Fetch the files from the VGPS.
        guard let fileList = self.downloadManager!.getRemoteFiles() else {
            // TODO: Show Error Message
            DispatchQueue.main.async {
                onFailure("Could not get file list")
            }
            return
        }
        
        DispatchQueue.main.async {
            onSuccess(fileList)
        }
    }
    
    func downloadTrackFile(file:NMSFTPFile, progress:@escaping(UInt,UInt)->(), onSuccess:@escaping(URL?)->(), onFailure:@escaping(String)->()) {
        self.downloadManager?.downloadFile(filename: file.filename, progress: { (received, total) -> Bool in
            progress(received, total)
            return true
        }, callback: { [unowned self] (data) in
            if let data = data {
                onSuccess(self.fileManager.saveDownloaded(data: data, filename: file.filename))
            } else {
                onFailure("No data to write.")
            }
        })
    }
}



