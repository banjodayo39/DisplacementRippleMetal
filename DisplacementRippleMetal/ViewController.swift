//
//  ViewController.swift
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 3/27/23.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    var renderer: Renderer?
    var mtkView: MTKView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    func setUpView() {
        view.backgroundColor = .white
        guard let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Device not found")
        }
        let frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: 300))
        mtkView = MTKView(frame: frame, device: device)
        renderer = Renderer(device: device, view: mtkView!)
        
        view.addSubview(mtkView!)
        mtkView?.center = view.center

    }


}

