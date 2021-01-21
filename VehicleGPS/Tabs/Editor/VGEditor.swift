//
//  VGEditorViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 2.12.2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import Pulley

class VGEditor {
    var mapViewController:VGEditorMapViewController!
    var trackViewController:VGEditorTrackViewController!
    var pulleyController:PulleyViewController!
    
    var tracks = [VGTrack]() {
        didSet {
            mapViewController.tracks = self.tracks
            trackViewController.tracks = self.tracks
        }
    }
    
    init(parentViewController:UIViewController) {
        mapViewController = UIStoryboard(name: "Editor", bundle: Bundle.main).instantiateViewController(withIdentifier: "VGEditorMapViewController") as? VGEditorMapViewController
        trackViewController = UIStoryboard(name: "Editor", bundle: Bundle.main).instantiateViewController(withIdentifier: "VGEditorTrackViewController") as? VGEditorTrackViewController
        pulleyController = PulleyViewController(contentViewController: mapViewController, drawerViewController: trackViewController)
        pulleyController.pulleyViewController?.delegate = self
        pulleyController.displayMode = .drawer
        pulleyController.backgroundDimmingOpacity = 0
        pulleyController.initialDrawerPosition = .partiallyRevealed
        pulleyController.modalPresentationStyle = .fullScreen
        parentViewController.present(pulleyController, animated: true)

    }
    
}

extension VGEditor: PulleyDrawerViewControllerDelegate {
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 364.0 + (pulleyController.currentDisplayMode == .drawer ? bottomSafeArea : 0.0)
    }
}
