import UIKit
import CoreData
import MBProgressHUD

class VGImportFileTableViewController: UITableViewController {
    
    var fileUrls = [URL]()
    var dataStore = VGDataStore()
    var importedTracks = [[VGTrack]]()
    var importBarButton = UIBarButtonItem()
    var vgFileManager = VGFileManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.titles.importFile
        tableView.register(VGImportTableViewCell.nib, forCellReuseIdentifier: VGImportTableViewCell.identifier)
        importBarButton = UIBarButtonItem(title: Strings.importFile, style: .done, target: self, action: #selector(tappedImport))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(tappedCancel))
        
        if fileUrls.count == 0 {
            return
        }
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.rightBarButtonItem = barButton
        activityIndicator.startAnimating()
        
        for _ in self.fileUrls {
            self.importedTracks.append([VGTrack]())
        }
        
        DispatchQueue.global(qos: .utility).async {
            for (index, fileUrl) in self.fileUrls.enumerated() {
                let parser = self.vgFileManager.getParser(for: fileUrl)
                
                if let parser = parser as? VGGPXParser {
                    parser.fileToTracks(fileUrl: fileUrl, progress: { (curr, count) in
                    }, callback: { (parsedTracks) in
                        self.importedTracks[index] = parsedTracks
                        DispatchQueue.main.async {
                            activityIndicator.stopAnimating()
                            self.navigationItem.rightBarButtonItem = self.importBarButton
                            self.tableView.reloadData()
                        }
                    }) { (track, style) in
                        
                    }
                } else {
                    parser?.fileToTrack(fileUrl: fileUrl, progress: { (curr, count) in
                        
                    }, onSuccess: { (parsedTrack) in
                        self.importedTracks[0] = [parsedTrack]
                        DispatchQueue.main.async {
                            activityIndicator.stopAnimating()
                            self.navigationItem.rightBarButtonItem = self.importBarButton
                            self.tableView.reloadData()
                        }

                    }, onFailure: { (error) in
                        print(error)
                    })
                }
                

            }
        }
    }
    
    init(style: UITableView.Style, fileUrls:[URL]) {
        super.init(style:style)
        self.fileUrls = fileUrls
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tappedImport() {
        var finishedTracks = Float(0.0)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        
        let hud = MBProgressHUD.showAdded(to: appDelegate.window!, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "Adding Logs..."
        var totalTracks = 0
        for file in importedTracks {
            totalTracks += file.count
        }
        hud.progress = finishedTracks/Float(totalTracks)
        for file in self.importedTracks {
            for track in file {
                self.dataStore.add(
                    vgTrack: track,
                    onSuccess: { (id) in
                        finishedTracks += 1
                        hud.progress = finishedTracks/Float(totalTracks)
                        if Int(finishedTracks) == totalTracks {
                            hud.hide(animated: true)
                        }
                        track.id = id
                    },
                    onFailure:  { (error) in
                        print(error)
                    }
                )
            }
        }
        dismiss(animated: true)
    }
    
    @objc func tappedCancel() {
        dismiss(animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fileUrls.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return importedTracks[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGImportTableViewCell.identifier, for: indexPath) as? VGImportTableViewCell else {
            return VGImportTableViewCell(style: .default, reuseIdentifier: VGImportTableViewCell.identifier)
        }
        
        cell.show(track: self.importedTracks[indexPath.section][indexPath.row])

        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(fileUrls[section].lastPathComponent)
    }
}
