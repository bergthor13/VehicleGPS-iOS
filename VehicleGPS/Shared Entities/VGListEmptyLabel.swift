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
    
    func setFrame() {
        let height = containerView.frame.height - navigationBar.frame.height - tabBar.frame.height
        let width = containerView.frame.width
        let newFrame = CGRect(x: 16.0, y: 0.0, width: width-32, height: height)
        self.frame = newFrame

    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configure()
    }
    @objc func preferredContentSizeChanged(_ notification: Notification) {
        setFrame()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            let scaledFont = UIFont.systemFont(ofSize: 20)
            let fontMetrics = UIFontMetrics(forTextStyle: .body)
            self.font = fontMetrics.scaledFont(for: scaledFont)
        }
    }

    
    func configure() {
        self.textAlignment = .center
        let scaledFont = UIFont.systemFont(ofSize: 20)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        self.font = fontMetrics.scaledFont(for: scaledFont)
        self.textColor = .secondaryLabel
    }
}
