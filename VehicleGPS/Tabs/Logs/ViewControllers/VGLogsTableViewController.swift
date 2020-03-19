import UIKit
import NMSSH
import CoreData

class VGLogsTableViewController: UITableViewController, DisplaySelectVehicleProtocol {
    func didTapVehicle(track: VGTrack) {
        let selectionVC = VGVehiclesSelectionTableViewController(style: .insetGrouped)
        selectionVC.track = track
        present(UINavigationController(rootViewController: selectionVC), animated: true, completion: nil)
    }
    
    
    // MARK: - Class Variables
    var tracksDict = [String: [VGTrack]]()
    var remoteList = [VGTrack]()
    var sectionKeys = [String]()
    var cdTracks: [NSManagedObject] = []
    var session: NMSSHSession?
    var sftpSession: NMSFTP?
    var downloadManager: VGSFTPManager?
    var vgFileManager: VGFileManager?
    var vgLogParser: IVGLogParser?
    let host = "cargps.local"
    let username = "pi"
    let password = "easyprintsequence"
    var dataStore:VGDataStore!
    var isDownloadingFile = false
    var isInDownloadingState = false
    var shouldStopDownloading = false
    var downloadCount = 0
    var parseCount = 0
    let headerDateFormatter = VGHeaderDateFormatter()
    var headerView: VGDeviceConnectedHeaderView!
    let distanceFormatter = VGDistanceFormatter()
    let durationFormatter = VGDurationFormatter()
    var emptyLabel: UILabel!
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        initializeTableViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeTableViewController()

    }

    func initializeTableViewController() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        title = NSLocalizedString("Ferlar", comment: "Vehicles Title")
        tabBarItem = UITabBarItem(title: NSLocalizedString("Ferlar", comment: "Vehicles Title"),
                                  image: UIImage(imageLiteralResourceName: "LogIcon"),
                                  tag: 0)
    }
    
    // MARK: - View Did Load Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeClasses()
        configureEmptyListLabel()
        configureNavigationBar()
        configureRefreshControl()
        setUpDeviceConnectedBanner()
        registerCells()
        startConnectionToVGPS()
        updateData()
    }
    
    fileprivate func initializeClasses() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
            self.vgFileManager = appDelegate.fileManager
        }
    }
    
    fileprivate func configureEmptyListLabel() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            emptyLabel = VGListEmptyLabel(text: NSLocalizedString("Engir ferlar", comment: ""),
                                          containerView: self.view,
                                          navigationBar: navigationController!.navigationBar,
                                          tabBar: delegate.tabController.tabBar)
        }

        view.addSubview(emptyLabel)
    }
    
    fileprivate func configureNavigationBar() {
        let button1 = UIBarButtonItem(title: NSLocalizedString("Þátta", comment: ""), style: .plain, target: self, action: #selector(self.processFiles))
        self.navigationItem.leftBarButtonItem = button1
        self.navigationItem.rightBarButtonItem = editButtonItem
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
    }
    
    fileprivate func configureRefreshControl() {
        // Add Refresh Control to Table View
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchLogList), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    fileprivate func setUpDeviceConnectedBanner() {
        self.headerView = VGDeviceConnectedHeaderView.loadFromNibNamed(nibNamed: "VGDeviceConnectedHeaderView")
        self.headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0)
        self.tableView.tableHeaderView = self.headerView
        self.headerView.lblLogsAvailable.isHidden = true
        self.headerView.lblConnectedToGPS.isHidden = true
        self.headerView.imgIcon.isHidden = true
        self.headerView.greenButton.isHidden = true
        
        // Add tap gesture recognizers to the views
        let headerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.headerViewTapped(_:)))
        let downloadTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.downloadFiles))

        self.headerView.greenBackground.addGestureRecognizer(headerTapRecognizer)
        self.headerView.greenButton.addGestureRecognizer(downloadTapRecognizer)
    }
    
    fileprivate func registerCells() {
        let logsTableViewCellNib = UINib(nibName: "VGLogsTableViewCell", bundle: nil)
        let logHeaderViewNib = UINib(nibName: "VGLogHeaderView", bundle: nil)
        
        self.tableView.register(logsTableViewCellNib, forCellReuseIdentifier: "LogsCell")
        self.tableView.register(logHeaderViewNib, forHeaderFooterViewReuseIdentifier: "LogsHeader")
    }

    fileprivate func startConnectionToVGPS() {
        DispatchQueue.global(qos: .background).async {
            self.session = NMSSHSession.init(host: self.host, andUsername: self.username)
            if self.session != nil {
                self.fetchLogList()
            }
        }
    }
    

    // MARK: - Interface Action Functions
    @objc func headerViewTapped(_:Any?) {
        let dlViewController = VGDownloadLogsViewController(downloadManager: self.downloadManager)
        dlViewController.tracks = self.combineLists(localList: self.dataStore.getAllTracks(), remoteList: remoteList)
        navigationController?.pushViewController(dlViewController, animated: true)
    }
    
    @objc func downloadFiles() {
        if self.isInDownloadingState {
            shouldStopDownloading = true
//            self.navigationItem.rightBarButtonItem?.title = "Hlaða niður"
//            self.navigationItem.rightBarButtonItem?.style = .plain
            self.isInDownloadingState = false
            UIApplication.shared.isIdleTimerDisabled = true

            return
        }
        self.isInDownloadingState = true
        UIApplication.shared.isIdleTimerDisabled = false
//        self.navigationItem.rightBarButtonItem?.title = "Stöðva"
//        self.navigationItem.rightBarButtonItem?.style = .done
        
        for key in self.sectionKeys {
            guard let trackList = self.tracksDict[key] else {
                continue
            }
            for track in trackList {
                if self.vgFileManager?.getAbsoluteFilePathFor(track: track) == nil {
                    self.downloadCount += 1
                }
            }
        }
        self.headerView.lblLogsAvailable.text = "Hleður niður. \(downloadCount) ferlar eftir."
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
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? VGLogsTableViewCell else {
                                    return
                                }
                                cell.progressView.backgroundColor = UIColor(rgb: 0x007F00).withAlphaComponent(0.2)
                                cell.update(progress: Double(received)/(Double(total)))
                                if self.shouldStopDownloading {
                                    cell.update(progress: 0.0)
                                }
                            }
                            return !self.shouldStopDownloading
                        }) { (data) in
                            self.isDownloadingFile = false
                            self.downloadCount -= 1
                            guard let data = data else {
                                return
                            }
                            _ = self.vgFileManager!.dataToFile(data: data, filename: track.fileName)
                            self.dataStore.update(vgTrack: track)
                            DispatchQueue.main.async {
                                if self.downloadCount == 0 {
                                    UIApplication.shared.isIdleTimerDisabled = false
                                    self.headerView.lblLogsAvailable.text = "Niðurhali lokið."

                                } else {
                                    self.headerView.lblLogsAvailable.text = "Hleður niður. \(self.downloadCount) ferlar eftir."
                                }
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? VGLogsTableViewCell else {
                                    return
                                }
                                cell.update(progress: 0)
                            }
                            
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                if self.downloadCount == 0 {
                    self.headerView.lblLogsAvailable.text = "Engir nýjir ferlar í boði"
                }
//                self.navigationItem.rightBarButtonItem?.title = "Hlaða niður"
//                self.navigationItem.rightBarButtonItem?.style = .plain
                self.isInDownloadingState = false
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
    }
    
    @objc func processFiles() {
        UIApplication.shared.isIdleTimerDisabled = true
        for key in self.sectionKeys {
            guard let trackList = self.tracksDict[key] else {
                continue
            }
            for track in trackList {
                if !track.processed && self.vgFileManager?.getAbsoluteFilePathFor(track: track) != nil {
                    self.parseCount += 1
                }
            }
        }
        self.navigationItem.prompt = "Þátta. \(parseCount) ferlar eftir."
        
        for (sectionIndex, sectionKey) in self.sectionKeys.enumerated() {
            guard let trackList = self.tracksDict[sectionKey] else {
                continue
            }
            for (rowIndex, track) in trackList.enumerated() {
                DispatchQueue.global(qos: .background).async {
                    if !track.processed && self.vgFileManager?.getAbsoluteFilePathFor(track: track) != nil {
                        track.beingProcessed = true
                        DispatchQueue.main.async {
                            guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? VGLogsTableViewCell else {
                                return
                            }
                            cell.activityView.startAnimating()
                        }
                        self.vgLogParser = self.vgFileManager?.getParser(for: track)
                        self.vgLogParser?.fileToTrack(fileUrl: (self.vgFileManager?.getAbsoluteFilePathFor(track: track))!, progress: { (current, total) in
                            DispatchQueue.main.async {
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? VGLogsTableViewCell else {
                                    return
                                }
                                cell.update(progress: Double(current)/Double(total))
                            }
                        }, callback: { (track) in
                            self.dataStore.update(vgTrack: track)
                            self.tracksDict[sectionKey]![rowIndex] = track
                            DispatchQueue.main.async {
                                self.parseCount -= 1
                                if self.parseCount == 0 {
                                    UIApplication.shared.isIdleTimerDisabled = false
                                    self.navigationItem.prompt = nil
                                }
                                self.navigationItem.prompt = "Þátta. \(self.parseCount) ferlar eftir."
                                track.beingProcessed = true
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? VGLogsTableViewCell else {
                                    return
                                }
                                cell.show(track: track)
                                cell.update(progress: 0)
                                if let header = self.tableView.headerView(forSection: sectionIndex) as? VGLogHeaderView {
                                    self.getViewForHeader(view: header, section: sectionIndex)
                                }
                                track.trackPoints = []
                            }
                            
                        }, imageCallback: { (track, style) in
                            track.beingProcessed = false
                            DispatchQueue.main.async {
                                guard let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? VGLogsTableViewCell else {
                                    return
                                }
                                cell.show(track: track)
                                if style == self.traitCollection.userInterfaceStyle {
                                    cell.activityView.stopAnimating()
                                }
                            }
                        })
                    }
                }
            }
        }
        UIApplication.shared.isIdleTimerDisabled = false
        self.navigationItem.prompt = nil
        
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
            DispatchQueue.main.async {
                self.tableView.refreshControl?.beginRefreshing()
            }
            guard let fileList = self.downloadManager!.getRemoteFiles() else {
                // TODO: Show Error Message
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if self.tracksDict.count > 0 {
                        self.emptyLabel.isHidden = true
                        self.tableView.separatorStyle = .singleLine
                    } else {
                        self.emptyLabel.isHidden = false
                        self.tableView.separatorStyle = .none
                    }
                    self.tableView.refreshControl?.endRefreshing()
                }
                return
            }
            var newFileCount = 0
            
            for file in fileList {
                let track = VGTrack()
                track.fileName = file.filename
                if let fileSize = file.fileSize as? Int {
                    track.fileSize = fileSize
                }
                if !self.vgFileManager!.fileForTrackExists(track: track) {
                    newFileCount += 1
                }
                self.remoteList.append(track)
                track.isRemote = true
                trackList.append(track)
            }
            
            let combinedList = self.combineLists(localList: self.dataStore.getAllTracks(), remoteList: trackList)
            self.tracksDict = self.tracksToDictionary(trackList: combinedList)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if newFileCount == 0 {
                    self.headerView.lblLogsAvailable.text = "Engir nýir ferlar í boði"
                } else if newFileCount == 1 {
                    self.headerView.lblLogsAvailable.text = "\(newFileCount) nýr ferill í boði"
                } else if (newFileCount-1)%10 == 0 && newFileCount != 11 {
                    self.headerView.lblLogsAvailable.text = "\(newFileCount) nýr ferill í boði"
                } else {
                    self.headerView.lblLogsAvailable.text = "\(newFileCount) nýir ferlar í boði"
                }
                if newFileCount == 0 {
                    self.headerView.greenButton.isHidden = true
                } else {
                    self.headerView.greenButton.isHidden = false
                }
                
                if self.tracksDict.count > 0 {
                    self.emptyLabel.isHidden = true
                    self.tableView.separatorStyle = .singleLine
                } else {
                    self.emptyLabel.isHidden = false
                    self.tableView.separatorStyle = .none
                }
                self.tableView.refreshControl?.endRefreshing()
            }
        }

    }
    
    
    // MARK: - GPS Connection Related Functions
    func displayErrorAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func reconnectToVehicleGPS(session: NMSSHSession) {
        if !session.isConnected || !session.isAuthorized || !sftpSession!.isConnected {
            if connectToVehicleGPS(session: session) {
                DispatchQueue.main.async {

                    self.headerView.lblLogsAvailable.isHidden = false
                    self.headerView.lblConnectedToGPS.isHidden = false
                    self.headerView.imgIcon.isHidden = false
                    self.headerView.lblConnectedToGPS.text = "Tengt við \(self.session!.host)"

                    self.headerView.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 51)
                    self.tableView.tableHeaderView = self.headerView
                }
                
            } else {
                DispatchQueue.main.async {
                    self.tableView.tableHeaderView = nil
                }
            }
            
        } else {
            DispatchQueue.main.async {
                self.tableView.tableHeaderView = nil
            }
        }
    }
    
    func tryToConnectSSH(session: NMSSHSession) -> Bool {
        if !session.connect() {
            DispatchQueue.main.async {
                //self.displayErrorAlert(title: "SSH Connection Error", message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func tryToAuthenticate(session: NMSSHSession) -> Bool {
        if !session.authenticate(byPassword: self.password) {
            DispatchQueue.main.async {
                self.displayErrorAlert(title: "Authorization Error", message: self.session?.lastError?.localizedDescription)
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
                self.displayErrorAlert(title: "SFTP Connection Error", message: self.session?.lastError?.localizedDescription)
            }
            return false
        }
        return true
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
    
    //MARK: - List Manipulation
    func updateData() {
        self.tracksDict = self.tracksToDictionary(trackList: self.dataStore.getAllTracks())
        tableView.reloadData()
        if self.tracksDict.count > 0 {
            self.emptyLabel.isHidden = true
            self.tableView.separatorStyle = .singleLine
        } else {
            self.emptyLabel.isHidden = false
            self.tableView.separatorStyle = .none
        }
    }
    
    func combineLists(localList: [VGTrack], remoteList: [VGTrack]) -> [VGTrack] {
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
    
    func tracksToDictionary(trackList:[VGTrack]) -> Dictionary<String, [VGTrack]>{
        var result = Dictionary<String, [VGTrack]>()
        for track in trackList {
            var day = ""
            if let timeStart = track.timeStart {
                day = String(String(describing: timeStart).prefix(10))
            } else {
                day = String(track.fileName.prefix(10))
            }
            
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
            result[day] = list.sorted { (first, second) -> Bool in
                if first.timeStart != nil && second.timeStart != nil {
                    return first.timeStart! > second.timeStart!
                }
                return first.fileName > second.fileName
            }
        }
        
        return result
    }
    
    func getTrackAt(indexPath:IndexPath) -> VGTrack? {
        guard let dayFileList = tracksDict[sectionKeys[indexPath.section]] else {
            return nil
        }
        let file = dayFileList[indexPath.row]
        return file
    }
    
    func getViewForHeader(view:VGLogHeaderView, section:Int) {
        let day = sectionKeys[section]
        view.dateLabel.text = " "
        view.detailsLabel.text = " "

        let dateString = headerDateFormatter.sectionKeyToDateString(sectionKey: day)
        var totalDuration = 0.0
        var totalDistance = 0.0
        var distanceString = ""
        var durationString = ""
        guard let trackSection = tracksDict[day] else {
            return
        }
        for track in trackSection {
            totalDuration += track.duration
            totalDistance += track.distance
        }
        distanceString = distanceFormatter.string(fromMeters: totalDistance*1000)
        
        let formattedDuration = durationFormatter.string(from: totalDuration)
        durationString = String(formattedDuration!)
        
        view.dateLabel.text = dateString
        view.detailsLabel.text = distanceString + " - " + durationString
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionKeys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let tracksForSection = tracksDict[sectionKeys[section]] else {
            return 0
        }
        return tracksForSection.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "LogsHeader") as? VGLogHeaderView else {
            return UIView()
        }
        getViewForHeader(view: view, section: section)
        return view
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "LogsCell",
            for: indexPath
            ) as? VGLogsTableViewCell else {
            return UITableViewCell()
        }
        cell.update(progress: 0.0)
        cell.delegate = self
        if let track = getTrackAt(indexPath: indexPath) {
            cell.show(track:track)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = self.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
            return
        }
        guard let track = getTrackAt(indexPath: indexPath) else {
            return
        }
        track.trackPoints = dataStore.getPointsForTrack(vgTrack: track)
        if track.trackPoints.count > 0 {
            let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
            logDetailsView.dataStore = self.dataStore
            logDetailsView.track = track
            self.navigationController?.pushViewController(logDetailsView, animated: true)
            return
        }
        
        
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
                self.dataStore.update(vgTrack: track)
                
                DispatchQueue.main.async {
                    let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
                    logDetailsView.dataStore = self.dataStore
                    logDetailsView.track = track
                    
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
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    

    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Eyða"
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
            guard let track = self.getTrackAt(indexPath: indexPath) else {
                return
            }
            
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
}
