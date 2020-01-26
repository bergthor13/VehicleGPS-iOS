//
//  VGListEmptyLabel.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 26/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGListEmptyLabel: UILabel {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var navigationBar: UINavigationBar!
    var tabBar: UITabBar!
    var containerView: UIView!
    
    init(text:String, containerView:UIView, navigationBar:UINavigationBar, tabBar:UITabBar) {
        self.navigationBar = navigationBar
        self.tabBar = tabBar
        self.containerView = containerView
        
        let height = containerView.frame.height - navigationBar.frame.height - tabBar.frame.height
        let width = containerView.frame.width
        let newFrame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        
        super.init(frame: newFrame)
        self.text = text
        self.configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configure()
    }
    
    func configure() {
        self.textAlignment = .center
        self.font = UIFont.systemFont(ofSize: 20)
        self.textColor = .secondaryLabel
    }
}
