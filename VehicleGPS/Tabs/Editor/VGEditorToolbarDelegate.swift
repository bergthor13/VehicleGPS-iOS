//
//  VGEditorToolbarDelegate.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 29.1.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import Foundation

protocol VGEditorToolbarDelegate {
    func didTap(button: ButtonType)
}

enum ButtonType {
    case next
    case previous
    case split
}
