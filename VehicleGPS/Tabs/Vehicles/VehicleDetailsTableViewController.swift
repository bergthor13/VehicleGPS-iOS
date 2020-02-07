import UIKit

class VehicleDetailsTableViewController: UITableViewController {
    var vehicle:VGVehicle?
    var dataStore = VGDataStore()
    override func viewDidLoad() {
        super.viewDidLoad()
        if let vehicle = vehicle {
            title = vehicle.name
        }
        
        let logsTableViewCellNib = UINib(nibName: "LogsTableViewCell", bundle: nil)
        self.tableView.register(logsTableViewCellNib, forCellReuseIdentifier: "LogsCell")

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit))
    }
    
    @objc func didTapEdit() {
        let editVehicleVC = EditVehicleTableViewController(style: .grouped)
        editVehicleVC.vehicle = vehicle
        present(UINavigationController(rootViewController: editVehicleVC), animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vehicle!.tracks!.count
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
            withIdentifier: "LogsCell",
            for: indexPath
            ) as? LogsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.show(track:vehicle!.tracks![indexPath.row])
        return cell
    }
}
