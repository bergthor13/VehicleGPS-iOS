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
    
    var color:UIColor?
    var maxValue:CGFloat = CGFloat(-Double.infinity)
    var minValue:CGFloat = CGFloat(Double.infinity)
    var graphMaxValue:Double?
    var graphMinValue:CGFloat?
    var graphSeparator: UIView?
    
    var graphFrame:CGRect!
    
    var maxLabel:UILabel?
    var minLabel:UILabel?
    var startTime:Date?
    var endTime:Date?
    var showMinMaxValue:Bool = true
    
    var selectedPoint: Set<UITouch>?
    var dlp: DisplayLineProtocol?

	private var elePoints = [(Date, CGFloat)]()

	public var numbersList = [(Date, Double)]() {
		didSet {
            elePoints = []
            self.maxValue = CGFloat(-Double.infinity)
            self.minValue = CGFloat(Double.infinity)
            let pixelWidth = self.graphFrame.width*UIScreen.main.scale
            let totalSeconds = self.endTime!.timeIntervalSince(self.startTime!)
            let secondsPerPixel = totalSeconds/Double(pixelWidth)
            if numbersList.count == 0 {
                setNeedsLayout()
                return
            }
            
			var totalAltitude: CGFloat = 0.0
            var lastPixel = numbersList.first!.0
            var pointCount = 0
            for item in numbersList {
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
                
                guard let newMin = self.graphMinValue else  {
                    setNeedsLayout()
                    return
                }

                self.maxValue = CGFloat(newMax)
                self.minValue = CGFloat(newMin)
            }
            setNeedsLayout()
		}
	}
    
    func displayVerticalLine(at point:CGPoint) {
        var thisPoint = point
        if point.x > self.graphFrame.width {
            thisPoint = CGPoint(x: self.graphFrame.width, y: point.y)
            displayVerticalLine(at: CGPoint(x: self.graphFrame.width, y: 0))

        }

        graphSelectLayer.sublayers?.removeAll()
        graphSelectLayer.path = nil
        graphSelectLayer.strokeColor = UIColor.gray.cgColor
        graphSelectLayer.lineWidth = 1
        layer.addSublayer(graphSelectLayer)
        let topPoint = CGPoint(x: thisPoint.x, y: 0.0)
        let bottomPoint = CGPoint(x: thisPoint.x, y: self.graphFrame.height)
        graphSelectPath = UIBezierPath(rect: CGRect(x: topPoint.x, y: 0, width: 0.5, height: self.graphFrame.height))
        graphSelectPath.move(to: topPoint)
        graphSelectPath.addLine(to: bottomPoint)
        graphSelectLayer.path = graphSelectPath.cgPath

    }
    
    func displayHorizontalLine(at list:[CGFloat]) {
        for view in self.subviews {
            if view.tag == 300 {
                view.removeFromSuperview()
            }
        }
        for value in list {
            if getColumnYPoint(graphPoint: value) < 0 {
                continue
            }
            
            let line = UIView(frame: CGRect(origin: CGPoint(x: 0, y: getColumnYPoint(graphPoint: value)), size: CGSize(width: self.graphFrame.width, height: 0.5)))
            line.tag = 300
            if traitCollection.userInterfaceStyle == .light {
                line.backgroundColor = .lightGray

            } else {
                line.backgroundColor = .darkGray
            }
            self.addSubview(line)
            
        }
        setNeedsLayout()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if tableView != nil {
            tableView?.isScrollEnabled = false
        }
        selectedPoint = touches
        displayVerticalLine(at: touches.first!.location(in: self))
        if let dlp = dlp {
            dlp.didTouchGraph(at: touches.first!.location(in: self))
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let i = getPointTouched(point: touches.first!.location(in: self))
        selectedPoint = touches
        if i < elePoints.count || i < 0 {
            self.maxLabel?.text = String(format: "%.2f", elePoints[i].1)
        }
        if touches.first!.location(in: self).x < self.graphFrame.width {
            displayVerticalLine(at: touches.first!.location(in: self))
        } else {
            displayVerticalLine(at: CGPoint(x: self.graphFrame.width, y: 0))
        }
        if let dlp = dlp {
            dlp.didTouchGraph(at: touches.first!.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //selectedPoint = nil
        if tableView != nil {
            tableView?.isScrollEnabled = true
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //selectedPoint = nil
    }
    
    // TODO: FIX ME
    func getPointTouched(point:CGPoint) -> Int {
        let id = Int(round((point.x/self.graphFrame.width)*CGFloat(elePoints.count)))
        return id
    }

	override func layoutSubviews() {
		super.layoutSubviews()
        self.graphFrame = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: self.bounds.width-60, height: self.bounds.height)
		drawGraph()
        self.graphSeparator?.frame = CGRect(origin: CGPoint(x: self.graphFrame.width, y: 0), size: CGSize(width: 0.25, height: self.graphFrame.height))
        if traitCollection.userInterfaceStyle == .light {
            self.graphSeparator?.backgroundColor = .lightGray

        } else {
            self.graphSeparator?.backgroundColor = .darkGray
        }
        
        self.maxLabel!.text = String(format: "%.2f", self.maxValue)
        self.minLabel?.text = String(format: "%.2f", self.minValue)
        self.maxLabel?.frame = CGRect(x: self.bounds.width-205, y: 5, width: 200, height: 15)
        self.minLabel?.frame = CGRect(x: self.bounds.width-205, y: self.graphFrame.height-20, width: 200, height: 15)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
        initializeView()
	}
    
    func initializeView() {
        self.graphFrame = self.bounds
        self.isMultipleTouchEnabled = true
        self.maxLabel = UILabel(frame: CGRect(x: self.bounds.width-205, y: 5, width: 200, height: 15))
        self.maxLabel?.font = UIFont.systemFont(ofSize: 12)
        self.maxLabel?.textAlignment = .right
        self.maxLabel?.textColor = UIColor.gray
        self.minLabel = UILabel(frame: CGRect(x: self.bounds.width-205, y: self.graphFrame.height-20, width: 200, height: 15))
        self.minLabel?.font = UIFont.systemFont(ofSize: 12)
        self.minLabel?.textAlignment = .right
        self.minLabel?.textColor = UIColor.gray
        graphSelectLayer = CAShapeLayer()
        graphSelectPath = UIBezierPath()
        self.graphSeparator = UIView(frame: CGRect(origin: CGPoint(x: self.graphFrame.width, y: 0), size: CGSize(width: 5, height: self.graphFrame.height)))
        self.addSubview(self.maxLabel!)
        self.addSubview(self.minLabel!)
        self.addSubview(self.graphSeparator!)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(tapGesture)
        if selectedPoint != nil {
            displayVerticalLine(at: (selectedPoint?.first!.location(in: self))!)
        } else {
            graphSelectLayer.sublayers?.removeAll()
            graphSelectLayer.path = nil
        }
        
    }
    
    @objc func doubleTapped() {
        print("DoubleTapped: \(String(describing: selectedPoint))")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    init(frame: CGRect, tableView:UITableView) {
        super.init(frame: frame)
        self.tableView = tableView
        initializeView()
    }
    
    func getColumnYPoint(graphPoint:CGFloat) -> CGFloat {
        var y: CGFloat = (CGFloat(graphPoint) - self.minValue) * CGFloat(self.graphFrame.height) / CGFloat(self.maxValue - self.minValue)
        y = self.graphFrame.height - y
        
        return y
    }
    
	public func drawGraph() {
		//calculate the x point
		UIGraphicsBeginImageContext(self.graphFrame.size)

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

		if elePoints.count == 0 {
			return
		}

		// calculate the y point
		let graphHeight = self.graphFrame.height

		let columnYPoint = { (graphPoint:Double) -> CGFloat in

			var y: CGFloat = (CGFloat(graphPoint) - self.minValue) * CGFloat(graphHeight) / CGFloat(self.maxValue - self.minValue)
			y = graphHeight - y

			return y
		}

		// draw the line graph
		//set up the points line
		let graphPath = UIBezierPath()
		//go to start of line

		graphLayer = CAShapeLayer()
        lineLayer = CAShapeLayer()
		graphLayer.strokeColor = self.color?.withAlphaComponent(0.5).cgColor
		graphLayer.fillColor = UIColor.clear.cgColor
		graphLayer.lineWidth = 0.75
		layer.addSublayer(graphLayer)
        let pixelWidth = self.graphFrame.width
        let totalSeconds = self.endTime!.timeIntervalSince(self.startTime!)
        let secondsFromStart = elePoints.first!.0.timeIntervalSince(self.startTime!)

		graphPath.move(to: CGPoint(x:CGFloat(secondsFromStart/totalSeconds)*pixelWidth,
                                   y:columnYPoint(Double(elePoints.first!.1))))

		//add points for each item in the graphPoints array
		//at the correct (x, y) for the point
		for i in 0 ..< elePoints.count {
            let secondsFromStart = elePoints[i].0.timeIntervalSince(self.startTime!)
			let nextPoint = CGPoint(x:CGFloat(secondsFromStart/totalSeconds)*pixelWidth,
			                        y:columnYPoint(Double(elePoints[i].1)))
			graphPath.addLine(to: nextPoint)
		}

		graphLayer.path = graphPath.cgPath


		//Create the clipping path for the graph gradient
		graphClipLayer = CAShapeLayer()

		//1 - save the state of the context (commented out for now)
		//CGContextSaveGState(context)

		//2 - make a copy of the path
		let clippingPath = graphPath.copy() as! UIBezierPath


		//3 - add lines to the copied path to complete the clip area
        let endFromStart = elePoints.last!.0.timeIntervalSince(self.startTime!)

        clippingPath.addLine(to: CGPoint(
			x: CGFloat(endFromStart/totalSeconds)*pixelWidth,
			y:self.graphFrame.height))
		clippingPath.addLine(to: CGPoint(
			x:CGFloat(secondsFromStart/totalSeconds)*pixelWidth,
			y:self.graphFrame.height))
		clippingPath.close()

		//4 - add the clipping path to the context
		clippingPath.addClip()

		//5 - check clipping path - temporary code
        if self.color == nil {
            graphClipLayer.fillColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3).cgColor
        }
        else {
            graphClipLayer.fillColor = self.color?.cgColor
        }
        
		let rectPath = UIBezierPath(rect: self.graphFrame)
		rectPath.fill()
		graphClipLayer.path = clippingPath.cgPath

		//end temporary code
		layer.addSublayer(graphClipLayer)


		//end temporary code
		UIGraphicsEndImageContext()
	}

}
