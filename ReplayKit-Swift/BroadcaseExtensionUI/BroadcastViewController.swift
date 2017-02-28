import ReplayKit

class BroadcastViewController: UIViewController {
    @IBOutlet
    var startButton:UIButton!

    @IBOutlet
    var endpointURLField:UITextField!
    
    @IBOutlet
    var streamNameField:UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.addTarget(self, action: #selector(BroadcastViewController.userDidFinishSetup), for: .touchDown)
    }

    func userDidFinishSetup() {

        let broadcastURL:URL = URL(string: endpointURLField.text!)!

        let streamName:String = streamNameField.text!
        let endpointURL:String = endpointURLField.text!
        let setupInfo: [String: NSCoding & NSObjectProtocol] =  [
            "endpointURL" : endpointURL as NSString,
            "streamName" : streamName as NSString,
        ]
        
        let bitrate = 2500
        let width = 1280
        let height = 720

        let broadcastConfiguration:RPBroadcastConfiguration = RPBroadcastConfiguration()
        broadcastConfiguration.clipDuration = 2
        broadcastConfiguration.videoCompressionProperties = [
            AVVideoCodecKey: AVVideoCodecH264 as NSSecureCoding & NSObjectProtocol,
            AVVideoWidthKey: width as NSSecureCoding & NSObjectProtocol,
            AVVideoHeightKey: height as NSSecureCoding & NSObjectProtocol,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel as NSSecureCoding & NSObjectProtocol,
            AVVideoAverageBitRateKey: (bitrate * 1024) as NSSecureCoding & NSObjectProtocol,
        ]

        self.extensionContext?.completeRequest(
            withBroadcast: broadcastURL,
            broadcastConfiguration: broadcastConfiguration,
            setupInfo: setupInfo
        )
    }

    func userDidCancelSetup() {
        let error = NSError(domain: "com.github.shogo4405.lf", code: -1, userInfo: nil)
        self.extensionContext?.cancelRequest(withError: error)
    }
}
