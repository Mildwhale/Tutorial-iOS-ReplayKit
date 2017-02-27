import Foundation

final class RTMPTSocket: NSObject, RTMPSocketCompatible {
    static let contentType:String = "application/x-fcs"

    var timeout:Int64 = 0
    var chunkSizeC:Int = RTMPChunk.defaultSize
    var chunkSizeS:Int = RTMPChunk.defaultSize
    var inputBuffer:[UInt8] = []
    var securityLevel:StreamSocketSecurityLevel = .none
    weak var delegate:RTMPSocketDelegate? = nil
    var connected:Bool = false {
        didSet {
            if (connected) {
                handshake.timestamp = Date().timeIntervalSince1970
                doOutput(bytes: handshake.c0c1packet)
                readyState = .versionSent
                return
            }
            timer = nil
            readyState = .closed
            for event in events {
                delegate?.dispatch(event: event)
            }
            events.removeAll()
        }
    }

    var timestamp:TimeInterval {
        return handshake.timestamp
    }

    var readyState:RTMPSocket.ReadyState = .uninitialized {
        didSet {
            delegate?.didSet(readyState: readyState)
        }
    }

    fileprivate(set) var totalBytesIn:Int64 = 0
    fileprivate(set) var totalBytesOut:Int64 = 0
    fileprivate(set) var queueBytesOut:Int64 = 0
    fileprivate var timer:Timer? {
        didSet {
            if let oldValue:Timer = oldValue {
                oldValue.invalidate()
            }
            if let timer:Timer = timer {
                RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
            }
        }
    }

    private var delay:UInt8 = 1
    private var index:Int64 = 0
    private var events:[Event] = []
    private var baseURL:URL!
    private var session:URLSession!
    private var request:URLRequest!
    private var c2packet:[UInt8] = []
    private var handshake:RTMPHandshake = RTMPHandshake()
    private let outputQueue:DispatchQueue = DispatchQueue(label: "com.github.shgoo4405.lf.RTMPTSocket.output")
    private var connectionID:String?
    private var isRequesting:Bool = false
    private var outputBuffer:[UInt8] = []
    private var lastResponse:Date = Date()

    override init() {
        super.init()
    }

    func connect(withName:String, port:Int) {
        let config:URLSessionConfiguration = URLSessionConfiguration.default
        config.httpShouldUsePipelining = true
        config.httpAdditionalHeaders = [
            "Content-Type": RTMPTSocket.contentType,
            "User-Agent": "Shockwave Flash",
        ]
        let scheme:String = securityLevel == .none ? "http" : "https"
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        baseURL = URL(string: "\(scheme)://\(withName):\(port)")!
        doRequest("/fcs/ident2", Data([0x00]), didIdent2)
        timer = Timer(timeInterval: 0.1, target: self, selector: #selector(RTMPTSocket.on(timer:)), userInfo: nil, repeats: true)
    }

    @discardableResult
    func doOutput(chunk:RTMPChunk, locked:UnsafeMutablePointer<UInt32>? = nil) -> Int {
        var bytes:[UInt8] = []
        let chunks:[[UInt8]] = chunk.split(chunkSizeS)
        for chunk in chunks {
            bytes.append(contentsOf: chunk)
        }
        outputQueue.sync {
            self.outputBuffer.append(contentsOf: bytes)
            if (!self.isRequesting) {
                self.doOutput(bytes: self.outputBuffer)
                self.outputBuffer.removeAll()
            }
        }
        return bytes.count
    }

    func close(isDisconnected:Bool) {
        deinitConnection(isDisconnected: isDisconnected)
    }

    func deinitConnection(isDisconnected:Bool) {
        if (isDisconnected) {
            let data:ASObject = (readyState == .handshakeDone) ?
                RTMPConnection.Code.connectClosed.data("") : RTMPConnection.Code.connectFailed.data("")
            events.append(Event(type: Event.RTMP_STATUS, bubbles: false, data: data))
        }
        guard let connectionID:String = connectionID else {
            return
        }
        doRequest("/close/\(connectionID)", Data(), didClose)
    }

    private func listen(data:Data?, response:URLResponse?, error:Error?) {

        lastResponse = Date()

        if (logger.isEnabledFor(level: .verbose)) {
            logger.verbose("\(data):\(response):\(error)")
        }

        if let error:Error = error {
            logger.error("\(error)")
            return
        }

        outputQueue.sync {
            if (self.outputBuffer.isEmpty) {
                self.isRequesting = false
            } else {
                self.doOutput(bytes: outputBuffer)
                self.outputBuffer.removeAll()
            }
        }

        guard
            let response:HTTPURLResponse = response as? HTTPURLResponse,
            let contentType:String = response.allHeaderFields["Content-Type"] as? String,
            let data:Data = data, contentType == RTMPTSocket.contentType else {
            return
        }

        var buffer:[UInt8] = data.bytes
        OSAtomicAdd64(Int64(buffer.count), &totalBytesIn)
        delay = buffer.remove(at: 0)
        inputBuffer.append(contentsOf: buffer)

        switch readyState {
        case .versionSent:
            if (inputBuffer.count < RTMPHandshake.sigSize + 1) {
                break
            }
            c2packet = handshake.c2packet(inputBuffer)
            inputBuffer = Array(inputBuffer[RTMPHandshake.sigSize + 1..<inputBuffer.count])
            readyState = .ackSent
            fallthrough
        case .ackSent:
            if (inputBuffer.count < RTMPHandshake.sigSize) {
                break
            }
            inputBuffer.removeAll()
            readyState = .handshakeDone
        case .handshakeDone:
            if (inputBuffer.isEmpty){
                break
            }
            let bytes:[UInt8] = inputBuffer
            inputBuffer.removeAll()
            delegate?.listen(bytes: bytes)
        default:
            break
        }
    }

    private func didIdent2(data:Data?, response:URLResponse?, error:Error?) {
        if let error:Error = error {
            logger.error("\(error)")
        }
        doRequest("/open/1", Data([0x00]), didOpen)
        if (logger.isEnabledFor(level: .verbose)) {
            logger.verbose("\(data?.bytes):\(response)")
        }
    }

    private func didOpen(data:Data?, response:URLResponse?, error:Error?) {
        if let error:Error = error {
            logger.error("\(error)")
        }
        guard let data:Data = data else {
            return
        }
        connectionID = String(data: data, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        doRequest("/idle/\(connectionID!)/0", Data([0x00]), didIdle0)
        if (logger.isEnabledFor(level: .verbose)) {
            logger.verbose("\(data.bytes):\(response)")
        }
    }

    private func didIdle0(data:Data?, response:URLResponse?, error:Error?) {
        if let error:Error = error {
            logger.error("\(error)")
        }
        connected = true
        if (logger.isEnabledFor(level: .verbose)) {
            logger.verbose("\(data?.bytes):\(response)")
        }
    }

    private func didClose(data:Data?, response:URLResponse?, error:Error?) {
        if let error:Error = error {
            logger.error("\(error)")
        }
        connected = false
        if (logger.isEnabledFor(level: .verbose)) {
            logger.verbose("\(data?.bytes):\(response)")
        }
    }

    private func idle() {
        guard let connectionID:String = connectionID, connected else {
            return
        }
        let index:Int64 = OSAtomicIncrement64(&self.index)
        doRequest("/idle/\(connectionID)/\(index)", Data([0x00]), didIdle)
    }

    private func didIdle(data:Data?, response:URLResponse?, error:Error?) {
        listen(data: data, response: response, error: error)
    }

    @objc private func on(timer:Timer) {
        guard (Double(delay) / 60) < abs(lastResponse.timeIntervalSinceNow), !isRequesting else {
            return
        }
        idle()
    }

    @discardableResult
    final private func doOutput(bytes:[UInt8]) -> Int {
        guard let connectionID:String = connectionID, connected else {
            return 0
        }
        let index:Int64 = OSAtomicIncrement64(&self.index)
        doRequest("/send/\(connectionID)/\(index)", Data(c2packet + bytes), listen)
        c2packet.removeAll()
        return bytes.count
    }

    private func doRequest(_ pathComonent: String,_ data:Data,_ completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        isRequesting = true
        request = URLRequest(url: baseURL.appendingPathComponent(pathComonent))
        request.httpMethod = "POST"
        session.uploadTask(with: request, from: data, completionHandler: completionHandler).resume()
        if (logger.isEnabledFor(level: .verbose)) {
            logger.verbose("\(self.request)")
        }
    }
}

// MARK: -
extension RTMPTSocket: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        OSAtomicAdd64(bytesSent, &totalBytesOut)
    }
}
