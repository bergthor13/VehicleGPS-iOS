import UIKit
import NMSSH
import CoreData

class VGLogsTableViewController: UITableViewController {
    
    // MARK: Variables
    var tracksDictionary = [String: [VGTrack]]()
    var sections = [String]()

    // MARK: Classes
    var vgFileManager: VGFileManager?
    var vgLogParser: IVGLogParser?
    var dataStore:VGDataStore!
    let vgGPXGenerator = VGGPXGenerator()
    
    // MARK: Views
    var headerView: VGDeviceConnectedHeaderView!
    var emptyLabel: UILabel!
    
    // MARK: Formatters
    let distanceFormatter = VGDistanceFormatter()
    let durationFormatter = VGDurationFormatter()
    let headerDateFormatter = VGHeaderDateFormatter()
    let dateParsingFormatter = VGDateParsingFormatter()
    
    // MARK: - Initializers
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
        title = Strings.titles.logs
        tabBarItem = UITabBarItem(title: Strings.titles.logs,
                                  image: Icons.log,
                                  tag: 0)
    }
    
    // MARK: - View Did Load Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeClasses()
        configureEmptyListLabel()
        configureNavigationBar()
        configureRefreshControl()
        //setUpDeviceConnectedBanner()
        registerCells()
        //startConnectionToVGPS()
        updateData()
        tableView.allowsMultipleSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(onVehicleAddedToLog(_:)), name: .vehicleAddedToTrack , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLogsAdded(_:)), name: .logsAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(previewImageStarting(_:)), name: .previewImageStartingUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(previewImageStopping(_:)), name: .previewImageFinishingUpdate, object: nil)

        
    }
    
    @objc func previewImageStarting(_ notification:Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        DispatchQueue.main.async {
            guard let indexPath = self.getIndexPath(for: newTrack) else {
                return
            }
            guard let cell = self.tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
                return
            }
            let track = self.getTrackAt(indexPath: indexPath)
            track?.beingProcessed = true
            cell.activityView.startAnimating()
        }

    }
    
    @objc func previewImageStopping(_ notification:Notification) {
        guard let updatedNotification = notification.object as? ImageUpdatedNotification else {
            return
        }
        DispatchQueue.main.async {
            if self.traitCollection.userInterfaceStyle == updatedNotification.style {
                guard let indexPath = self.getIndexPath(for: updatedNotification.track) else {
                    return
                }
                guard let cell = self.tableView.cellForRow(at: self.getIndexPath(for: updatedNotification.track)!) as? VGLogsTableViewCell else {
                    return
                }
                let track = self.getTrackAt(indexPath: indexPath)
                track?.beingProcessed = false
                cell.activityView.stopAnimating()
                cell.trackView.image = updatedNotification.image
            }
        }


    }
    
    @objc func onVehicleAddedToLog(_ notification:Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        guard let indexPath = getIndexPath(for: newTrack) else {
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? VGLogsTableViewCell else {
            return
        }
        getTrackAt(indexPath: indexPath)?.vehicle = newTrack.vehicle
        cell.lblVehicle.text = newTrack.vehicle!.name
        
    }
    
    func getIndexPath(for track:VGTrack) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            for (rowIndex, trk) in tracksDictionary[section]!.enumerated() {
                if track.id == trk.id {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }
    
    
    @objc func onLogsAdded(_ notification:Notification) {
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
            self.tracksDictionary = self.tracksToDictionary(trackList: self.combineLists(localList: list, remoteList: newTracks))

            self.tableView.reloadData()
        }
        
        
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
    
    fileprivate func initializeClasses() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
            self.vgFileManager = appDelegate.fileManager
        }
    }
    
    fileprivate func configureEmptyListLabel() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            emptyLabel = VGListEmptyLabel(text: Strings.noLogs,
                                          containerView: self.view,
                                          navigationBar: navigationController!.navigationBar,
                                          tabBar: delegate.tabController.tabBar)
        }

        view.addSubview(emptyLabel)
    }
    
    fileprivate func configureNavigationBar() {
        //let button1 = UIBarButtonItem(title: Strings.parse, style: .plain, target: self, action: #selector(self.processFiles))
        //self.navigationItem.leftBarButtonItem = button1
        self.navigationItem.leftBarButtonItem = editButtonItem
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
    }
    
    fileprivate func configureRefreshControl() {
        // TODO: Reconnect RefreshControl
        // Add Refresh Control to Table View
        //let refreshControl = UIRefreshControl()
        //refreshControl.addTarget(self, action: #selector(fetchLogList), for: UIControl.Event.valueChanged)
        //tableView.refreshControl = refreshControl
    }
    
    fileprivate func setUpDeviceConnectedBanner() {
        self.headerView = VGDeviceConnectedHeaderView.loadFromNibNamed(nibNamed: VGDeviceConnectedHeaderView.nibName)
        self.headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0)
        self.tableView.tableHeaderView = self.headerView
        self.headerView.lblLogsAvailable.isHidden = true
        self.headerView.lblConnectedToGPS.isHidden = true
        self.headerView.imgIcon.isHidden = true
        self.headerView.greenButton.isHidden = true
        
        // Add tap gesture recognizers to the views
        let headerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.headerViewTapped(_:)))
        //let downloadTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.downloadFiles))

        self.headerView.greenBackground.addGestureRecognizer(headerTapRecognizer)
        //self.headerView.greenButton.addGestureRecognizer(downloadTapRecognizer)
    }
    
    fileprivate func registerCells() {
        self.tableView.register(VGLogsTableViewCell.nib, forCellReuseIdentifier: VGLogsTableViewCell.identifier)
        self.tableView.register(VGLogHeaderView.nib, forHeaderFooterViewReuseIdentifier: VGLogHeaderView.identifier)
    }

    // MARK: - Interface Action Functions
    @objc func headerViewTapped(_:Any?) {
        let dlViewController = VGDownloadLogsViewController()
        dlViewController.tracks = self.dataStore.getAllTracks()
        navigationController?.pushViewController(dlViewController, animated: true)
    }
            
    func displayErrorAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    //MARK: - List Manipulation
    func updateData() {
        self.tracksDictionary = self.tracksToDictionary(trackList: self.dataStore.getAllTracks())
        tableView.reloadData()
        if self.tracksDictionary.count > 0 {
            self.emptyLabel.isHidden = true
            self.tableView.separatorStyle = .singleLine
        } else {
            self.emptyLabel.isHidden = false
            self.tableView.separatorStyle = .none
        }
    }
    
    func tracksToDictionary(trackList:[VGTrack]) -> Dictionary<String, [VGTrack]>{
        var result = Dictionary<String, [VGTrack]>()
        for track in trackList {
            var day = ""
            
            if let timeStart = track.timeStart {
                day = dateParsingFormatter.string(from: timeStart)
            }
            
            if result[day] == nil {
                result[day] = [VGTrack]()
            }
            
            if !sections.contains(day) {
                sections.append(day)
            }
            result[day]!.append(track)
        }
        
        // Reorder the sections and lists to display the newest log first.
        self.sections = self.sections.sorted().reversed()
        for (day, list) in result {
            result[day] = list.sorted()
        }
        
        return result
    }
    
    func getTrackAt(indexPath:IndexPath) -> VGTrack? {
        guard let dayFileList = tracksDictionary[sections[indexPath.section]] else {
            return nil
        }
        let file = dayFileList[indexPath.row]
        return file
    }
    
    func getViewForHeader(section:Int, view:VGLogHeaderView?) -> VGLogHeaderView {
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
        distanceString = distanceFormatter.string(fromMeters: totalDistance*1000)
        
        let formattedDuration = durationFormatter.string(from: totalDuration)
        durationString = String(formattedDuration!)
        
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
        return getViewForHeader(section: section, view:nil)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VGLogsTableViewCell.identifier,
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
        guard let track = getTrackAt(indexPath: indexPath) else {
            return
        }
        
        if track.trackPoints.count == 0 {
            track.trackPoints = dataStore.getPointsForTrack(vgTrack: track)
        }
        
        if track.trackPoints.count > 0 {
            let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
            logDetailsView.dataStore = self.dataStore
            logDetailsView.track = track
            self.navigationController?.pushViewController(logDetailsView, animated: true)
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    

    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return Strings.delete
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteTrack(at: indexPath)
        }
    }
    func deleteTrack(at indexPath:IndexPath) {
        // Delete the row from the data source
        guard let track = self.getTrackAt(indexPath: indexPath) else {
            return
        }
        
        self.tracksDictionary[self.sections[indexPath.section]]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)

        if self.tracksDictionary[self.sections[indexPath.section]]?.count == 0 {
            self.sections.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        }
        self.vgFileManager?.deleteFileFor(track: track)
        self.dataStore.delete(vgTrack: track)
    }
    
    override func tableView(_ tableView: UITableView,
      contextMenuConfigurationForRowAt indexPath: IndexPath,
      point: CGPoint) -> UIContextMenuConfiguration? {
        
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
                track!.trackPoints = self.dataStore.getPointsForTrack(vgTrack: track!)
                let fileUrl = self.vgGPXGenerator.generateGPXFor(track: track!)!
                let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                DispatchQueue.main.async {
                    self.present(activityVC, animated: true, completion: nil)
                }
            }
            
        }
        
        let selectVehicle = UIAction(title: Strings.selectVehicle, image: Icons.vehicle, identifier: .none, discoverabilityTitle: nil, attributes: .init(), state: .off) {_ in
            let cell = tableView.cellForRow(at: indexPath) as! VGLogsTableViewCell
            self.didTapVehicle(track: track!, tappedView: cell.btnVehicle)
        }

        let exportMenu = UIMenu(title: Strings.share, image: Icons.share, identifier: .none, options: .init(), children: [exportGPX, exportOriginal])

      return UIContextMenuConfiguration(identifier: nil,
        previewProvider: nil) { _ in
        UIMenu(title: "", children: [selectVehicle, exportMenu, delete])
      }
    }
}

extension VGLogsTableViewController: DisplaySelectVehicleProtocol {
    func didTapVehicle(track: VGTrack, tappedView:UIView?) {
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
