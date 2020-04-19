import UIKit
import CoreData
import MBProgressHUD

class VGImportFileTableViewController: UITableViewController {
    
    var fileUrl:URL?
    var dataStore = VGDataStore()
    var importedTracks = [VGTrack]()
    var importBarButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.titles.importFile
        tableView.register(VGImportTableViewCell.nib, forCellReuseIdentifier: VGImportTableViewCell.identifier)
        importBarButton = UIBarButtonItem(title: Strings.importFile, style: .done, target: self, action: #selector(tappedImport))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(tappedCancel))
        
        let asdf = VGGPXParser()
        guard let fileUrl = fileUrl else {
            return
        }
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.rightBarButtonItem = barButton
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .utility).async {
            asdf.fileToTracks(fileUrl: fileUrl, progress: { (curr, count) in
            }, callback: { (parsedTracks) in
                self.importedTracks = parsedTracks
                DispatchQueue.main.async {
                    activityIndicator.stopAnimating()
                    self.navigationItem.rightBarButtonItem = self.importBarButton
                    self.tableView.reloadData()
                }
            }) { (track, style) in
                  
            }
        }
    }
    
    init(style: UITableView.Style, fileUrl:URL) {
        super.init(style:style)
        self.fileUrl = fileUrl
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
        hud.progress = finishedTracks/Float(self.importedTracks.count)
        for track in self.importedTracks {
            self.dataStore.add(
                vgTrack: track,
                onSuccess: { (id) in
                    finishedTracks += 1
                    hud.progress = finishedTracks/Float(self.importedTracks.count)
                    if Int(finishedTracks) == self.importedTracks.count {
                        hud.hide(animated: true)
                    }
                    track.id = id
                },
                onFailure:  { (error) in
                    print(error)
                }
            )
        }
        dismiss(animated: true)
    }
    
    @objc func tappedCancel() {
        dismiss(animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return importedTracks.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGImportTableViewCell.identifier, for: indexPath) as? VGImportTableViewCell else {
            return VGImportTableViewCell(style: .default, reuseIdentifier: VGImportTableViewCell.identifier)
        }
        
        cell.show(track: self.importedTracks[indexPath.row])

        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return String(fileUrl!.lastPathComponent)
        }
        
        return nil
    }
}
