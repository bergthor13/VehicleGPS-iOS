//
//  VGEditorToolbar.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 28.1.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGEditorToolbar: UIView {
    
    var delegate: VGEditorToolbarDelegate?

    @IBOutlet weak var background: UIVisualEffectView!
    @IBOutlet weak var nextButtonView: UIView!
    @IBOutlet weak var splitButtonView: UIView!
    @IBOutlet weak var prevButtonView: UIView!
    @IBOutlet weak var grabber: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.background.effect = UIBlurEffect(style: .regular)
        grabber.layer.cornerRadius = grabber.frame.height/2
        let splitButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapSplitButton))
        splitButtonView.addGestureRecognizer(splitButtonRecognizer)
        let nextButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapNextButton))
        nextButtonView.addGestureRecognizer(nextButtonRecognizer)
        let prevButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapPrevButton))
        prevButtonView.addGestureRecognizer(prevButtonRecognizer)

    }
    
    @objc func didTapSplitButton(_ sender:UIView?) {
        delegate?.didTap(button: .split)
        print("SPLITTING")
        
    }
    
    @objc func didTapNextButton(_ sender:UIView?) {
        delegate?.didTap(button: .next)
        print("Next!")
    }
    
    @objc func didTapPrevButton(_ sender:UIView?) {
        delegate?.didTap(button: .previous)
        print("Prev!")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

    }
}
