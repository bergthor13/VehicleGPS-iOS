//
//  DashboardViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import SocketIO

class DashboardViewController: UIViewController {
    var lblSpeed: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Mælaborð"
        lblSpeed = UILabel(frame: self.view.frame)
        lblSpeed.text = "0.0"
        lblSpeed.textAlignment = .center
        self.view.addSubview(lblSpeed)
        
        let manager = SocketManager(socketURL: URL(string: "http://localhost:8080")!, config: [.log(true)])
        let socket = manager.defaultSocket

        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }

        socket.on("speedUpdated") {data, ack in
            guard let cur = data[0] as? Double else { return }
            self.lblSpeed.text = String(cur)
        }

        socket.connect()
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
