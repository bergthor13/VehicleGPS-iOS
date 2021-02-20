//
//  VGTagsTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 2.2.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGTagsTableViewController: UITableViewController {

    var track: VGTrack?
    var tags = [VGTag]()
    var emptyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        self.tableView.register(VGAddTagTableViewCell.nib, forCellReuseIdentifier: VGAddTagTableViewCell.identifier)
        title = Strings.titles.tags
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        VGDataStore().getTags { (tags) in
            self.tags = tags
            for tag in self.tags {
                if self.track!.tags.contains(tag) {
                    tag.tracks!.append(self.track!)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        } onFailure: { (error) in
            self.appDelegate.display(error: error)
        }
        
        tableView.isEditing = true

    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count+1
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Merki hjálpa þér að flokka ferla saman. Til dæmis er hægt að nota merki til að sameina ferðalög."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGAddTagTableViewCell.identifier, for: indexPath) as? VGAddTagTableViewCell else {
            return UITableViewCell()
        }
        
        
        cell.txtName.delegate = self
        
        if indexPath.row == tags.count {
            return cell
        }
        let cellTag = tags[indexPath.row]
        cell.txtName.isEnabled = false
        cell.txtName.text = cellTag.name
        
        guard let track = track else {
            return cell
        }
        
        
        let tagInTrack = track.tags.contains { (tag) -> Bool in
            return tag.id == cellTag.id
        }
        
        if tagInTrack {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tag = tags[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: false)
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        if tag.tracks!.contains(track!) {
            VGDataStore().remove(tagWith: tag.id!, fromTrackWith: track!.id!) {
                cell.accessoryType = .none
                tag.tracks!.remove(at: tag.tracks!.firstIndex(of: self.track!)!)
            } onFailure: { (error) in
                self.appDelegate.display(error: error)
            }

        } else {
            VGDataStore().add(tagWith: tag.id!, toTrackWith: track!.id!) {
                cell.accessoryType = .checkmark
                tag.tracks!.append(self.track!)
            } onFailure: { (error) in
                self.appDelegate.display(error: error)
            }
        }
        


    }
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row == tags.count {
            return .insert
        }
        
        return .delete
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? VGAddTagTableViewCell else {
            return
        }
        
        if editingStyle == .insert {
            if indexPath.row == tags.count {
                addTag(at: indexPath)
                cell.txtName.text = ""
            }
        } else if editingStyle == .delete {
            deleteTag(at: indexPath)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        for cell in tableView.visibleCells as! [VGAddTagTableViewCell] {
            if editing {
                cell.txtName.isEnabled = true
            } else {
                cell.txtName.isEnabled = false
                if tableView.indexPath(for: cell)?.row == tags.count {
                    cell.txtName.isEnabled = true
                }
                
            }
        }
    }
    
    func deleteTag(at indexPath:IndexPath) {
        guard let id = tags[indexPath.row].id else {
            return
        }
        VGDataStore().delete(tagWith: id) {
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tags.remove(at: indexPath.row)
            self.tableView.endUpdates()
        } onFailure: { (error) in
            self.appDelegate.display(error: error)
        }

    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == tags.count {
            return false
        }
        return true
    }

    
//    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//
//    }
    
    func addTag(at indexPath:IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? VGAddTagTableViewCell {
            if cell.txtName.text != "" {
                let tag = VGTag()
                tag.name = cell.txtName.text
                VGDataStore().add(tag: tag) {id in
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                    tag.id = id
                    self.tags.append(tag)
                    self.tableView.endUpdates()
                } onFailure: { (error) in
                    self.appDelegate.display(error: error)
                }

            }
        }

    }
}

extension VGTagsTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let cell = textField.superview?.superview as? UITableViewCell else {
            return false
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            return false
        }

        if indexPath.row == tags.count {
            addTag(at: indexPath)
            textField.text = ""
        } else {
            
        }
        
        return true
    }
    
}
