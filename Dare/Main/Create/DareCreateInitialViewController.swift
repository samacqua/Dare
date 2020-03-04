//
//  DareCreateInitialViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/13/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class DareCreateInitialViewController: UIViewController {
    
    var createDareButton: UIButton!
    var captureVideoButton: UIButton!
    var browseDaresButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpElements()
    }
    
    func setUpElements() {
        createDareButton = UIButton()
        createDareButton.translatesAutoresizingMaskIntoConstraints = false
        createDareButton.addTarget(self, action: #selector(createDarePressed), for: .touchUpInside)
        view.addSubview(createDareButton)
        
        captureVideoButton = UIButton()
        captureVideoButton.translatesAutoresizingMaskIntoConstraints = false
        captureVideoButton.addTarget(self, action: #selector(captureVideoPressed), for: .touchUpInside)
        view.addSubview(captureVideoButton)
        
        browseDaresButton = UIButton()
        browseDaresButton.translatesAutoresizingMaskIntoConstraints = false
        browseDaresButton.addTarget(self, action: #selector(browseDaresPressed), for: .touchUpInside)
        view.addSubview(browseDaresButton)
    }
    
    // MARK: - Actions
    
    @objc func createDarePressed() {
        
    }
    
    @objc func captureVideoPressed() {
        
    }
    
    @objc func browseDaresPressed() {
        
    }
}
