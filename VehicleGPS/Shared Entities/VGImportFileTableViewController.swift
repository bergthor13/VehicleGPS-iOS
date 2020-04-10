import UIKit

class VGImportFileTableViewController: UITableViewController {
    
    var fileUrl:URL?
    var dataStore = VGDataStore()
    var importedTracks = [VGTrack]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.titles.importFile
        tableView.register(VGLogsTableViewCell.nib, forCellReuseIdentifier: VGLogsTableViewCell.identifier)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.importFile, style: .done, target: self, action: #selector(tappedImport))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(tappedCancel))
        
        let asdf = VGGPXParser()
        guard let fileUrl = fileUrl else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            asdf.fileToTracks(fileUrl: fileUrl, progress: { (curr, count) in
                  
            }, callback: { (parsedTracks) in
                self.importedTracks = parsedTracks
                DispatchQueue.main.async {
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
        for track in importedTracks {
            self.dataStore.add(
                vgTrack: track,
                onSuccess: { (id) in
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return importedTracks.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGLogsTableViewCell.identifier, for: indexPath) as? VGLogsTableViewCell else {
            return VGLogsTableViewCell(style: .default, reuseIdentifier: VGLogsTableViewCell.identifier)
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
