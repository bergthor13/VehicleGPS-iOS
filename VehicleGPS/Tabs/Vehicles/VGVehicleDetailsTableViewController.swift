import UIKit

class VGVehicleDetailsTableViewController: UITableViewController {
    var vehicle:VGVehicle?
    var dataStore = VGDataStore()
    override func viewDidLoad() {
        super.viewDidLoad()
        if let vehicle = vehicle {
            title = vehicle.name
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onVehicleUpdated(_:)), name: .vehicleUpdated, object: nil)
        
        self.tableView.register(VGLogsTableViewCell.nib, forCellReuseIdentifier: VGLogsTableViewCell.identifier)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))
    }
    
    @objc func onVehicleUpdated(_ notification:Notification) {
        guard let updatedVehicle = notification.object as? VGVehicle else {
            return
        }
        vehicle = updatedVehicle
        title = updatedVehicle.name
    }
    
    @objc func didTapEdit() {
        let editVehicleVC = VGEditVehicleTableViewController(style: .grouped)
        editVehicleVC.vehicle = vehicle!
        present(UINavigationController(rootViewController: editVehicleVC), animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tracks = vehicle?.tracks else {
            return 0
        }
        return tracks.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = vehicle!.tracks![indexPath.row]
        let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
        logDetailsView.dataStore = self.dataStore
        logDetailsView.track = track
        self.navigationController?.pushViewController(logDetailsView, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VGLogsTableViewCell.identifier,
            for: indexPath
            ) as? VGLogsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.show(track:vehicle!.tracks![indexPath.row])
        return cell
    }
}
