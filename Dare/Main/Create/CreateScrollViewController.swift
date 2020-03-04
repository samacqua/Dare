//
//  CreateCollectionViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/13/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class CreateScrollViewController: UIViewController {
    
    var scrollView: UIScrollView!
    
    var createDareView: CreateDareView!
    var cameraView: CameraView!
    var randomDareView: RandomDareView!
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpElements()
        setUpLayout()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func setUpElements() {
        
        scrollView = UIScrollView()
        scrollView.backgroundColor = .darkGray
        scrollView.contentSize.height = view.bounds.height * 3
        scrollView.delegate = self
        scrollView.setContentOffset(CGPoint(x: 0, y: view.bounds.height), animated: false)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.decelerationRate = .fast
        view.insertSubview(scrollView, at: 0)
        
        createDareView = CreateDareView()
        createDareView.parentVC = self
        createDareView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(createDareView)
        
        cameraView = CameraView()
        cameraView.parentViewController = self
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(cameraView)
        
        randomDareView = RandomDareView()
        randomDareView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(randomDareView)
        
    }
    
    func setUpLayout() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            createDareView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            createDareView.heightAnchor.constraint(equalToConstant: view.bounds.height),
            createDareView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            createDareView.widthAnchor.constraint(equalToConstant: view.bounds.width),
            
            cameraView.topAnchor.constraint(equalTo: createDareView.bottomAnchor),
            cameraView.heightAnchor.constraint(equalToConstant: view.bounds.height),
            cameraView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            cameraView.widthAnchor.constraint(equalToConstant: view.bounds.width),
            
            randomDareView.topAnchor.constraint(equalTo: cameraView.bottomAnchor),
            randomDareView.heightAnchor.constraint(equalToConstant: view.bounds.height),
            randomDareView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            randomDareView.widthAnchor.constraint(equalToConstant: view.bounds.width),
        ])
    }
}

extension CreateScrollViewController: UIScrollViewDelegate {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        // Create auto lock onto each view
        let viewHeight = view.bounds.height
        
        var offset = targetContentOffset.pointee
        let index = (offset.y / viewHeight)
        let roundedIndex = round(index)
        
        offset = CGPoint(x: 0, y: roundedIndex * UIScreen.main.bounds.height)
        targetContentOffset.pointee = offset
    }
}
