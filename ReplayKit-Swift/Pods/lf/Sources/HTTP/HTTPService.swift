import Foundation

enum HTTPVersion: String {
    case version10 = "HTTP/1.0"
    case version11 = "HTTP/1.1"
}

extension HTTPVersion: CustomStringConvertible {
    // MARK: CustomStringConvertible
    var description:String {
        return rawValue
    }
}

// MARK: -
enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case delete  = "DELETE"
    case head    = "HEAD"
    case options = "OPTIONS"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

// MARK: -
enum HTTPStatusCode: Int {
    case `continue`                   = 100
    case switchingProtocols           = 101
    case ok                           = 200
    case created                      = 201
    case accepted                     = 202
    case nonAuthoritative             = 203
    case noContent                    = 204
    case resetContent                 = 205
    case partialContent               = 206
    case multipleChoices              = 300
    case movedParmanently             = 301
    case found                        = 302
    case seeOther                     = 303
    case notModified                  = 304
    case useProxy                     = 305
    case temporaryRedirect	          = 307
    case badRequest                   = 400
    case unauthorixed                 = 401
    case paymentRequired              = 402
    case forbidden                    = 403
    case notFound                     = 404
    case methodNotAllowed             = 405
    case notAcceptable                = 406
    case proxyAuthenticationRequired  = 407
    case requestTimeOut               = 408
    case conflict                     = 409
    case gone                         = 410
    case lengthRequired               = 411
    case preconditionFailed	          = 412
    case requestEntityTooLarge        = 413
    case requestURITooLarge           = 414
    case unsupportedMediaType         = 415
    case requestedRangeNotSatisfiable = 416
    case expectationFailed            = 417
    case internalServerError          = 500
    case notImplemented               = 501
    case badGateway                   = 502
    case serviceUnavailable           = 503
    case gatewayTimeOut               = 504
    case httpVersionNotSupported      = 505

    var message:String {
        switch self {
        case .continue:
            return "Continue"
        case .switchingProtocols:
            return "Switching Protocols"
        case .ok:
            return "OK"
        case .created:
            return "Created"
        case .accepted:
            return "Accepted"
        case .nonAuthoritative:
            return "Non-Authoritative Information"
        case .noContent:
            return "No Content"
        case .resetContent:
            return "Reset Content"
        case .partialContent:
            return "Partial Content"
        case .multipleChoices:
            return "Multiple Choices"
        case .movedParmanently:
            return "Moved Permanently"
        case .found:
            return "Found"
        case .seeOther:
            return "See Other"
        case .notModified:
            return "Not Modified"
        case .useProxy:
            return "Use Proxy"
        case .temporaryRedirect:
            return "Temporary Redirect"
        case .badRequest:
            return "Bad Request"
        case .unauthorixed:
            return "Unauthorixed"
        case .paymentRequired:
            return "Payment Required"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not Found"
        case .methodNotAllowed:
            return "Method Not Allowed"
        case .notAcceptable:
            return "Not"
        case .proxyAuthenticationRequired:
            return "Proxy Authentication Required"
        case .requestTimeOut:
            return "Request Time-out"
        case .conflict:
            return "Conflict"
        case .gone:
            return "Gone"
        case .lengthRequired:
            return "Length Required"
        case .preconditionFailed:
            return "Precondition Failed"
        case .requestEntityTooLarge:
            return "Request Entity Too Large"
        case .requestURITooLarge:
            return "Request-URI Too Large"
        case .unsupportedMediaType:
            return "Unsupported Media Type"
        case .requestedRangeNotSatisfiable:
            return "Requested range not satisfiable"
        case .expectationFailed:
            return "Expectation Failed"
        case .internalServerError:
            return "Internal Server Error"
        case .notImplemented:
            return "Not Implemented"
        case .badGateway:
            return "Bad Gateway"
        case .serviceUnavailable:
            return "Service Unavailable"
        case .gatewayTimeOut:
            return "Gateway Time-out"
        case .httpVersionNotSupported:
            return "HTTP Version not supported"
        }
    }
}

extension HTTPStatusCode: CustomStringConvertible {
    // MARK: CustomStringConvertible
    var description:String {
        return "\(rawValue) \(message)"
    }
}

// MARK: -
open class HTTPService: NetService {
    static open let type:String = "_http._tcp"
    static open let defaultPort:Int32 = 8080
    static open let defaultDocument:String = "<!DOCTYPE html><html><head><meta charset=\"UTF-8\" /><title>lf</title></head><body>lf</body></html>"

    var document:String = HTTPService.defaultDocument
    fileprivate(set) var streams:[HTTPStream] = []

    open func addHTTPStream(_ stream:HTTPStream) {
        for i in 0..<streams.count {
            if (stream.name == streams[i].name) {
                return
            }
        }
        streams.append(stream)
    }

    open func removeHTTPStream(_ stream:HTTPStream) {
        for i in 0..<streams.count {
            if (stream.name == streams[i].name) {
                streams.remove(at: i)
                return
            }
        }
    }

    func get(_ request:HTTPRequest, client:NetClient) {
        logger.verbose("\(request)")
        var response:HTTPResponse = HTTPResponse()

        // #141
        response.headerFields["Access-Control-Allow-Headers"] = "*"
        response.headerFields["Access-Control-Allow-Methods"] = "GET,HEAD,OPTIONS"
        response.headerFields["Access-Control-Allow-Origin"] = "*"
        response.headerFields["Access-Control-Expose-Headers"] = "*"

        response.headerFields["Connection"] = "close"

        defer {
            logger.verbose("\(response)")
            disconnect(client)
        }

        switch request.uri {
        case "/":
            response.headerFields["Content-Type"] = "text/html"
            response.body = [UInt8](document.utf8)
            client.doOutput(bytes: response.bytes)
        default:
            for stream in streams {
                guard let (mime, resource) = stream.getResource(request.uri) else {
                    break
                }
                response.statusCode = HTTPStatusCode.ok.description
                response.headerFields["Content-Type"] = mime.rawValue
                switch mime {
                case .VideoMP2T:
                    if let info:[FileAttributeKey:Any] = try? FileManager.default.attributesOfItem(atPath: resource) {
                        if let length:Any = info[FileAttributeKey.size] {
                            response.headerFields["Content-Length"] = String(describing: length)
                        }
                    }
                    client.doOutput(bytes: response.bytes)
                    client.doOutputFromURL(URL(fileURLWithPath: resource), length: 8 * 1024)
                default:
                    response.statusCode = HTTPStatusCode.ok.description
                    response.body = [UInt8](resource.utf8)
                    client.doOutput(bytes: response.bytes)
                }
                return
            }
            response.statusCode = HTTPStatusCode.notFound.description
            client.doOutput(bytes: response.bytes)
        }
    }

    func client(inputBuffer client:NetClient) {
        guard let request:HTTPRequest = HTTPRequest(bytes: client.inputBuffer) else {
            disconnect(client)
            return
        }
        client.inputBuffer.removeAll()
        switch request.method {
        case "GET":
            get(request, client: client)
        default:
            break
        }
    }
}
