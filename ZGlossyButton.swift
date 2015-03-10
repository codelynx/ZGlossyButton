//
//  ZGlossyButton.swift
//  ZGlossyButton
//
//  Created by Kaz Yoshikawa on 2015/03/09.
//  Copyright (c) 2015 Kaz Yoshikawa. All rights reserved.
//

import UIKit

//
//	ZGlossyButton
//

@IBDesignable class ZGlossyButton : UIButton {

	@IBInspectable var buttonColor: UIColor = UIColor.orangeColor()
	@IBInspectable var gloss: Double = 1.0

#if !TARGET_INTERFACE_BUILDER
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
#endif

#if !TARGET_INTERFACE_BUILDER
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
#endif

	func roundRectBezierPath(# rect: CGRect, radius: CGFloat) -> UIBezierPath {
		var minY = CGRectGetMinY(rect)
		var maxY = CGRectGetMaxY(rect)
		var minX = CGRectGetMinX(rect)
		var maxX = CGRectGetMaxX(rect)

		var buttonPath = UIBezierPath()
		buttonPath.moveToPoint(CGPointMake(minX+radius, minY))
		buttonPath.addQuadCurveToPoint(CGPointMake(minX, minY+radius), controlPoint:CGPointMake(minX, minY))
		buttonPath.addLineToPoint(CGPointMake(minX, maxY-radius))
		buttonPath.addQuadCurveToPoint(CGPointMake(minX+radius, maxY), controlPoint:CGPointMake(minX, maxY))
		buttonPath.addLineToPoint(CGPointMake(maxX-radius, maxY))
		buttonPath.addQuadCurveToPoint(CGPointMake(maxX, maxY-radius), controlPoint:CGPointMake(maxX, maxY))
		buttonPath.addLineToPoint(CGPointMake(maxX, minY+radius))
		buttonPath.addQuadCurveToPoint(CGPointMake(maxX-radius, minY), controlPoint:CGPointMake(maxX, minY))
		buttonPath.closePath()
		return buttonPath
	}

	func HSBtoRGB(# hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
		let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
		var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		color.getRed(&r, green: &g, blue: &b, alpha: &a)
		return (red: r, green: g, blue: b)
	}

	override func drawRect(rect: CGRect) {
		let contextRef = UIGraphicsGetCurrentContext()
		CGContextSaveGState(contextRef)

		UIColor.clearColor().set()
		UIRectFill(self.bounds)
		
		let inset1: CGFloat = 1.5
		let inset2: CGFloat = 2.0
		let bounds1 = CGRectIntegral(self.bounds)
		let bounds2 = CGRectInset(bounds1, inset1, inset1)
		let bounds3 = CGRectInset(bounds2, inset2, inset2)
		let radius1: CGFloat = (bounds1.size.height * 0.25) + (inset1 + inset2)
		let radius2: CGFloat = radius1 - inset1
		let radius3: CGFloat = radius2 - inset2
		
		var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0

		buttonColor.getHue(&h, saturation: &s, brightness: &v, alpha: &a)

		let z: CGFloat = (v > 0.5 && self.highlighted) ? 0.2 : 0.0
		let v1: CGFloat = ((v > 0.5) ? v - 0.3 : v) - z;
		let v2: CGFloat = ((v > 0.5) ? v : v + 0.3) - z;
		let (r1: CGFloat, g1: CGFloat, b1: CGFloat) = HSBtoRGB(hue: h, saturation: s, brightness: v1)
		let (r2: CGFloat, g2: CGFloat, b2: CGFloat) = HSBtoRGB(hue: h, saturation: s, brightness: v2)

		// outer stroke
		CGContextSetRGBStrokeColor(contextRef, 0.5, 0.5, 0.5, 0.125)
		CGContextSetLineWidth(contextRef, 1.0)
		CGContextAddPath(contextRef, self.roundRectBezierPath(rect: bounds1, radius:radius1).CGPath)
		CGContextStrokePath(contextRef)

		// inner fill
		CGContextSetRGBFillColor(contextRef, r1, g1, b1, a);
		CGContextAddPath(contextRef, self.roundRectBezierPath(rect: bounds2, radius:radius2).CGPath)
		CGContextFillPath(contextRef);
		
		// garient fill button
		let glossiness = CGFloat(0.25 * (1.0 - min(max(self.gloss, 0.0), 1.0)) + 0.01)
		let numberOfComponents: UInt = 4

		let components: [CGFloat] = [
			r1, g1, b1, a,
			r1, g1, b1, a,
			r2, g2, b2, a,
			r2, g2, b2, a
		]
		let locationsN: [CGFloat] = [
			0.0,
			0.5 - glossiness,
			0.5 + glossiness,
			1.0
		]
		let locationsH: [CGFloat] = [
			1.0,
			0.5 + glossiness,
			0.5 - glossiness,
			0.0
		]
		let locations = self.highlighted ? locationsN : locationsH
		let colorSpaceRef: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
		let gradientRef: CGGradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, numberOfComponents)
		let startPt: CGPoint = CGRectGetMidXMinYPoint(bounds1)
		let endPt: CGPoint = CGRectGetMidXMaxYPoint(bounds2)

		CGContextAddPath(contextRef, self.roundRectBezierPath(rect: bounds3, radius:radius3).CGPath)
		CGContextClip(contextRef);
		CGContextDrawLinearGradient(contextRef, gradientRef, startPt, endPt, 0);

		CGContextRestoreGState(contextRef);
	}

	private func CGRectGetMidXMinYPoint(rect: CGRect) -> CGPoint {
		return CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect))
	}
	
	private func CGRectGetMidXMaxYPoint(rect: CGRect) -> CGPoint {
		return CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect))
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.contentMode = .Redraw
	}
	
	override func sizeThatFits(size: CGSize) -> CGSize {
		let baseSize = super.sizeThatFits(size)
		return CGSizeMake(baseSize.width + 32.0, baseSize.height + 8.0)
	}
	
	override func intrinsicContentSize() -> CGSize {
		let baseSize = super.intrinsicContentSize()
		return CGSizeMake(baseSize.width + 32.0, baseSize.height + 8.0)
	}

	override var highlighted : Bool {
		didSet {
			self.setNeedsDisplay()
		}
	}
}
