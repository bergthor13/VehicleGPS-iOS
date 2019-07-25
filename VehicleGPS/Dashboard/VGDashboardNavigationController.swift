//
//  VGDashboardNavigationController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGDashboardNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let dashController = DashboardViewController.init()
        dashController.view.backgroundColor = .white
        self.pushViewController(dashController, animated: false)

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
