//
//  VGHistoryNavigationController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGHistoryNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let historyController = VGHistoryTableViewController.init(style: .insetGrouped)
        historyController.view.backgroundColor = .systemBackground
        self.navigationBar.prefersLargeTitles = true
        self.pushViewController(historyController, animated: false)
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
