//
//  ConstraintsCreator.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/21.
//

import UIKit

class ConstraintsCreator {
    private var middleAttrsConverters: [ConstraintAttributesConverter] = []
    
    private var generators: [ConstraintsGenerator] {
        var generators = [ConstraintsGenerator]()
        for middleAttrsConverter in middleAttrsConverters {
            if let gens = middleAttrsConverter.relationHander?.generators {
                generators.append(contentsOf: gens)
            }
        }
        return generators
    }
    
    let item: UIView
    init(item: UIView) {
        self.item = item
    }
    
    var top: ConstraintAttributesConverter {
        return addAtrribute(.top)
    }
    
    var bottom: ConstraintAttributesConverter {
        return addAtrribute(.bottom)
    }
    
    var left: ConstraintAttributesConverter {
        return addAtrribute(.left)
    }
    
    var right: ConstraintAttributesConverter {
        return addAtrribute(.right)
    }
    
    var leading: ConstraintAttributesConverter {
        return addAtrribute(.leading)
    }
    
    var trailing: ConstraintAttributesConverter {
        return addAtrribute(.trailing)
    }
    
    var firstBaseline: ConstraintAttributesConverter {
        return addAtrribute(.firstBaseline)
    }
    
    var lastBaseline: ConstraintAttributesConverter {
        return addAtrribute(.lastBaseline)
    }
    
    var edges: ConstraintAttributesConverter {
        return addAtrribute(.edges)
    }
    
    var centerX: ConstraintAttributesConverter {
        return addAtrribute(.centerX)
    }
    
    var centerY: ConstraintAttributesConverter {
        return addAtrribute(.centerY)
    }
    
    var center: ConstraintAttributesConverter {
        return addAtrribute(.center)
    }
    
    var width: ConstraintAttributesConverter {
        return addAtrribute(.width)
    }
    
    var height: ConstraintAttributesConverter {
        return addAtrribute(.height)
    }
    
    private func addAtrribute(_ attr: ConstraintItem.Attribute) -> ConstraintAttributesConverter {
        let middleAttrsConverter = ConstraintAttributesConverter(item: item, attr: attr)
        middleAttrsConverters.append(middleAttrsConverter)
        return middleAttrsConverter
    }
    
    static func addConstaints(view: UIView, constraintsCreator: (ConstraintsCreator) -> ()) {
        view.translatesAutoresizingMaskIntoConstraints = false
        let creator = ConstraintsCreator(item: view)
        constraintsCreator(creator)
        var constraints = [NSLayoutConstraint]()
        for generator in creator.generators {
            constraints.append(contentsOf: generator.constraints)
        }
        NSLayoutConstraint.activate(constraints)
        view.add(constraints: creator.generators)
    }
    
    static func updateConstaints(view: UIView, constraintsCreator: (ConstraintsCreator) -> ()) {
        guard !view.constraintsGenerators.isEmpty else {
            addConstaints(view: view, constraintsCreator: constraintsCreator)
            return
        }
        let creator = ConstraintsCreator(item: view)
        constraintsCreator(creator)
        for generator in creator.generators {
            generator.updateConstraintsIfNeeded()
        }
    }
}
