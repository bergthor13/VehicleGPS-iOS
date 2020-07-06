import UIKit

class VGVGPSDeviceSettingsTableViewController: UITableViewController {
    let dataStore = VGDataStore()
    var txtHost: UITextField!
    var txtUsername: UITextField!
    var txtPassword: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.titles.vgpsDevice
        tableView.allowsSelection = false
        
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
        let textField = UITextField()
        textField.autocapitalizationType = .none

        if indexPath.section == 0 {
            cell = UITableViewCell()
            txtHost = textField
            textField.text = dataStore.getHost()
            cell.contentView.addSubview(textField)
            
        } else if indexPath.section == 1 {
            cell = UITableViewCell()
            txtUsername = textField
            textField.text = dataStore.getUsername()
            cell.contentView.addSubview(textField)

        } else if indexPath.section == 2 {
            cell = UITableViewCell()
            txtPassword = textField
            textField.textContentType = .password
            textField.isSecureTextEntry = true
            textField.text = Constants.sftp.password
            cell.contentView.addSubview(textField)
        }
        textField.translatesAutoresizingMaskIntoConstraints = false

        let topConstraint = NSLayoutConstraint(item: textField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: textField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: textField, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1, constant: 20)
        let trailingConstraint = NSLayoutConstraint(item: textField, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataStore.setHost(host: txtHost.text!)
        dataStore.setUsername(username: txtUsername.text!)
    }
}
