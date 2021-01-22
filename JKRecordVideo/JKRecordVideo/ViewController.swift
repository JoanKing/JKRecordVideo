//
//  ViewController.swift
//  JKRecordVideo
//
//  Created by IronMan on 2021/1/13.
//

import UIKit
import JKSwiftExtension
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "视频录制"
        self.view.backgroundColor = .white
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
        button.setTitle("视频", for: .normal)
        button.backgroundColor = .brown
        self.view.addSubview(button)
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        
        button.center = self.view.center
       
    }
    
    @objc func click() {
        let recordVideoViewController = TradeCACertificationViewController()
        recordVideoViewController.modalPresentationStyle = .fullScreen
        self.present(recordVideoViewController, animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
