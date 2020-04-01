//
//  ColorPickerTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 17/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGColorPickerTableViewController: UITableViewController {
    let colors:[String: UIColor] = [
        NSLocalizedString("Rauður", comment: ""):.red,
        NSLocalizedString("Grænn", comment: ""):.green,
        NSLocalizedString("Svartur", comment: ""):.black,
        NSLocalizedString("Blár", comment: ""):.blue,
        NSLocalizedString("Brúnn", comment: ""):.brown,
        NSLocalizedString("Dökkgrár", comment: ""):.darkGray,
        NSLocalizedString("Hvítur", comment: ""):.white,
        NSLocalizedString("Appelsínugulur", comment: ""):.orange]
    var delegate: ColorPickerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(VGColorTableViewCell.nib, forCellReuseIdentifier: VGColorTableViewCell.identifier)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Hætta við", comment: ""), style: .plain, target: self, action: #selector(didTapCancel))
        title = NSLocalizedString("Velja lit", comment: "")
    }
    
    @objc func didTapCancel() {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let delegate = delegate else {
            dismiss(animated: true)
            return
        }
        
        delegate.didPick(color: colors[Array(colors.keys)[indexPath.row]]!)
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "colorCell", for: indexPath) as? VGColorTableViewCell else {
            return UITableViewCell()
        }
        cell.lblColorTitle.text = Array(colors.keys)[indexPath.row]
        cell.colorView.backgroundColor = colors[Array(colors.keys)[indexPath.row]]
        cell.colorView.layer.cornerRadius = cell.colorView.bounds.height/2

        return cell
    }
}
