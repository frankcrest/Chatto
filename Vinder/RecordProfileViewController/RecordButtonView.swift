//
//  RecordButtonView.swift
//  Vinder
//
//  Created by Dayson Dong on 2019-06-20.
//  Copyright © 2019 Frank Chen. All rights reserved.
//

import UIKit

protocol VideoHandlerDelegate: AnyObject {
    func startRecording()
    func stopRecording()
}

class RecordButtonView: UIView, CAAnimationDelegate {
    
    
    private var circleLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()
    var videoHandlerDelegate: VideoHandlerDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    
    func setupView()  {
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        
        self.layer.addSublayer(trackLayer)
        self.layer.addSublayer(circleLayer)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.videoHandlerDelegate?.startRecording()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        circleLayer.removeAllAnimations()
    }
    
    
    func setupCircleProgressBar() {
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = self.bounds.height/2.0
        let circularPath = UIBezierPath(arcCenter: center, radius: radius , startAngle: -CGFloat.pi/2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        
        circleLayer.frame = self.bounds
        circleLayer.path = circularPath.cgPath
        circleLayer.strokeColor = UIColor.red.cgColor
        circleLayer.lineWidth = 8
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = CAShapeLayerLineCap.round
        circleLayer.strokeEnd = 0

        trackLayer.frame = self.bounds
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor.darkGray.cgColor
        trackLayer.lineWidth = 8
        trackLayer.fillColor = UIColor.clear.cgColor
        
    }
    
    func hideCircleBar() {
        circleLayer.isHidden = true
        trackLayer.isHidden = true
    }
    
    func showCircleBar() {
        circleLayer.isHidden = false
        trackLayer.isHidden = false
    }
    
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        videoHandlerDelegate?.stopRecording()
    }
    
    func startAnimation() {
        
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.delegate = self
        basicAnimation.toValue = 1
        basicAnimation.duration = 15
        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
        basicAnimation.isRemovedOnCompletion = false
        circleLayer.add(basicAnimation, forKey: "animate")
        
    }
}


