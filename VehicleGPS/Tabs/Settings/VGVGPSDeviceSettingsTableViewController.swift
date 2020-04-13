import UIKit

class VGVGPSDeviceSettingsTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.titles.vgpsDevice
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Host"
        } else if section == 1 {
            return "Username"
        } else if section == 2 {
            return "Password"
        } else {
            return nil
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        let textField = UITextField(frame: CGRect(x: 20, y: 0, width: cell.frame.width-40, height: cell.frame.height))
        textField.autocapitalizationType = .none

        if indexPath.section == 0 {
            cell = UITableViewCell()
            textField.text = "cargps.local"
            cell.addSubview(textField)
            
        } else if indexPath.section == 1 {
            cell = UITableViewCell()
            textField.text = "pi"
            cell.addSubview(textField)

        } else if indexPath.section == 2 {
            cell = UITableViewCell()
            textField.textContentType = .password
            textField.isSecureTextEntry = true
            textField.text = "easyprintsequence"
            cell.addSubview(textField)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
