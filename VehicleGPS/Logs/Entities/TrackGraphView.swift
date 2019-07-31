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
	var graphClipLayer: CAShapeLayer!
    
    var color:UIColor?
    var maxValue:Double?
    var minValue:Double?
    var showMinMaxValue:Bool = true

	private var elePoints = [CGFloat]()


	public var numbersList = [Double]() {
		didSet {
			let pixelWidth = self.bounds.width*UIScreen.main.scale
			let pointsPerPixel = CGFloat(numbersList.count) / pixelWidth

			elePoints = []
			var averageAltitude: CGFloat = 0.0
			var pointInPixel = 0
			for (index, coordinate) in numbersList.enumerated() {
				averageAltitude += CGFloat(coordinate)
				pointInPixel += 1

				let modulo = floor(CGFloat(index).truncatingRemainder(dividingBy: pointsPerPixel))
				if modulo == 0 {
					elePoints.append(averageAltitude/CGFloat(pointInPixel))
					averageAltitude = 0.0
					pointInPixel = 0
				}
			}
            setNeedsLayout()
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let pixelWidth = self.bounds.width*UIScreen.main.scale
		let pointsPerPixel = CGFloat(numbersList.count) / pixelWidth

		elePoints = []
		var averageAltitude: CGFloat = 0.0
		var pointInPixel = 0
		for (index, coordinate) in numbersList.enumerated() {
			averageAltitude += CGFloat(coordinate)
			pointInPixel += 1

			let modulo = floor(CGFloat(index).truncatingRemainder(dividingBy: pointsPerPixel))
			if modulo == 0 {
				elePoints.append(averageAltitude/CGFloat(pointInPixel))
				averageAltitude = 0.0
				pointInPixel = 0
			}
		}

		drawGraph()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
    
    

	public func drawGraph() {
		//calculate the x point
		UIGraphicsBeginImageContext(self.bounds.size)

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
		
		let columnXPoint = { (column:Double) -> CGFloat in
			//Calculate gap between points

			let spacer = (self.bounds.width) / CGFloat(self.elePoints.count - 1)
			let x: CGFloat = CGFloat(column) * spacer
			return x
		}

		// calculate the y point
		let graphHeight = self.bounds.height
		let maxValue = elePoints.max()
		let minValue = elePoints.min()

		let columnYPoint = { (graphPoint:Double) -> CGFloat in

			var y: CGFloat = (CGFloat(graphPoint) - minValue!) * CGFloat(graphHeight) / CGFloat(maxValue! - minValue!)
			y = graphHeight - y

			return y
		}

		// draw the line graph
		//set up the points line
		let graphPath = UIBezierPath()
		//go to start of line

		graphLayer = CAShapeLayer()
		graphLayer.strokeColor = UIColor.black.cgColor
		graphLayer.fillColor = UIColor.clear.cgColor
		graphLayer.lineWidth = 0.5
		layer.addSublayer(graphLayer)



		graphPath.move(to: CGPoint(x:columnXPoint(0),
		                           y:columnYPoint(Double(elePoints[0]))))



		//add points for each item in the graphPoints array
		//at the correct (x, y) for the point
		for i in 1 ..< elePoints.count {
			let nextPoint = CGPoint(x:columnXPoint(Double(i)),
			                        y:columnYPoint(Double(elePoints[i])))
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
		clippingPath.addLine(to: CGPoint(
			x: columnXPoint(Double(elePoints.count - 1)),
			y:self.bounds.height))
		clippingPath.addLine(to: CGPoint(
			x:columnXPoint(0),
			y:self.bounds.height))
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
        
		let rectPath = UIBezierPath(rect: self.bounds)
		rectPath.fill()
		graphClipLayer.path = clippingPath.cgPath

		//end temporary code
		layer.addSublayer(graphClipLayer)


		//end temporary code
		UIGraphicsEndImageContext()
	}

}
