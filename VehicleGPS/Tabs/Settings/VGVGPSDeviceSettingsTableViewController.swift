import UIKit

class VGVGPSDeviceSettingsTableViewController: UITableViewController {
    let dataStore = VGDataStore()
    var txtHost: UITextField!
    var txtUsername: UITextField!
    var txtPassword: UITextField!
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
            txtHost = textField
            textField.text = dataStore.getHost()
            cell.addSubview(textField)
            
        } else if indexPath.section == 1 {
            cell = UITableViewCell()
            txtUsername = textField
            textField.text = dataStore.getUsername()
            cell.addSubview(textField)

        } else if indexPath.section == 2 {
            cell = UITableViewCell()
            txtPassword = textField
            textField.textContentType = .password
            textField.isSecureTextEntry = true
            textField.text = Constants.sftp.password
            cell.addSubview(textField)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataStore.setHost(host: txtHost.text!)
        dataStore.setUsername(username: txtUsername.text!)
    }
}
