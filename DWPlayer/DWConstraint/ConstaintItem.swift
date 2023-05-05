//
//  ConstraintItem.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/21.
//

import UIKit
class ConstraintItem {
    enum Attribute {
        case top
        case bottom
        case left
        case right
        case leading
        case trailing
        case firstBaseline
        case lastBaseline
        case edges
        case centerX
        case centerY
        case center
        case width
        case height
    }
    
    enum AttributeType {
        case xAxis
        case yAxis
        case dimension
        case mixed
    }
    
    var attrType: AttributeType {
        switch attr {
        case .left, .right, .leading, .trailing, .centerX:
            return .xAxis
        case .top, .bottom, .centerY, .firstBaseline, .lastBaseline:
            return .yAxis
        case .width, .height:
            return .dimension
        default:
            return .mixed
        }
    }

    
//    enum LayoutAnchor {
//        case xAxis(NSLayoutXAxisAnchor)
//        case yAxis(NSLayoutYAxisAnchor)
//        case dimension(NSLayoutDimension)
//        static func ~= (lhs: Self, rhs: Self) -> Bool {
//            switch (lhs, rhs) {
//            case
//                (.xAxis, .xAxis),
//                (.yAxis, .yAxis),
//                (.dimension, .dimension):
//                return true
//
//            default:
//                return false
//            }
//        }
//    }
    
    let item: UIView
    let attr: Attribute
    
    init(item: UIView, attr: Attribute) {
        self.item = item
        self.attr = attr
    }
    
    var xAnchors: [Attribute: NSLayoutXAxisAnchor] {
        switch attr {
        case .left:
            return [.left: item.leftAnchor]
        case .right:
            return [.right: item.rightAnchor]
        case .leading:
            return [.leading: item.leadingAnchor]
        case .trailing:
            return [.trailing: item.trailingAnchor]
        case .centerX, .center:
            return [.centerX: item.centerXAnchor]
        case .edges:
            return [.leading: item.leadingAnchor, .trailing: item.trailingAnchor]
        default: return [:]
        }
    }
    var yAnchors: [Attribute: NSLayoutYAxisAnchor] {
        switch attr {
        case .top:
            return [.top: item.topAnchor]
        case .bottom:
            return [.bottom: item.bottomAnchor]
        case .centerY, .center:
            return [.centerY: item.centerYAnchor]
        case .lastBaseline:
            return [.lastBaseline: item.lastBaselineAnchor]
        case .firstBaseline:
            return [.firstBaseline: item.firstBaselineAnchor]
        case .edges:
            return [.top: item.topAnchor, .bottom: item.bottomAnchor]
        default: return [:]
        }
    }
    var dimensions: [Attribute: NSLayoutDimension] {
        switch attr {
        case .width:
            return [.width: item.widthAnchor]
        case .height:
            return [.height: item.heightAnchor]
        default: return [:]
        }
    }

    
//    lazy var layoutAnchors: [LayoutAnchor] = {
//        switch attr {
//        case .left:
//            return [.xAxis(item.leftAnchor)]
//        case .right:
//            return [.xAxis(item.rightAnchor)]
//        case .leading:
//            return [.xAxis(item.leadingAnchor)]
//        case .trailing:
//            return [.xAxis(item.trailingAnchor)]
//        case .centerX:
//            return [.xAxis(item.centerXAnchor)]
//            
//        case .top:
//            return [.yAxis(item.topAnchor)]
//        case .bottom:
//            return [.yAxis(item.bottomAnchor)]
//        case .centerY:
//            return [.yAxis(item.centerYAnchor)]
//        case .firstBaseline:
//            return [.yAxis(item.firstBaselineAnchor)]
//        case .lastBaseline:
//            return [.yAxis(item.lastBaselineAnchor)]
//            
//        case .width:
//            return [.dimension(item.widthAnchor)]
//        case .height:
//            return [.dimension(item.heightAnchor)]
//            
//        case .edges:
//            return [.xAxis(item.leftAnchor), .xAxis(item.rightAnchor), .yAxis(item.topAnchor), .yAxis(item.bottomAnchor)]
//        case .center:
//            return [.xAxis(item.centerXAnchor), .yAxis(item.centerYAnchor)]
//        }
//    }()
//    
//    static func ~= (lhs: ConstraintItem, rhs: ConstraintItem) -> Bool {
//        guard lhs.layoutAnchors.count == rhs.layoutAnchors.count else { return false }
//        if lhs.layoutAnchors.count == 1 {
//            return lhs.layoutAnchors[0] ~= rhs.layoutAnchors[0]
//        } else {
//            return lhs.attr == rhs.attr
//        }
//    }
    
}

//protocol ConstraintRelationTarget: ConstraintConstantTarget {
//
//}

protocol ConstraintRelationTarget {
    
}

//extension ConstraintRelationTarget {
//    func toConstantTarget() -> ConstraintConstantTarget? {
//        if self is UIView || self is ConstraintItem {
//            return nil
//        }
//        return ConstraintConstantTarget()
//    }
//}

//extension Int: ConstraintRelationTarget {}
//extension UInt: ConstraintRelationTarget {}
//extension Float: ConstraintRelationTarget {}
//extension Double: ConstraintRelationTarget {}
//extension CGFloat: ConstraintRelationTarget {}
//extension CGSize: ConstraintRelationTarget {}
//extension CGPoint: ConstraintRelationTarget {}
//extension UIEdgeInsets: ConstraintRelationTarget {}
extension ConstraintItem: ConstraintRelationTarget {}
extension UIView: ConstraintRelationTarget {}

protocol ConstraintConstantNumberTarget {
    
}

protocol ConstraintConstantOffsetTarget {

}

protocol ConstraintConstantInsetsTarget {

}

extension Int: ConstraintConstantNumberTarget, ConstraintConstantOffsetTarget, ConstraintConstantInsetsTarget {}
extension UInt: ConstraintConstantNumberTarget, ConstraintConstantOffsetTarget, ConstraintConstantInsetsTarget {}
extension Float: ConstraintConstantNumberTarget, ConstraintConstantOffsetTarget, ConstraintConstantInsetsTarget {}
extension Double: ConstraintConstantNumberTarget, ConstraintConstantOffsetTarget, ConstraintConstantInsetsTarget {}
extension CGFloat: ConstraintConstantNumberTarget, ConstraintConstantOffsetTarget, ConstraintConstantInsetsTarget {}

extension CGPoint: ConstraintConstantOffsetTarget {}
extension UIEdgeInsets: ConstraintConstantInsetsTarget {}


struct ConstraintConstant: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    var constant: CGFloat?
    init(floatLiteral value: FloatLiteralType) {
        constant = CGFloat(value)
    }
    init(integerLiteral value: IntegerLiteralType) {
        constant = CGFloat(value)
    }
}
