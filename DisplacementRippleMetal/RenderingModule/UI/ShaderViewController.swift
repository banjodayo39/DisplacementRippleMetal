//
//  ShaderViewController.swift
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 10/14/23.
//

import UIKit
import MetalKit

class ShaderViewController: UIViewController {

    var renderer: Renderer?
    var mtkView: MTKView?
    
    let shaderItem: ShaderItem
    
    init(shaderItem: ShaderItem) {
        self.shaderItem = shaderItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        renderer = Renderer(device: device,
                            view: mtkView!,
                            vertexFunctionName: shaderItem.vertexName,
                            fragmentFunctionName: shaderItem.fragmentName)
        
        view.addSubview(mtkView!)
        mtkView?.center = view.center
    }
}

