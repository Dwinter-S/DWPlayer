//
//  ConstraintsGenerator.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/21.
//

import UIKit

class ConstraintsGenerator {
    let fromItem: ConstraintItem
    var toItem: ConstraintItem?
    var relation: NSLayoutConstraint.Relation
    var multiplier: CGFloat = 1
    var constant: ConstraintConstantNumberTarget = 0
    var priority: Float = 1000
    var offset: ConstraintConstantOffsetTarget?
    var insets: ConstraintConstantInsetsTarget?
    
    init(fromItem: ConstraintItem, relation: NSLayoutConstraint.Relation, toItem: ConstraintItem?) {
        self.fromItem = fromItem
        self.relation = relation
        self.toItem = toItem
    }
    
    func toCGFloat(value: Any) -> CGFloat? {
        if let intValue = value as? Int {
            return CGFloat(intValue)
        } else if let intValue = value as? UInt {
            return CGFloat(intValue)
        } else if let intValue = value as? Float {
            return CGFloat(intValue)
        } else if let intValue = value as? Double {
            return CGFloat(intValue)
        }
        return nil
    }
    
    lazy var constraints: [NSLayoutConstraint] = {
        guard isLegal() else {
            fatalError("constraint is not legal!")
        }
        var constraints = [NSLayoutConstraint]()
        if let toItem = toItem {
            let xAxisConstraints = fromItem.xAnchors.map({ type, anchor in
                return self.constraint(from: anchor, relation: self.relation, to: toItem.xAnchors[type]!, constant: self.finalConstant(with: type), priority: priority)
            })
            let yAxisConstraints = fromItem.yAnchors.map({ type, anchor in
                return self.constraint(from: anchor, relation: self.relation, to: toItem.yAnchors[type]!, constant: self.finalConstant(with: type), priority: priority)
            })
            let dimensionConstraints = fromItem.dimensions.map({ type, anchor in
                return self.constraint(from: anchor, relation: self.relation, to: toItem.dimensions[type]!, constant: self.finalConstant(with: type), priority: priority)
            })
            constraints = xAxisConstraints + yAxisConstraints + dimensionConstraints
        } else {
            switch fromItem.attrType {
            case .dimension:
                constraints.append(self.constraint(from: fromItem.dimensions[fromItem.attr]!, relation: relation, to: toItem?.dimensions[fromItem.attr], multiplier: multiplier, constant: self.finalConstant(with: fromItem.attr), priority: priority))
            default: ()
            }
        }
        return constraints
    }()
    
    func updateConstraintsIfNeeded() {
        let constraints = constraints
        let existConstraints = fromItem.item.constraintsGenerators.flatMap({ $0.constraints })
        for constraint in constraints {
            if let updateCons = existConstraints.first(where: { self.isSame(lhs: $0, rhs: constraint) }) {
                updateCons.constant = constraint.constant
            }
        }
    }
    
    func isSame(lhs: NSLayoutConstraint, rhs: NSLayoutConstraint) -> Bool {
        guard lhs.relation == rhs.relation &&
                lhs.priority == rhs.priority &&
                lhs.multiplier == rhs.multiplier &&
                lhs.secondAnchor === rhs.secondAnchor &&
                lhs.firstAnchor === rhs.firstAnchor else {
            return false
        }
        return true
    }
    
//    internal func == (lhs: NSLayoutConstraint, rhs: NSLayoutConstraint) -> Bool {
//        guard lhs.firstAttribute == rhs.firstAttribute &&
//              lhs.secondAttribute == rhs.secondAttribute &&
//              lhs.relation == rhs.relation &&
//              lhs.priority == rhs.priority &&
//              lhs.multiplier == rhs.multiplier &&
//              lhs.secondItem === rhs.secondItem &&
//              lhs.firstItem === rhs.firstItem else {
//            return false
//        }
//        return true
//    }
    
    private func constraint(from: NSLayoutDimension,
                            relation: NSLayoutConstraint.Relation,
                            to: NSLayoutDimension?,
                            multiplier: CGFloat = 1,
                            constant: CGFloat = 0,
                            priority: Float) -> NSLayoutConstraint {
        var constraint: NSLayoutConstraint
        switch relation {
        case .lessThanOrEqual:
            if let to = to {
                constraint = from.constraint(lessThanOrEqualTo: to, multiplier: multiplier, constant: constant)
            } else {
                constraint = from.constraint(lessThanOrEqualToConstant: constant)
            }
        case .equal:
            if let to = to {
                constraint = from.constraint(equalTo: to, multiplier: multiplier, constant: constant)
            } else {
                constraint = from.constraint(equalToConstant: constant)
            }
        case .greaterThanOrEqual:
            if let to = to {
                constraint = from.constraint(greaterThanOrEqualTo: to, multiplier: multiplier, constant: constant)
            } else {
                constraint = from.constraint(greaterThanOrEqualToConstant: constant)
            }
        }
        constraint.priority = UILayoutPriority(priority)
        return constraint
    }
    
    private func constraint<T>(from: NSLayoutAnchor<T>,
                               relation: NSLayoutConstraint.Relation,
                               to: NSLayoutAnchor<T>,
                               constant: CGFloat = 0,
                               priority: Float) -> NSLayoutConstraint where T: NSLayoutAnchor<T> {
        var constraint: NSLayoutConstraint
        switch relation {
        case .lessThanOrEqual:
            constraint = from.constraint(lessThanOrEqualTo: to, constant: constant)
        case .equal:
            constraint = from.constraint(equalTo: to, constant: constant)
        case .greaterThanOrEqual:
            constraint = from.constraint(greaterThanOrEqualTo: to, constant: constant)
        }
        constraint.priority = UILayoutPriority(priority)
        return constraint
    }
    
    private func finalConstant(with attr: ConstraintItem.Attribute) -> CGFloat {
        var constant = toCGFloat(value: constant) ?? 0
        switch attr {
        case .top, .firstBaseline, .lastBaseline, .centerY, .width, .height:
            if let offset = offset {
                if let number = toCGFloat(value: offset) {
                    constant += number
                } else if let point = offset as? CGPoint {
                    constant += point.y
                }
            } else if let insets = insets {
                if let number = toCGFloat(value: insets) {
                    constant += number
                } else if let insets = insets as? UIEdgeInsets {
                    constant += insets.top
                }
            }
        case .bottom:
            if let offset = offset {
                if let number = toCGFloat(value: offset) {
                    constant += number
                } else if let point = offset as? CGPoint {
                    constant += point.y
                }
            } else if let insets = insets {
                if let number = toCGFloat(value: insets) {
                    constant -= number
                } else if let insets = insets as? UIEdgeInsets {
                    constant -= insets.bottom
                }
            }
        case .leading, .left, .centerX:
            if let offset = offset {
                if let number = toCGFloat(value: offset) {
                    constant += number
                } else if let point = offset as? CGPoint {
                    constant += point.x
                }
            } else if let insets = insets {
                if let number = toCGFloat(value: insets) {
                    constant += number
                } else if let insets = insets as? UIEdgeInsets {
                    constant += insets.left
                }
            }
        case .trailing, .right:
            if let offset = offset {
                if let number = toCGFloat(value: offset) {
                    constant += number
                } else if let point = offset as? CGPoint {
                    constant += point.x
                }
            } else if let insets = insets {
                if let number = toCGFloat(value: insets) {
                    constant -= number
                } else if let insets = insets as? UIEdgeInsets {
                    constant -= insets.right
                }
            }
        default: ()
        }
        return constant
    }
    
    
    private func isLegal() -> Bool {
        if let toItem = toItem {
            if fromItem.attrType == .mixed, fromItem.attr != toItem.attr {
                return false
            }
            if fromItem.attrType != toItem.attrType {
                return false
            }
        } else {
            if fromItem.attrType != .dimension {
                return false
            }
        }
        return true
    }
    
}
