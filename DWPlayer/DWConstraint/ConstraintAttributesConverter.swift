//
//  ConstraintAttributesConverter.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/21.
//

import UIKit

class ConstraintAttributesConverter {
    
    var item: UIView
    private var relation: NSLayoutConstraint.Relation = .equal
    var relationHander: ConstraintRelationConverter?
    
    
    var attributes = [ConstraintItem.Attribute]()
//    var constraintsGenerators = [ConstraintsGenerator]()
    
    init(item: UIView, attr: ConstraintItem.Attribute) {
        self.item = item
        self.attributes = [attr]
//        self.constraintsGenerators = [ConstraintsGenerator(fromItem: ConstraintItem(item: item, attr: attr))]
    }
    
    private func addAtrribute(_ attr: ConstraintItem.Attribute) {
//        constraintsGenerators.append(ConstraintsGenerator(fromItem: ConstraintItem(item: item, attr: attr)))
        attributes.append(attr)
    }
    
    var top: ConstraintAttributesConverter {
        addAtrribute(.top)
        return self
    }
    
    var bottom: ConstraintAttributesConverter {
        addAtrribute(.bottom)
        return self
    }
    
    var left: ConstraintAttributesConverter {
        addAtrribute(.left)
        return self
    }
    
    var right: ConstraintAttributesConverter {
        addAtrribute(.right)
        return self
    }
    
    var leading: ConstraintAttributesConverter {
        addAtrribute(.leading)
        return self
    }
    
    var trailing: ConstraintAttributesConverter {
        addAtrribute(.trailing)
        return self
    }
    
    var firstBaseline: ConstraintAttributesConverter {
        addAtrribute(.firstBaseline)
        return self
    }
    
    var lastBaseline: ConstraintAttributesConverter {
        addAtrribute(.lastBaseline)
        return self
    }
    
    var edges: ConstraintAttributesConverter {
        addAtrribute(.edges)
        return self
    }
    
    var centerX: ConstraintAttributesConverter {
        addAtrribute(.centerX)
        return self
    }
    
    var centerY: ConstraintAttributesConverter {
        addAtrribute(.centerY)
        return self
    }
    
    var center: ConstraintAttributesConverter {
        addAtrribute(.center)
        return self
    }
    
    var width: ConstraintAttributesConverter {
        addAtrribute(.width)
        return self
    }
    
    var height: ConstraintAttributesConverter {
        addAtrribute(.height)
        return self
    }
    
    @discardableResult
    func equalTo(_ to: ConstraintRelationTarget) -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, to: to, relation: .equal)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func lessThanOrEqualTo(_ to: ConstraintRelationTarget) -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, to: to, relation: .lessThanOrEqual)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func greaterThanOrEqualTo(_ to: ConstraintRelationTarget) -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, to: to, relation: .greaterThanOrEqual)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func equalTo(_ to: ConstraintConstantNumberTarget) -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, toConstant: to, relation: .equal)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func lessThanOrEqualTo(_ to: ConstraintConstantNumberTarget) -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, toConstant: to, relation: .lessThanOrEqual)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func greaterThanOrEqualTo(_ to: ConstraintConstantNumberTarget) -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, toConstant: to, relation: .greaterThanOrEqual)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func equalToSuperview() -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, to: item.superview!, relation: .equal)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func lessThanOrEqualToSuperview() -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, to: item.superview!, relation: .lessThanOrEqual)
        self.relationHander = relationHander
        return relationHander
    }
    
    @discardableResult
    func greaterThanOrEqualToSuperview() -> ConstraintRelationConverter {
        let relationHander = ConstraintRelationConverter(from: item, attrs: attributes, to: item.superview!, relation: .greaterThanOrEqual)
        self.relationHander = relationHander
        return relationHander
    }
    
}
