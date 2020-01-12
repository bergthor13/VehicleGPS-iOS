//
//  TrackGraphView.swift
//  Track Cutter
//
//  Created by Bergþór on 10.4.2017.
//  Copyright © 2017 Bergþór Þrastarson. All rights reserved.
//

import UIKit

import CoreLocation

class TrackGraphView: UIView {
    
    var graphLayer: CAShapeLayer!
    var lineLayer: CAShapeLayer!
    var graphClipLayer: CAShapeLayer!
    var graphSelectLayer: CAShapeLayer!
    var graphSelectPath: UIBezierPath!
    
    var tableView: UITableView?
    
    var color: UIColor?
    var maxValue: CGFloat = CGFloat(-Double.infinity)
    var minValue: CGFloat = CGFloat(Double.infinity)
    var graphMaxValue: Double?
    var graphMinValue: CGFloat?
    var graphSeparatorRight: UIView?
    var graphSeparatorLeft: UIView?
    
    var graphFrame: UIView!
    
    var maxLabel: UILabel?
    var minLabel: UILabel?
    var startTime: Date?
    var endTime: Date?
    var showMinMaxValue: Bool = true
    var inset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 60)

    var selectedPoint: CGPoint?
    var dlpList = [DisplayLineProtocol]()
    
    var horizontalLineMarkers = [Double]() {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var elePoints = [(Date, CGFloat)]()
    
    public var numbersList = [(Date, Double)]() {
        didSet {
            elePoints = []
            guard let endTime = self.endTime else {return}
            guard let startTime = self.startTime else {return}
            self.maxValue = CGFloat(-Double.infinity)
            self.minValue = CGFloat(Double.infinity)
            let pixelWidth = self.graphFrame.bounds.width*UIScreen.main.scale
            let totalSeconds = endTime.timeIntervalSince(startTime)
            let secondsPerPixel = totalSeconds/Double(pixelWidth)
            if numbersList.count == 0 {
                setNeedsLayout()
                return
            }
            
            var totalAltitude: CGFloat = 0.0
            var lastPixel = numbersList.first!.0
            var pointCount = 0
            for item in numbersList {
                if item.1 == Double.infinity {
                    continue
                }
                pointCount += 1
                totalAltitude += CGFloat(item.1)
                if item.0.timeIntervalSince(lastPixel) > secondsPerPixel {
                    let currValue = totalAltitude/CGFloat(pointCount)
                    
                    if currValue < minValue {
                        minValue = currValue
                    }
                    
                    if currValue > maxValue {
                        maxValue = currValue
                    }
                    elePoints.append((item.0, currValue))
                    pointCount = 0
                    totalAltitude = 0.0
                    lastPixel = item.0
                }
            }
            
            if showMinMaxValue {
                guard let newMax = self.graphMaxValue else {
                    setNeedsLayout()
                    return
                }
                
                guard let newMin = self.graphMinValue else {
                    setNeedsLayout()
                    return
                }
                
                self.maxValue = CGFloat(newMax)
                self.minValue = CGFloat(newMin)
            }
            setNeedsLayout()
        }
    }
    
    func displayVerticalLine(at point: CGPoint) {
        graphSelectLayer.sublayers?.removeAll()
        graphSelectLayer.path = nil
        graphSelectLayer.strokeColor = UIColor.gray.cgColor
        graphSelectLayer.lineWidth = 0.5
        self.graphFrame.layer.addSublayer(graphSelectLayer)
        let topPoint = CGPoint(x: point.x, y: 0.0)
        let bottomPoint = CGPoint(x: point.x, y: self.graphFrame.bounds.height)
        graphSelectPath = UIBezierPath(rect: CGRect(x: topPoint.x, y: 0, width: 0.5, height: self.graphFrame.bounds.height))
        graphSelectPath.move(to: topPoint)
        graphSelectPath.addLine(to: bottomPoint)
        graphSelectLayer.path = graphSelectPath.cgPath
    }
    
    func displayHorizontalLine(at list: [Double]) {
        if elePoints.count == 0 {
            return
        }
        for view in self.graphFrame.subviews {
            if view.tag == 300 {
                view.removeFromSuperview()
            }
        }
        
        let topLine = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.graphFrame.frame.width, height: 0.5)))
        let bottomLine = UIView(frame: CGRect(origin: CGPoint(x: 0, y: self.graphFrame.frame.height), size: CGSize(width: self.graphFrame.frame.width, height: 0.5)))

        topLine.tag = 300
        bottomLine.tag = 300
        if traitCollection.userInterfaceStyle == .light {
             topLine.backgroundColor = .lightGray
             bottomLine.backgroundColor = .lightGray

         } else {
            topLine.backgroundColor = .darkGray
            bottomLine.backgroundColor = .darkGray

        }
        self.graphFrame.addSubview(topLine)
        self.graphFrame.addSubview(bottomLine)

        for value in list {
            if getColumnYPoint(graphPoint: CGFloat(value)) < 0 {
                continue
            }
            
            let line = UIView(frame: CGRect(origin: CGPoint(x: 0, y: getColumnYPoint(graphPoint: CGFloat(value))), size: CGSize(width: self.graphFrame.frame.width, height: 0.5)))
            line.tag = 300
            if traitCollection.userInterfaceStyle == .light {
                line.backgroundColor = .lightGray
                
            } else {
                line.backgroundColor = .darkGray
            }
            self.graphFrame.addSubview(line)
            
        }
        
    }
    
    // TODO: FIX ME
    func getPointTouched(point: CGPoint) -> Int {
        let id = Int(round((point.x/self.graphFrame.bounds.width)*CGFloat(elePoints.count)))
        return id
    }
    
    func getTimeOfTouched(point:CGPoint) -> Date? {
        guard let startTime = self.startTime else {return nil}
        guard let endTime = self.endTime else {return nil}
        
        let totalSeconds = endTime.timeIntervalSince(startTime)
        let positionPercentage = point.x / self.graphFrame.frame.width

        if positionPercentage > 1 {
            return endTime
        }
        if positionPercentage < 0 {
            return startTime
        }
        
        let calculatedDate = startTime.addingTimeInterval(totalSeconds*Double(positionPercentage))
        return calculatedDate
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if elePoints.count == 0 {
            return
        }
        displayHorizontalLine(at: horizontalLineMarkers)
        self.graphFrame.frame =  CGRect(x: self.bounds.origin.x+inset.left, y: self.bounds.origin.y+inset.top, width: self.bounds.width-inset.left-inset.right, height: self.bounds.height-inset.top-inset.bottom)
        drawGraph()
        self.graphSeparatorRight?.frame = CGRect(origin: CGPoint(x: self.graphFrame.frame.width+self.graphFrame.frame.origin.x, y: 0), size: CGSize(width: 0.25, height: self.bounds.height))
        self.graphSeparatorLeft?.frame = CGRect(origin: CGPoint(x: self.graphFrame.frame.origin.x, y: 0), size: CGSize(width: 0.25, height: self.bounds.height))

        if traitCollection.userInterfaceStyle == .light {
            self.graphSeparatorRight?.backgroundColor = .lightGray
            self.graphSeparatorLeft?.backgroundColor = .lightGray
        } else {
            self.graphSeparatorRight?.backgroundColor = .darkGray
            self.graphSeparatorLeft?.backgroundColor = .darkGray
        }
        
        self.maxLabel!.text = String(format: "%.2f", self.maxValue)
        self.minLabel?.text = String(format: "%.2f", self.minValue)
        self.maxLabel?.frame = CGRect(x: self.bounds.width-205, y: 5, width: 200, height: 15)
        self.minLabel?.frame = CGRect(x: self.bounds.width-205, y: self.bounds.height-20, width: 200, height: 15)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }
    
    func initializeView() {
        graphLayer = CAShapeLayer()

        self.graphFrame = UIView(frame: CGRect(x: self.bounds.origin.x+20, y: self.bounds.origin.y+10, width: self.bounds.width-60, height: self.bounds.height))
        self.addSubview(graphFrame)
        self.isMultipleTouchEnabled = true
        self.maxLabel = UILabel(frame: CGRect(x: self.bounds.width-205, y: 5, width: 200, height: 15))
        self.maxLabel?.font = UIFont.systemFont(ofSize: 12)
        self.maxLabel?.textAlignment = .right
        self.maxLabel?.textColor = UIColor.gray
        self.minLabel = UILabel(frame: CGRect(x: self.bounds.width-205, y: self.bounds.height-20, width: 200, height: 15))
        self.minLabel?.font = UIFont.systemFont(ofSize: 12)
        self.minLabel?.textAlignment = .right
        self.minLabel?.textColor = UIColor.gray
        graphSelectLayer = CAShapeLayer()
        graphSelectPath = UIBezierPath()
        self.graphSeparatorRight = UIView(frame: CGRect(origin: CGPoint(x: self.graphFrame.frame.width+self.graphFrame.frame.origin.x, y: 0), size: CGSize(width: 5, height: self.graphFrame.bounds.height)))
        self.graphSeparatorLeft = UIView(frame: CGRect(origin: CGPoint(x: self.graphFrame.frame.origin.x, y: 0), size: CGSize(width: 5, height: self.graphFrame.bounds.height)))
        self.addSubview(self.maxLabel!)
        self.addSubview(self.minLabel!)
        self.addSubview(self.graphSeparatorRight!)
        self.addSubview(self.graphSeparatorLeft!)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPressGesture.minimumPressDuration = TimeInterval(0.5)
        self.addGestureRecognizer(longPressGesture)
        
        if let selectedPoint = selectedPoint {
            displayVerticalLine(at: (selectedPoint))
        } else {
            graphSelectLayer.sublayers?.removeAll()
            graphSelectLayer.path = nil
        }
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        if sender.state == .began {
            selectionFeedbackGenerator.selectionChanged()
        }
        
        selectedPoint = sender.location(in: self.graphFrame)
        guard var selectedPoint = selectedPoint else {
            return
        }
        
        switch sender.state {
        case .began, .changed:
            var drawnPoint = selectedPoint

            if 0 <= selectedPoint.x && selectedPoint.x < self.graphFrame.bounds.width {
                drawnPoint = selectedPoint
                displayVerticalLine(at: selectedPoint)
            }
            
            if selectedPoint.x < 0.0 {
                drawnPoint = .zero
                displayVerticalLine(at: .zero)
            }
            
            if selectedPoint.x > self.graphFrame.bounds.width {
                drawnPoint = CGPoint(x: self.graphFrame.bounds.width, y: 0)
                displayVerticalLine(at: drawnPoint)
            }
            for dlp in dlpList {
                dlp.didTouchGraph(at: drawnPoint)
            }
            


        case .ended, .failed, .cancelled:
            break
        default:
            break
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    init(frame: CGRect, tableView: UITableView) {
        super.init(frame: frame)
        self.tableView = tableView
        initializeView()
    }
    
    func getColumnYPoint(graphPoint: CGFloat) -> CGFloat {
        var y: CGFloat = (CGFloat(graphPoint) - self.minValue) * CGFloat(self.graphFrame.frame.height) / CGFloat(self.maxValue - self.minValue)
        y = self.graphFrame.frame.height - y
        
        return y
    }
    
    fileprivate func clearGraph() {
        if graphLayer != nil {
            if graphLayer.superlayer != nil {
                self.graphLayer.removeFromSuperlayer()
            }
        }
        
        if graphClipLayer != nil {
            if graphClipLayer.superlayer != nil {
                self.graphClipLayer.removeFromSuperlayer()
            }
        }
    }
    
    public func drawGraph() {
        guard let endTime = self.endTime else {return}
        guard let startTime = self.startTime else {return}
        if elePoints.count == 0 { return }
        UIGraphicsBeginImageContext(self.graphFrame.bounds.size)
        
        clearGraph()

        let graphHeight = self.graphFrame.bounds.height
        let graphWidth = self.graphFrame.bounds.width

        let columnYPoint = { (graphPoint: Double) -> CGFloat in
            var y: CGFloat = (CGFloat(graphPoint) - self.minValue) * CGFloat(graphHeight) / CGFloat(self.maxValue - self.minValue)
            y = graphHeight - y
            return y
        }
        
        let graphPath = UIBezierPath()
        
        graphLayer.strokeColor = self.color?.withAlphaComponent(0.8).cgColor
        graphLayer.fillColor = UIColor.clear.cgColor
        graphLayer.lineWidth = 0.5
        
        self.graphFrame.layer.addSublayer(graphLayer)
        
        let totalSeconds = endTime.timeIntervalSince(startTime)
        let secondsFromStart = elePoints.first!.0.timeIntervalSince(startTime)
        
        //go to start of line
        graphPath.move(to: CGPoint(x: CGFloat(secondsFromStart/totalSeconds)*graphWidth,
                                   y: columnYPoint(Double(elePoints.first!.1))))
        
        //add points for each item in the graphPoints array
        //at the correct (x, y) for the point
        for i in 0 ..< elePoints.count {
            let secondsFromStart = elePoints[i].0.timeIntervalSince(startTime)
            let nextPoint = CGPoint(x: CGFloat(secondsFromStart/totalSeconds)*graphWidth,
                                    y: columnYPoint(Double(elePoints[i].1)))
            graphPath.addLine(to: nextPoint)
        }
        
        graphLayer.path = graphPath.cgPath
        
        // Create the clipping path for the graph gradient
        graphClipLayer = CAShapeLayer()
                
        // Make a copy of the path
        guard let clippingPath = graphPath.copy() as? UIBezierPath else {
            return
        }
        
        // Add lines to the copied path to complete the clip area
        let endFromStart = elePoints.last!.0.timeIntervalSince(startTime)
        
        clippingPath.addLine(to: CGPoint(
            x: CGFloat(endFromStart/totalSeconds)*graphWidth,
            y: self.graphFrame.bounds.height+graphFrame.bounds.origin.y))
        clippingPath.addLine(to: CGPoint(
            x: CGFloat(secondsFromStart/totalSeconds)*graphWidth,
            y: self.graphFrame.bounds.height+graphFrame.bounds.origin.y))
        clippingPath.close()
        
        // Add the clipping path to the context
        clippingPath.addClip()
        
        if self.color == nil {
            graphClipLayer.fillColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3).cgColor
        } else {
            graphClipLayer.fillColor = self.color?.cgColor
        }
        
        let rectPath = UIBezierPath(rect: self.graphFrame.frame)
        rectPath.fill()
        graphClipLayer.path = clippingPath.cgPath
        
        //end temporary code
        self.graphFrame.layer.addSublayer(graphClipLayer)
        
        //end temporary code
        UIGraphicsEndImageContext()
    }
}
