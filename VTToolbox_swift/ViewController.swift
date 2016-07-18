import UIKit
import AVFoundation

class ViewController: UIViewController {
    var capture:VideoIOComponent!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func StartPtnPush(sender: UIButton) {
        capture = VideoIOComponent()
        capture.attachCamera(self)
    }
}