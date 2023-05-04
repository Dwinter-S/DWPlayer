//
//  UIViewDSL.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/20.
//

import UIKit

extension UIView: ConstraintView {
    var dwc: DWConstraintDSL {
        return DWConstraintDSL(item: self)
    }
}

protocol ConstraintView {
    
}

extension ConstraintView {
    internal var constraintsGenerators: [ConstraintsGenerator] {
        return self.constraintsSet.allObjects as! [ConstraintsGenerator]
    }
    
    internal func add(constraints: [ConstraintsGenerator]) {
        let constraintsSet = self.constraintsSet
        for constraint in constraints {
            constraintsSet.add(constraint)
        }
    }
    
    internal func remove(constraints: [ConstraintsGenerator]) {
        let constraintsSet = self.constraintsSet
        for constraint in constraints {
            constraintsSet.remove(constraint)
        }
    }
    
    private var constraintsSet: NSMutableSet {
        let constraintsSet: NSMutableSet
        
        if let existing = objc_getAssociatedObject(self, &constraintsKey) as? NSMutableSet {
            constraintsSet = existing
        } else {
            constraintsSet = NSMutableSet()
            objc_setAssociatedObject(self, &constraintsKey, constraintsSet, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return constraintsSet
        
    }
    
}

private var constraintsKey: UInt8 = 0


