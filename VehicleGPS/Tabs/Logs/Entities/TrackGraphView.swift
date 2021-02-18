import Foundation
import UIKit
import CoreLocation

public class TrackGraphView: UIView {
    private var graphLayer: CAShapeLayer!
    private var lineLayer: CAShapeLayer!
    private var graphClipLayer: CAShapeLayer!
    private var graphSelectLayer: CAShapeLayer!
    private var graphSelectPath: UIBezierPath!
    
    private var  graphFrame: UIView!

    private var maxValue: CGFloat = CGFloat(-Double.infinity)
    private var minValue: CGFloat = CGFloat(Double.infinity)
    
    private var graphSeparatorRight: UIView?
    private var graphSeparatorLeft: UIView?
    
    private var scrollView:UIScrollView!
    private var pinchRecognizer: UIPinchGestureRecognizer!
    
    private var maxLabel: UILabel?
    private var minLabel: UILabel?
        
    var selectedPoint: CGPoint?
    var dlpList: [DisplayLineProtocol]?
    
    var configuration = TrackGraphViewConfig() {
        didSet {
            elePoints = []
            guard let endTime = configuration.endTime else {return}
            guard let startTime = configuration.startTime else {return}
            self.maxValue = CGFloat(-Double.infinity)
            self.minValue = CGFloat(Double.infinity)
            let pixelWidth = self.graphFrame.bounds.width*UIScreen.main.scale
            let totalSeconds = endTime.timeIntervalSince(startTime)
            let secondsPerPixel = totalSeconds/Double(pixelWidth)
            if configuration.numbersList.count == 0 {
                setNeedsLayout()
                return
            }
            
            var totalAltitude: CGFloat = 0.0
            var lastPixel = configuration.numbersList.first!.0
            var pointCount = 0
            for item in configuration.numbersList {
                if item.1 == Double.infinity {
                    continue
                }
                if elePoints.count == 0 {
                    if !item.1.isNaN {
                        elePoints.append((item.0, CGFloat(item.1)))
                        lastPixel = item.0
                    }
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
                    if !currValue.isNaN {
                        elePoints.append((item.0, currValue))
                    }
                    
                    pointCount = 0
                    totalAltitude = 0.0
                    lastPixel = item.0
                }
            }
            
            if elePoints.count == 1 && configuration.numbersList.count > 1 {
                let elePointsElement = elePoints.first!
                let numbersListElement = configuration.numbersList.last!
                elePoints.append((numbersListElement.0, CGFloat(numbersListElement.1)))
                maxValue = CGFloat(max(Double(elePointsElement.1), Double(numbersListElement.1)))
                minValue = CGFloat(min(Double(numbersListElement.1), Double(elePointsElement.1)))
            }

            if configuration.showMinMaxValue {
                guard let newMax = configuration.graphMaxValue else {
                    setNeedsLayout()
                    return
                }
                
                guard let newMin = configuration.graphMinValue else {
                    setNeedsLayout()
                    return
                }
                
                self.maxValue = CGFloat(newMax)
                self.minValue = CGFloat(newMin)
            }
            setNeedsLayout()
        }
    }
    
    func addDLP(listener:DisplayLineProtocol) {
        if dlpList == nil {
            dlpList = [DisplayLineProtocol]()
        }
        dlpList?.append(listener)
    }
    
    public func removeAllDLPListeners() {
        dlpList?.removeAll()
        dlpList = nil
    }
    
    private var elePoints = [(Date, CGFloat)]()
    
    
    public func displayVerticalLine(at point: CGPoint) {
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
    
    public func displayHorizontalLine(at list: [Double]) {
        // TODO: Move this!
        let topLine = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.graphFrame.frame.width, height: 0.5)))
        let bottomLine = UIView(frame: CGRect(origin: CGPoint(x: 0, y: self.graphFrame.frame.height), size: CGSize(width: self.graphFrame.frame.width, height: 0.5)))

        if elePoints.count == 0 {
            return
        }
        for view in self.graphFrame.subviews {
            if view.tag == 300 {
                view.removeFromSuperview()
            }
        }
        

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
            let yPoint = getColumnYPoint(graphPoint: CGFloat(value))
            
            if yPoint < 0 {
                continue
            }
            
            if yPoint.isNaN {
                continue
            }
            
            let line = UIView(frame: CGRect(origin: CGPoint(x: 0, y: yPoint), size: CGSize(width: self.graphFrame.frame.width, height: 0.5)))
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
    public func getPointTouched(point: CGPoint) -> Int {
        let id = Int(round((point.x/self.graphFrame.bounds.width)*CGFloat(elePoints.count)))
        return id
    }
    
    public func getTimeOfTouched(point:CGPoint) -> Date? {
        guard let startTime = configuration.startTime else {return nil}
        guard let endTime = configuration.endTime else {return nil}
        
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        clearGraph()
        displayHorizontalLine(at: configuration.horizontalLineMarkers)
        if elePoints.count == 0 {
            return
        }
        self.scrollView.frame =  CGRect(x: self.bounds.origin.x+configuration.inset.left, y: self.bounds.origin.y+configuration.inset.top, width: self.bounds.width-configuration.inset.left-configuration.inset.right, height: self.bounds.height-configuration.inset.top-configuration.inset.bottom)
        self.graphFrame.frame = CGRect(x: 0, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height)
        self.scrollView.contentSize = self.graphFrame.frame.size
        drawGraph()
        self.graphSeparatorRight?.frame = CGRect(origin: CGPoint(x: self.scrollView.frame.width+self.scrollView.frame.origin.x, y: 0), size: CGSize(width: 0.25, height: self.bounds.height))
        self.graphSeparatorLeft?.frame = CGRect(origin: CGPoint(x: self.scrollView.frame.origin.x, y: 0), size: CGSize(width: 0.25, height: self.bounds.height))

        if traitCollection.userInterfaceStyle == .light {
            self.graphSeparatorRight?.backgroundColor = .lightGray
            self.graphSeparatorLeft?.backgroundColor = .lightGray
        } else {
            self.graphSeparatorRight?.backgroundColor = .darkGray
            self.graphSeparatorLeft?.backgroundColor = .darkGray
        }
        
        self.maxLabel!.text = String(format: "%.2f", self.maxValue)
        self.minLabel?.text = String(format: "%.2f", self.minValue)
        self.maxLabel?.frame = CGRect(x: configuration.inset.left+self.scrollView.frame.width+5, y: 5, width: 200, height: 15)
        self.minLabel?.frame = CGRect(x: configuration.inset.left+self.scrollView.frame.width+5, y: self.bounds.height-20, width: 200, height: 15)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }
    
    var oldDelta: CGFloat = 0.0
    var oldFinger1: CGFloat = 0.0
    var oldFinger2: CGFloat = 0.0
    var oldLocation: CGFloat = 0.0
    
    @objc private func didPinch(_ sender:UIPinchGestureRecognizer) {
        if sender.numberOfTouches != 2 {
            return
        }
        let finger1 = sender.location(ofTouch: 0, in: scrollView)
        let finger2 = sender.location(ofTouch: 1, in: scrollView)
        let deltaX:CGFloat = abs(finger1.x - finger2.x)
        
        if sender.state == .began {
            oldDelta = deltaX
            oldFinger1 = sender.location(in: nil).x
            oldFinger2 = finger2.x
            return
        }
        
        oldLocation = (scrollView?.contentOffset.x)!/(scrollView?.contentSize.width)!
        scrollView.contentSize.width += (deltaX-oldDelta)*(1-(1/scrollView.contentSize.width))
        
        graphFrame.frame.size = scrollView.contentSize
        drawGraph()
        var offset = scrollView?.contentOffset
        offset?.x = oldLocation*(scrollView?.contentSize.width)!-(sender.location(in: nil).x-oldFinger1)
        if (scrollView?.contentSize.width)!-(offset?.x)! < (scrollView?.contentSize.width)! {
            offset?.x = (scrollView?.contentSize.width)!-(scrollView?.frame.width)!
        }
        scrollView?.setContentOffset(offset!, animated: false)
        oldDelta = deltaX
        oldFinger1 = sender.location(in: nil).x
        oldFinger2 = finger2.x

    }
    
    public func initializeView() {
        graphLayer = CAShapeLayer()
        self.scrollView = UIScrollView(frame: CGRect(x: self.bounds.origin.x+configuration.inset.left, y: self.bounds.origin.y+configuration.inset.top, width: self.bounds.width-configuration.inset.left-configuration.inset.right, height: self.bounds.height-configuration.inset.top-configuration.inset.bottom))
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        self.pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch))
        self.pinchRecognizer.delegate = self
        scrollView.addGestureRecognizer(pinchRecognizer)
        scrollView.maximumZoomScale = 3.0
        self.graphFrame = UIView(frame: CGRect(x: 0, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height))
        self.scrollView.contentSize = graphFrame.frame.size
        self.addSubview(scrollView)
        scrollView.addSubview(graphFrame)
        self.isMultipleTouchEnabled = true
        self.maxLabel = UILabel(frame: CGRect(x: self.bounds.width-205, y: 5, width: 200, height: 15))
        self.maxLabel?.font = UIFont.systemFont(ofSize: 12)
        self.maxLabel?.textAlignment = .left
        self.maxLabel?.textColor = UIColor.gray
        self.minLabel = UILabel(frame: CGRect(x: self.bounds.width-205, y: self.bounds.height-20, width: 200, height: 15))
        self.minLabel?.font = UIFont.systemFont(ofSize: 12)
        self.minLabel?.textAlignment = .left
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
        longPressGesture.minimumPressDuration = TimeInterval(0.3)
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
        guard let selectedPoint = selectedPoint else {
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
            if let dlpList = dlpList {
                for dlp in dlpList {
                    dlp.didTouchGraph(at: drawnPoint)
                }
            }
            
        case .ended, .failed, .cancelled:
            break
        default:
            break
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    public func getColumnYPoint(graphPoint: CGFloat) -> CGFloat {
        if self.maxValue == self.minValue {
            if CGFloat(graphPoint) > self.maxValue {
                return self.graphFrame.frame.height
            }
            
            if CGFloat(graphPoint) < self.maxValue {
                return 0
            }
            return self.graphFrame.frame.height/2
        }
        
        var y: CGFloat = (CGFloat(graphPoint) - self.minValue) * CGFloat(self.graphFrame.frame.height) / CGFloat(self.maxValue - self.minValue)
        
        y = self.graphFrame.frame.height - y
        
        return y
    }
    
    public func clearGraph() {
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
        self.maxLabel?.text = ""
        self.minLabel?.text = ""
    }
    
    public func drawGraph() {
        clearGraph()
        guard let endTime = configuration.endTime else {return}
        guard let startTime = configuration.startTime else {return}
        if elePoints.count == 0 { return }
        UIGraphicsBeginImageContext(self.graphFrame.frame.size)

        let graphHeight = self.graphFrame.frame.height
        let graphWidth = self.graphFrame.frame.width

        let columnYPoint = { (graphPoint: Double) -> CGFloat in
            
            if self.maxValue == self.minValue {
                if CGFloat(graphPoint) > self.maxValue {
                    return self.graphFrame.frame.height
                }
                
                if CGFloat(graphPoint) < self.maxValue {
                    return 0
                }
                return self.graphFrame.frame.height/2
            }
            
            var y: CGFloat = (CGFloat(graphPoint) - self.minValue) * CGFloat(graphHeight) / CGFloat(self.maxValue - self.minValue)
            y = graphHeight - y
            
            if y.isNaN  || y.isInfinite {
                return 0
            }
            
            return y
        }
        
        let graphPath = UIBezierPath()
        
        graphLayer.strokeColor = configuration.color.withAlphaComponent(0.8).cgColor
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
        
        
        graphClipLayer.fillColor = configuration.color.cgColor
        
        
        let rectPath = UIBezierPath(rect: self.graphFrame.frame)
        rectPath.fill()
        graphClipLayer.path = clippingPath.cgPath
        
        //end temporary code
        self.graphFrame.layer.addSublayer(graphClipLayer)
        
        //end temporary code
        UIGraphicsEndImageContext()
    }
}

extension TrackGraphView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.graphFrame
    }
    
    
}

extension TrackGraphView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
