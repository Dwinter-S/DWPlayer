//
//  DWConstraintDSL.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/21.
//

import UIKit

class DWConstraintDSL {
    
    private let item: UIView
    init(item: UIView) {
        self.item = item
    }
    
    func addConstraints(_ constraintsCreator: (ConstraintsCreator) -> ()) {
        ConstraintsCreator.addConstaints(view: item, constraintsCreator: constraintsCreator)
    }
    
    func updateConstraints(_ constraintsCreator: (ConstraintsCreator) -> ()) {
        ConstraintsCreator.updateConstaints(view: item, constraintsCreator: constraintsCreator)
    }
    
    var top: ConstraintItem {
        return convertToConstaintItem(.top)
    }
    
    var bottom: ConstraintItem {
        return convertToConstaintItem(.bottom)
    }
    
    var left: ConstraintItem {
        return convertToConstaintItem(.left)
    }
    
    var right: ConstraintItem {
        return convertToConstaintItem(.right)
    }
    
    var leading: ConstraintItem {
        return convertToConstaintItem(.leading)
    }
    
    var trailing: ConstraintItem {
        return convertToConstaintItem(.trailing)
    }
    
    var lastBaseline: ConstraintItem {
        return convertToConstaintItem(.lastBaseline)
    }
    
    var firstBaseline: ConstraintItem {
        return convertToConstaintItem(.firstBaseline)
    }
    
    var edges: ConstraintItem {
        return convertToConstaintItem(.edges)
    }
    
    var centerX: ConstraintItem {
        return convertToConstaintItem(.centerX)
    }
    
    var centerY: ConstraintItem {
        return convertToConstaintItem(.centerY)
    }
    
    var center: ConstraintItem {
        return convertToConstaintItem(.centerX)
    }
    
    var width: ConstraintItem {
        return convertToConstaintItem(.width)
    }
    
    var height: ConstraintItem {
        return convertToConstaintItem(.height)
    }
    
    private func convertToConstaintItem(_ attr: ConstraintItem.Attribute) -> ConstraintItem {
        let layout = ConstraintItem(item: item, attr: attr)
        return layout
    }
    
}
