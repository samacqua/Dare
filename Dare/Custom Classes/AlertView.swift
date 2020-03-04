//
//  AlertView.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/13/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class AlertView: UIView {
    
    var message = ""
    var errorLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        
        self.setUpElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpElements() {
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        self.layer.cornerRadius = 6.0
        self.layer.masksToBounds = true
    }
}
