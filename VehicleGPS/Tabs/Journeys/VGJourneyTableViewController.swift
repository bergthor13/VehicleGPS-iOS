//
//  VGJourneyTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 11/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGJourneyTableViewController: UITableViewController {
    var emptyLabel: UILabel!
    fileprivate func configureEmptyListLabel() {
        var height: CGFloat = 0.0
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            height = view.frame.height-(navigationController?.navigationBar.frame.height)!
            return
        }
        height = view.frame.height-(navigationController?.navigationBar.frame.height)!-delegate.tabController.tabBar.frame.height
        let frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: height)
        
        emptyLabel = UILabel(frame: frame)
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 20)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.text = NSLocalizedString("Engin ferðalög", comment: "")
        view.addSubview(emptyLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var height: CGFloat = 0.0
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            height = view.frame.height-(navigationController?.navigationBar.frame.height)!
            return
        }
        height = view.frame.height-(navigationController?.navigationBar.frame.height)!-delegate.tabController.tabBar.frame.height
        let frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: height)
        
        emptyLabel.frame = frame
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Ferðalög", comment: "Vehicles Title")

        configureEmptyListLabel()

        let button = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(self.didTapAddJourney))
        self.navigationItem.rightBarButtonItem = button
    }
    
    @objc func didTapAddJourney() {
        let newJourneyVC = NewJourneyTableViewController(style: .grouped)
        let newJourneyNavController = UINavigationController()
        newJourneyNavController.pushViewController(newJourneyVC, animated: false)
        self.present(newJourneyNavController, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
}
