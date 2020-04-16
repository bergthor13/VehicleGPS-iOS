import UIKit

class VGVehicleDetailsTableViewController: VGHistoryDetailsTableViewController {
    var vehicle:VGVehicle?
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
}
