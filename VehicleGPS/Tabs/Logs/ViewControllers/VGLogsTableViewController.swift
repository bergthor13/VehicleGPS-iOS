import UIKit
import NMSSH
import CoreData
import CoreServices
import UniformTypeIdentifiers

class VGLogsTableViewController: UITableViewController {
    
    // MARK: Variables
    var tracksDictionary = [String: [VGTrack]]()
    var sections = [String]()

    // MARK: Classes
    var vgFileManager: VGFileManager?
    var vgLogParser: IVGLogParser?
    var dataStore: VGDataStore!
    let vgGPXGenerator = VGGPXGenerator()
    
    // MARK: Views
    var headerView: VGDeviceConnectedHeaderView!
    var emptyLabel: UILabel!
    
    // MARK: Formatters
    let headerDateFormatter = VGHeaderDateFormatter()
    let dateParsingFormatter = VGDateParsingFormatter()
    
    // MARK: File Lists
    var filesOnDevice = [NMSFTPFile]()
    var downloadedFiles = [DownloadedFile]()
    var undownloadedFiles = [NMSFTPFile]()
    
    // MARK: Toolbar Buttons
    var toolbarButtonShare: UIBarButtonItem!
    var toolbarButtonDelete: UIBarButtonItem!

    // MARK: - Initializers
    override init(style: UITableView.Style) {
        super.init(style: style)
        initializeTableViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeTableViewController()

    }
    
    // MARK: - Button Actions
    // MARK: Toolbar
    @objc func deleteTracks(_ sender: UIBarButtonItem) {
        print("DELETING SELECTED TRACKS")
    }
    
    @objc func exportTracks(_ sender: UIBarButtonItem) {
        var tracks = [VGTrack]()
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        for indexPath in indexPaths {
            guard let track = getTrackAt(indexPath: indexPath) else {
                continue
            }
            tracks.append(track)
        }
        
        let dpGroup = DispatchGroup()
        for track in tracks {
            dpGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataStore.getDataPointsForTrack(with: track.id!, onSuccess: { (dataPoints) in
                    track.trackPoints = dataPoints
                    dpGroup.leave()
                }, onFailure: { (error) in
                    self.appDelegate.display(error: error)
                    dpGroup.leave()
                })
            }
        }
        dpGroup.wait()
        if let fileUrl = self.vgGPXGenerator.generateGPXFor(tracks: tracks) {
            let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = self.toolbarButtonShare
            self.present(activityVC, animated: true, completion: nil)
        } else {
            displayErrorAlert(title: "Could not generate GPX", message: "An error occurred and generating a GPX file failed.")
        }
    }
    
    @objc func downloadFiles() {
        self.headerView.displayProgressBar()
        let group1 = DispatchGroup()
        let group2 = DispatchGroup()
        group1.enter()
        DispatchQueue.global(qos: .utility).async {
            let totalCount = self.undownloadedFiles.count
            var downloadProgress = [Double]() {
                didSet {
                    let percentage = downloadProgress.reduce(0, +)/Double(totalCount)
                    DispatchQueue.main.async {
                        self.headerView.setDownloadProgress(percentage: percentage)
                    }
                }
            }
            var parseProgress = [Double]() {
                didSet {
                    let percentage = parseProgress.reduce(0, +)/Double(totalCount)
                    DispatchQueue.main.async {
                        self.headerView.setParseProgress(percentage: percentage)
                    }
                }
            }
            for _ in 0 ..< totalCount {
                downloadProgress.append(0)
                parseProgress.append(0)
            }
            for (index, file) in self.undownloadedFiles.enumerated() {
                group2.enter()
                self.appDelegate.deviceCommunicator.downloadTrackFile(file: file, progress: { (current, total) in
                    downloadProgress[index] = Double(current)/Double(total)
                }, onSuccess: { (fileUrl) in
                    downloadProgress[index] = 1
                    DispatchQueue.global(qos: .utility).async {
                        guard let fileManager = self.vgFileManager else {
                            let downlFile = VGDownloadedFile(name: file.filename, size: file.fileSize as? Int)
                            self.dataStore.add(file: downlFile, onSuccess: {
                                parseProgress[index] = 1
                                group2.leave()
                            }, onFailure: { (error) in
                                parseProgress[index] = 1
                                group2.leave()
                            })
                            return
                        }
                        guard let fileUrl = fileUrl else {
                            let downlFile = VGDownloadedFile(name: file.filename, size: file.fileSize as? Int)
                            self.dataStore.add(file: downlFile, onSuccess: {
                                parseProgress[index] = 1
                                group2.leave()
                            }, onFailure: { (error) in
                                parseProgress[index] = 1
                                group2.leave()
                            })
                            return
                        }
                        guard let parser = fileManager.getParser(for: fileUrl) else {
                            let downlFile = VGDownloadedFile(name: file.filename, size: file.fileSize as? Int)
                            self.dataStore.add(file: downlFile, onSuccess: {
                                parseProgress[index] = 1
                                group2.leave()
                            }, onFailure: { (error) in
                                parseProgress[index] = 1
                                group2.leave()
                            })
                            return
                        }
                        parser.fileToTrack(fileUrl: fileUrl, progress: { (current, total) in
                            parseProgress[index] = Double(current)/Double(total)
                        }, onSuccess: { [unowned self] (track) in
                            let existingIndexPath = self.getIndexPath(for: file.filename)
                            if existingIndexPath != nil {
                                let existingTrack = self.getTrackAt(indexPath: existingIndexPath!)!
                                track.id = existingTrack.id
                                self.dataStore.update(vgTrack: track, onSuccess: { [unowned self] (id) in
                                    track.trackPoints = []
                                    track.mapPoints = []
                                    let downlFile = VGDownloadedFile(name: file.filename, size: file.fileSize as? Int)
                                    self.dataStore.update(file: downlFile, onSuccess: {
                                        parseProgress[index] = 1
                                        group2.leave()
                                    }, onFailure: { (error) in
                                        parseProgress[index] = 1
                                        group2.leave()
                                    })
                                }, onFailure: { (error) in
                                    parseProgress[index] = 1
                                    self.appDelegate.display(error: error)
                                    group2.leave()
                                })
                            } else {
                                self.dataStore.add(vgTrack: track, onSuccess: { [unowned self] (id) in
                                    track.trackPoints = []
                                    track.mapPoints = []
                                    let downlFile = VGDownloadedFile(name: file.filename, size: file.fileSize as? Int)
                                    self.dataStore.add(file: downlFile, onSuccess: {
                                        parseProgress[index] = 1
                                        group2.leave()
                                    }, onFailure: { (error) in
                                        parseProgress[index] = 1
                                        group2.leave()
                                    })
                                    
                                }, onFailure: { (error) in
                                    parseProgress[index] = 1
                                    self.appDelegate.display(error: error)
                                    group2.leave()
                                })
                            }
                        }, onFailure: {error in
                            parseProgress[index] = 1
                            self.appDelegate.display(error: error)
                            group2.leave()
                            
                        })
                    }
                }, onFailure: { error in
                    downloadProgress[index] = 1
                    self.appDelegate.display(error: error)
                    group2.leave()
                })
            }
            group2.wait()
            group1.leave()
        }
        
        group1.notify(queue: .global()) {
            DispatchQueue.main.async {
                self.headerView.downloadComplete()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               self.searchForNewLogs(shouldDownloadFiles: false)
            }
        }
        
    }

    // MARK: Notifications
    
    @objc func onVehicleAddedToLog(_ notification: Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        guard let vehicle = newTrack.vehicle else {
            return
        }
        guard let indexPath = getIndexPath(for: newTrack) else {
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
            return
        }
        getTrackAt(indexPath: indexPath)?.vehicle = newTrack.vehicle
        
        cell.lblVehicle.text = vehicle.name
    }
    
    @objc func onLogsAdded(_ notification: Notification) {
        guard let newTracks = notification.object as? [VGTrack] else {
            return
        }

        DispatchQueue.main.async {
            var list = [VGTrack]()
            _ = self.tracksDictionary.map {
                for item in $1 {
                    list.append(item)
                }
            }
            (self.sections, self.tracksDictionary) = LogDateSplitter.splitLogsByDate(trackList: self.combineLists(localList: list, remoteList: newTracks))

            self.tableView.reloadData()
            if self.tracksDictionary.count > 0 {
                self.emptyLabel.isHidden = true
                self.tableView.separatorStyle = .singleLine
            } else {
                self.emptyLabel.isHidden = false
                self.tableView.separatorStyle = .none
            }
        }
    }
    
    @objc func onLogUpdated(_ notification: Notification) {
        guard let updatedTrack = notification.object as? VGTrack else {
            return
        }

        DispatchQueue.main.async {
            
            guard let indexPath = self.getIndexPath(for: updatedTrack) else {
                return
            }
            
            guard let cell = self.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            
            if self.tracksDictionary[self.sections[indexPath.section]] == nil {
                return
            }
            
            self.tracksDictionary[self.sections[indexPath.section]]![indexPath.row] = updatedTrack
            cell.show(track: updatedTrack)
        }
    }
        
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeClasses()
        configureNavigationBar()
        configureToolbar()
        setUpDeviceConnectedBanner()
        registerCells()
        updateData()
        addObservers()
        configureEmptyListLabel()
        tableView.allowsMultipleSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if !editing {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let visibleCells = tableView.visibleCells as? [VGLogsTableViewCell] else {
            return
        }
        
        for cell in visibleCells where cell.currentTrack!.isRecording {
            cell.animateRecording()
        }
    }
    
    // MARK: - Setup Functions
    
    fileprivate func setUpDeviceConnectedBanner() {
        self.headerView = VGDeviceConnectedHeaderView.loadFromNibNamed(nibNamed: VGDeviceConnectedHeaderView.nibName)
        self.headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 51)
        self.headerView.lblLogsAvailable.isHidden = false
        self.headerView.lblConnectedToGPS.isHidden = false
        self.headerView.imgIcon.isHidden = false
        self.headerView.downloadView.isHidden = false
        self.tableView.tableHeaderView = self.headerView
        self.searchForNewLogs(shouldDownloadFiles: false)
        
        // Add tap gesture recognizers to the views
        let headerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.headerViewTapped(_:)))
        let downloadTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.searchForNewLogsAndDownload))

        self.headerView.downloadView.addGestureRecognizer(downloadTapRecognizer)
        self.headerView.statusView.addGestureRecognizer(headerTapRecognizer)
        
    }
    
    fileprivate func registerCells() {
        self.tableView.register(VGLogsTableViewCell.nib, forCellReuseIdentifier: VGLogsTableViewCell.identifier)
        self.tableView.register(VGLogHeaderView.nib, forHeaderFooterViewReuseIdentifier: VGLogHeaderView.identifier)
    }
    
    func addObservers() {
        addObserver(selector: #selector(onVehicleAddedToLog(_:)), name: .vehicleAddedToTrack)
        addObserver(selector: #selector(onLogsAdded(_:)), name: .logsAdded)
        addObserver(selector: #selector(onLogUpdated(_:)), name: .logUpdated)
    }
    
    func addObserver(selector: Selector, name: Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    func initializeTableViewController() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        title = Strings.Titles.vgpsDevice
        self.toolbarButtonShare = UIBarButtonItem(title: Strings.share, style: .plain, target: self, action: #selector(exportTracks(_:)))
        self.toolbarButtonDelete = UIBarButtonItem(title: Strings.delete, style: .plain, target: self, action: #selector(deleteTracks(_:)))
        tabBarItem = UITabBarItem(title: Strings.Titles.vgps,
                                  image: Icons.device,
                                  tag: 0)
    }
    
    fileprivate func initializeClasses() {
        self.dataStore = appDelegate.dataStore
        self.vgFileManager = appDelegate.fileManager
    }
    
    fileprivate func configureEmptyListLabel() {
        emptyLabel = VGListEmptyLabel(text: Strings.noLogs,
                                      containerView: self.tableView,
                                      navigationBar: navigationController!.navigationBar,
                                      tabBar: appDelegate.tabController.tabBar)
        view.addSubview(emptyLabel)
    }
    
    fileprivate func configureNavigationBar() {
        self.navigationItem.leftBarButtonItem = editButtonItem
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
    }
    
    fileprivate func configureToolbar() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarButtonDelete.tintColor = .red
        setToolbarItems([toolbarButtonShare, space, toolbarButtonDelete], animated: false)
        
    }
    
    // MARK: - Other
    func showEditToolbar() {
        navigationController?.setToolbarHidden(false, animated: true)

    }
    
    func hideEditToolbar() {
        navigationController?.setToolbarHidden(true, animated: true)

    }
    
    @objc func searchForNewLogsAndDownload() {
        searchForNewLogs(shouldDownloadFiles: true)
    }
    
    func searchForNewLogs(shouldDownloadFiles: Bool) {
        self.headerView.searchingForLogs()
        DispatchQueue.global(qos: .utility).async {
            self.appDelegate.deviceCommunicator.getAvailableFiles(onSuccess: { (filesOnDevice) in
                self.undownloadedFiles.removeAll()
                self.filesOnDevice = filesOnDevice
                self.dataStore.getDownloadedFiles(onSuccess: { (downloadedFiles) in
                    self.downloadedFiles = downloadedFiles
                    for deviceFile in filesOnDevice {
                        var fileFoundOnPhone = false
                        for downFile in downloadedFiles where downFile.name == deviceFile.filename {
                            fileFoundOnPhone = true
                            if Int(downFile.size) != Int(truncating: deviceFile.fileSize!) {
                                self.undownloadedFiles.append(deviceFile)
                            }
                            continue
                        }
                        if !fileFoundOnPhone {
                            self.undownloadedFiles.append(deviceFile)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.headerView.newLogsAvailable(count: self.undownloadedFiles.count)
                        if shouldDownloadFiles {
                            self.downloadFiles()
                        }
                    }
                    
                    let recordingFileNames = self.getRecordingFile()
                    for recordingFileName in recordingFileNames {
                        guard let recordingIndexPath = self.getIndexPath(for: recordingFileName.filename) else {
                            continue
                        }
                        self.tracksDictionary[self.sections[recordingIndexPath.section]]![recordingIndexPath.row].isRecording = true
                        
                        DispatchQueue.main.async {
                            guard let cell = self.tableView.cellForRow(at: recordingIndexPath) as? VGLogsTableViewCell else {
                                return
                            }
                            cell.animateRecording()
                        }
                    }

                }, onFailure: { (error) in
                    self.appDelegate.display(error: error)
                })
            }, onFailure: { (error) in
                self.appDelegate.display(error: error)
            })
        }
    }
    
    func getRecordingFile() -> [NMSFTPFile] {
        var files = [NMSFTPFile]()
        for deviceFile in self.filesOnDevice {
            for downFile in self.downloadedFiles {
                if downFile.name == deviceFile.filename &&
                    Int(downFile.size) != Int(truncating: deviceFile.fileSize!) {
                    files.append(deviceFile)
                }
            }
        }
        return files
    }
    
    func getIndexPath(for track: VGTrack) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            guard let sectionList = tracksDictionary[section] else {
                continue
            }
            for (rowIndex, trk) in sectionList.enumerated() where track.id == trk.id {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
    
    func getIndexPath(for fileName: String) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            guard let sectionList = tracksDictionary[section] else {
                continue
            }
            for (rowIndex, trk) in sectionList.enumerated() where fileName == trk.fileName {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
    
    func combineLists(localList: [VGTrack], remoteList: [VGTrack]) -> [VGTrack] {
        var result = localList

        for track in remoteList {
            if !(result.contains(track)) {
                result.append(track)
            }
        }
        return result
    }
    
    // MARK: - Interface Action Functions
    @objc func headerViewTapped(_:Any?) {
        let dlViewController = VGDownloadLogsViewController()
        self.dataStore.getAllTracks(
            onSuccess: { (tracks) in
                dlViewController.tracks = tracks
                self.navigationController?.pushViewController(dlViewController, animated: true)
            },
            onFailure: { (error) in
                self.appDelegate.display(error: error)
            }
        )

    }
            
    func displayErrorAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    // MARK: - List Manipulation
    func updateData() {
        self.dataStore.getAllTracks(
            onSuccess: { (tracks) in
                (self.sections, self.tracksDictionary) = LogDateSplitter.splitLogsByDate(trackList: tracks)
                self.tableView.reloadData()
                if self.tracksDictionary.count > 0 {
                    self.emptyLabel.isHidden = true
                    self.tableView.separatorStyle = .singleLine
                } else {
                    self.emptyLabel.isHidden = false
                    self.tableView.separatorStyle = .none
                }
            },
            onFailure: { (error) in
                self.appDelegate.display(error: error)
            }
        )
    }
    
    func getTrackAt(indexPath: IndexPath) -> VGTrack? {
        guard let dayFileList = tracksDictionary[sections[indexPath.section]] else {
            return nil
        }
        let file = dayFileList[indexPath.row]
        return file
    }
    
    func getViewForHeader(section: Int, view: VGLogHeaderView?) -> VGLogHeaderView {
        var hdrView = view
        
        if hdrView == nil {
            hdrView = tableView.dequeueReusableHeaderFooterView(withIdentifier: VGLogHeaderView.identifier) as? VGLogHeaderView
        }
        
        guard let view = hdrView else {
            return VGLogHeaderView()
        }
        
        let day = sections[section]
        view.dateLabel.text = " "
        view.detailsLabel.text = " "

        let dateString = headerDateFormatter.sectionKeyToDateString(sectionKey: day)
        var totalDuration = 0.0
        var totalDistance = 0.0
        var distanceString = ""
        var durationString = ""
        guard let trackSection = tracksDictionary[day] else {
            return VGLogHeaderView()
        }
        for track in trackSection {
            totalDuration += track.duration
            totalDistance += track.distance
        }
        distanceString = (totalDistance*1000).asDistanceString()
        
        let formattedDuration = totalDuration.asDurationString()
        durationString = formattedDuration
        
        view.dateLabel.text = dateString
        view.detailsLabel.text = distanceString + " - " + durationString
        
        var frame1 = view.dateLabel.frame
        frame1.size.height = dateString.height(withConstrainedWidth: view.bounds.width-40, font: view.dateLabel.font)
        view.dateLabel.frame = frame1
        
        var frame2 = view.detailsLabel.frame
        frame2.origin.y = frame1.size.height+2+2
        frame2.size.height = durationString.height(withConstrainedWidth: view.bounds.width-40, font: view.detailsLabel.font)
        view.detailsLabel.frame = frame2
        
        return view
    }

    // MARK: - Table View Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tracksForSection = tracksDictionary[sections[section]] else {
            return 0
        }
        return tracksForSection.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return getViewForHeader(section: section, view: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VGLogsTableViewCell.identifier,
            for: indexPath
            ) as? VGLogsTableViewCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        if let track = getTrackAt(indexPath: indexPath) {
            cell.show(track: track)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let track = getTrackAt(indexPath: indexPath) else {
            return
        }
        
//        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//            appDelegate.trackDetailsViewController.track = track
//            return
//        }
        
        if tableView.isEditing {
            guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
                return
            }
            
            if selectedIndexPaths.count == 0 {
                self.hideEditToolbar()
            } else {
                self.showEditToolbar()
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let logDetailsView = PulleyEditorViewController()
            logDetailsView.dataStore = self.dataStore
            logDetailsView.track = track
            self.navigationController?.pushViewController(logDetailsView, animated: true)
        }
        
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if getTrackAt(indexPath: indexPath) == nil {
            return
        }

        if tableView.isEditing {
            if tableView.indexPathsForSelectedRows == nil {
                self.hideEditToolbar()
                return
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return Strings.delete
    }

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let track = getTrackAt(indexPath: indexPath)
        
        let delete = UIAction(title: Strings.delete, image: Icons.delete, identifier: .none, discoverabilityTitle: nil, attributes: .destructive, state: .off) {_ in
            self.deleteTrack(at: indexPath)
        }
        
        let exportOriginal = UIAction(title: Strings.shareCSV, image: Icons.share, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            let activityVC = UIActivityViewController(activityItems: [self.vgFileManager!.getAbsoluteFilePathFor(track: track!)!], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
        
        let exportGPX = UIAction(title: Strings.shareGPX, image: Icons.share, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataStore.getDataPointsForTrack(with: track!.id!, onSuccess: { (dataPoints) in
                    track!.trackPoints = dataPoints
                    let fileUrl = self.vgGPXGenerator.generateGPXFor(tracks: [track!])!
                    let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                    DispatchQueue.main.async {
                        self.present(activityVC, animated: true, completion: nil)
                    }
                }, onFailure: { (error) in
                    self.appDelegate.display(error: error)
                })
            }
        }
        
        let selectVehicle = UIAction(title: Strings.selectVehicle, image: Icons.vehicle, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            guard let cell = tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            self.didTapVehicle(track: track!, tappedView: cell.btnVehicle)
        }
        
        let selectTags = UIAction(title: Strings.selectTags, image: Icons.tag, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            guard let cell = tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            self.didTapVehicle(track: track!, tappedView: cell.btnVehicle)
        }
        
        let exportMenu = UIMenu(title: Strings.share, image: Icons.share, identifier: .none, options: .init(), children: [exportGPX, exportOriginal])
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: [selectTags, selectVehicle, exportMenu, delete])
        }
    }
    
    func deleteTrack(at indexPath: IndexPath) {
        // Delete the row from the data source
        guard let track = self.getTrackAt(indexPath: indexPath) else {
            return
        }
        
        self.tracksDictionary[self.sections[indexPath.section]]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)

        if self.tracksDictionary[self.sections[indexPath.section]]?.count == 0 {
            self.tracksDictionary.removeValue(forKey: self.sections[indexPath.section])
            self.sections.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        }
        self.vgFileManager?.deleteFile(for: track)
        if self.tracksDictionary.count > 0 {
            self.emptyLabel.isHidden = true
            self.tableView.separatorStyle = .singleLine
        } else {
            self.emptyLabel.isHidden = false
            self.tableView.separatorStyle = .none
        }

        self.dataStore.delete(trackWith: track.id!, onSuccess: {
            
        }, onFailure: { (error) in
            self.appDelegate.display(error: error)
        })
    }
}

// MARK: - Extensions
extension VGLogsTableViewController: DisplaySelectVehicleProtocol {
    func didTapVehicle(track: VGTrack, tappedView: UIView?) {
        if tableView.isEditing {
            return
        }
        let selectionVC = VGVehiclesSelectionTableViewController(style: .insetGrouped)
        selectionVC.track = track
        
        let navController = UINavigationController(rootViewController: selectionVC)
        navController.modalPresentationStyle = .popover
        navController.preferredContentSize = CGSize(width: 414, height: 600)
        
        let popover: UIPopoverPresentationController = navController.popoverPresentationController!
        popover.sourceView = tappedView

        present(navController, animated: true, completion: nil)
    }
}
