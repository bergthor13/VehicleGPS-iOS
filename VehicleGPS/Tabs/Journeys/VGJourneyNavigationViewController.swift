//
//  VGJourneyNavigationController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 11/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGJourneyNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let journeyController = VGJourneyTableViewController.init(style: .insetGrouped)
        self.navigationBar.prefersLargeTitles = true
        self.pushViewController(journeyController, animated: false)
        // Do any additional setup after loading the view.

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
