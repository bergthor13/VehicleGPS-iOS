//
//  LogHeaderView.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 30/07/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGLogHeaderView: UITableViewHeaderFooterView {
    var blurViewTag = 4009

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initializeBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeBackground()
    }
    
    func initializeBackground() {
        let blurEffect = UIBlurEffect(style: .prominent)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = blurViewTag
        
        self.insertSubview(blurEffectView, at: 0)

    }
}
