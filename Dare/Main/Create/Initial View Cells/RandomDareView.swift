//
//  RandomDareCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/13/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class RandomDareView: UIView {
    
    let rollDiceAnimation = UIImageView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            setUpElements()
            setUpConstraints()
        }
        
        func setUpElements() {
            self.backgroundColor = .black
            
            let imgListArray :NSMutableArray = []
            for countValue in 1...6
            {
                let strImageName : String = "Dice_\(countValue)"
                let image  = UIImage(named:strImageName)
                imgListArray.add(image!)
            }
            
            self.rollDiceAnimation.animationImages = imgListArray as? [UIImage]
            self.rollDiceAnimation.animationDuration = 1.0
            self.rollDiceAnimation.startAnimating()
            rollDiceAnimation.translatesAutoresizingMaskIntoConstraints = false
            addSubview(rollDiceAnimation)
        }
        
        func setUpConstraints() {
            NSLayoutConstraint.activate([
                rollDiceAnimation.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                rollDiceAnimation.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                rollDiceAnimation.heightAnchor.constraint(equalToConstant: 100),
                rollDiceAnimation.widthAnchor.constraint(equalToConstant: 100)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
