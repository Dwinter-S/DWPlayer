//
//  ConstraintRelationConverter.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/21.
//

import UIKit

class ConstraintRelationConverter {
    let generators: [ConstraintsGenerator]
    init(from: UIView, attrs: [ConstraintItem.Attribute], to: ConstraintRelationTarget, relation: NSLayoutConstraint.Relation) {
        var generators = [ConstraintsGenerator]()
        for attr in attrs {
            var toItem: ConstraintItem?
            if let item = to as? ConstraintItem {
                toItem = item
            } else if let toView = to as? UIView {
                toItem = ConstraintItem(item: toView, attr: attr)
            }
            let generator = ConstraintsGenerator(fromItem: ConstraintItem(item: from, attr: attr), relation: relation, toItem: toItem)
            generators.append(generator)
        }
        self.generators = generators
    }
    
    init(from: UIView, attrs: [ConstraintItem.Attribute], toConstant: ConstraintConstantNumberTarget, relation: NSLayoutConstraint.Relation) {
        var generators = [ConstraintsGenerator]()
        for attr in attrs {
            let fromItem = ConstraintItem(item: from, attr: attr)
            var toItem: ConstraintItem?
            if fromItem.attrType != .dimension {
                toItem = ConstraintItem(item: from.superview!, attr: attr)
            }
            let generator = ConstraintsGenerator(fromItem: fromItem, relation: relation, toItem: toItem)
            generator.constant = toConstant
            generators.append(generator)
        }
        self.generators = generators
    }
    
    @discardableResult
    func multiplier(_ multiplier: CGFloat) -> ConstraintRelationConverter {
        for generator in generators {
            generator.multiplier *= multiplier
        }
        return self
    }
    
    @discardableResult
    func offset(_ offset: ConstraintConstantOffsetTarget) -> ConstraintPriorityConverter {
        for generator in generators {
            generator.offset = offset
        }
        return ConstraintPriorityConverter(generators: generators)
    }
    
    @discardableResult
    func insets(_ insets: ConstraintConstantInsetsTarget) -> ConstraintPriorityConverter {
        for generator in generators {
            generator.insets = insets
        }
        return ConstraintPriorityConverter(generators: generators)
    }
}

class ConstraintPriorityConverter {
    let generators: [ConstraintsGenerator]
    init(generators: [ConstraintsGenerator]) {
        self.generators = generators
    }
    
    @discardableResult
    func priority(_ priority: Float) -> ConstraintPriorityConverter {
        for generator in generators {
            generator.priority = priority
        }
        return self
    }
}
