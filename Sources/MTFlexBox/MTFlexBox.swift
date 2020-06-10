//
//  MTFlexBox.swift
//  MTFlexBox
//
//  Created by Maksim Tochilkin on 10.06.2020.
//  Copyright © 2020 Maksim Tochilkin. All rights reserved.
//

import UIKit

final class Spacer: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


final class MTFlexBox: UIView {
    
    var nodes: [Node] = []
    var axis: Axis = .horizontal
    var layout: Layout?
    var padding: UIEdgeInsets = .all(0)
    
    static var layoutQueue = DispatchQueue(label: "layout", qos: .userInteractive)
    
    required init(@FlexBuilder builder: () -> [UIView]) {
        super.init(frame: .zero)
        let views = builder()
        
        for view in views {
            addSubview(view)
        }
        
        layout = FlexLayout(flex: [Int](repeating: 1, count: views.count))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        layout?.layoutRect = Rect(from: self.bounds, axis: self.axis)
        let subviews = self.subviews
        layout?.willLayout()
        
        Self.layoutQueue.async { [weak self] in
            guard let self = self else { return }
            guard var layout = self.layout else { return }
            
            let rects = subviews.compactMap { layout.transform($0) }
            
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: 0.2) {
                    for (index, node) in rects.enumerated() {
                        self.subviews[index].frame = node.cgRect(axis: self.axis).inset(by: self.padding)
                        print(node.cgRect(axis: self.axis))
                    }
                }
                
            }
        }
    }
    
    
    func axis(_ axis: Axis) -> MTFlexBox{
        self.axis = axis
        return self
    }
    
    func layout(_ layout: Layout) -> MTFlexBox {
        self.layout = layout
        return self
    }
    
    func padding(_ padding: UIEdgeInsets) -> MTFlexBox {
        self.padding = padding
        return self
    }
    
}


struct Node {
    var axisRect: Rect
    var flex: Int
}


protocol Layout {
    mutating func transform(_ node: UIView) -> Rect
    var layoutRect: Rect { get set }
    mutating func willLayout()
}

struct FlexLayout: Layout {
    
    mutating func willLayout() {
        count = 0
    }
    
    enum OrthognalFlex: CaseIterable {
        case leading, center, trailing
    }
    
    var axisRect: Rect = .zero
    
    var layoutRect: Rect {
        
        get {
            axisRect
        }
        set {
            axisRect = newValue
            unitStep = axisRect.majorSize / CGFloat(self.flex.reduce(0, +))
            unitStep -= self.spacing * CGFloat(self.flex.count + 1)
        }
    }
    
    var flex: [Int]
    var unitStep: CGFloat = 0
    lazy var offset: CGFloat = spacing
    var spacing: CGFloat = 0
    var orthognalFlex: OrthognalFlex = .leading
    var count = 0
    
    mutating func transform(_ node: UIView) -> Rect {
        var rect: Rect = .zero
        
        rect.minorSize = axisRect.minorSize
        rect.majorSize = unitStep * CGFloat(flex[count])
        
        switch self.orthognalFlex {
        
        case .leading:
            rect.minorPos = layoutRect.minorPos
        case .center:
            rect.minorCenter = axisRect.minorCenter
        case .trailing:
            rect.minorPos = axisRect.minorSize - node.frame.width
        }
        
        rect.majorPos = offset
        offset += rect.majorSize + self.spacing
        count += 1
        
        return rect
    }
}

@_functionBuilder struct FlexBuilder {
    static func buildBlock(_ views: UIView...) -> [UIView] {
        return views
    }
}


enum Axis: CaseIterable {
    case horizontal, vertical
}

struct Rect {
    static var zero = Rect()
    var majorPos: CGFloat = 0
    var minorPos: CGFloat = 0
    var majorSize: CGFloat = 0
    var minorSize: CGFloat = 0
    
    init(from bounds: CGRect, axis: Axis) {
        (majorSize, minorSize) =
            (axis == .horizontal) ? (bounds.width, bounds.height) : (bounds.height, bounds.width)
        
        (majorPos, minorPos) =
            (axis == .horizontal) ? (bounds.origin.x, bounds.origin.y) : (bounds.origin.y, bounds.origin.x)
    }
    
    init() { }
    
    func cgRect(axis: Axis) -> CGRect {
        let (x, y) = (axis == .horizontal) ? (majorPos, minorPos) : (minorPos, majorPos)
        let (width, height) = (axis == .horizontal) ? (majorSize, minorSize) : (minorSize, majorSize)
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    var minorCenter: CGFloat {
        get {
            minorPos + minorSize / 2
        }
        
        set {
            minorPos = newValue - minorSize / 2
        }
    }
    
    var majorCenter: CGFloat {
        get {
            majorPos + majorSize / 2
        }
        
        set {
            majorPos = newValue - majorSize / 2
        }
    }
}

extension CGRect {
    var centerX: CGFloat {
        get {
            origin.x + size.width / 2
        }
        
        set {
            origin.x = newValue - size.width / 2
        }
    }
    
    var centerY: CGFloat {
        get {
            origin.y + size.height / 2
        }
        
        set {
            origin.y = newValue - size.height / 2
        }
    }
}

protocol Configurable {
    init()
}

extension Configurable {
    init(_ config: (Self) -> Void) {
        self.init()
        config(self)
    }
}

extension NSObject: Configurable { }

extension UIEdgeInsets {
   static func all(_ spacing: CGFloat) -> UIEdgeInsets {
        .init(top: spacing, left: spacing, bottom: spacing, right: spacing)
    }
}
