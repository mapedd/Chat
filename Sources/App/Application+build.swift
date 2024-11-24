import Hummingbird
import Foundation
import Logging
import AsyncAlgorithms
import Elementary
import HummingbirdElementary

struct MessageContext: ChildRequestContext {
  var coreContext: CoreRequestContextStorage
  
  
  init(context: AppRequestContext) throws {
    self.coreContext = context.coreContext
    // if user identity doesn't exist then throw an unauthorized HTTP error
    
  }
  
  var requestDecoder: MessageRequestDecoder {
    MessageRequestDecoder()
  }
}

struct MessageRequest: Decodable {
  var message: String
}

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
  var hostname: String { get }
  var port: Int { get }
  var logLevel: Logger.Level? { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
  let environment = Environment()
  let logger = {
    var logger = Logger(label: "Chat")
    logger.logLevel =
    arguments.logLevel ??
    environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
      .info
    return logger
  }()
  let router = buildRouter()
  let app = Application(
    router: router,
    configuration: .init(
      address: .hostname(arguments.hostname, port: arguments.port),
      serverName: "Chat"
    ),
    logger: logger
  )
  return app
}

struct MessageModel {
  var sender: String
  var text: String
  let date = Date()
  
  var dateFormatted: String {
    date.formatted(date: .omitted, time: .shortened)
  }
}

actor ChatEngine {
  var messages: [MessageModel] = []
  func addMessage(_ message: MessageModel) {
    messages.append(message)
    continuations.forEach {
      $0.yield(message)
    }
  }
  
  var continuations: [AsyncStream<MessageModel>.Continuation] = []
  
  var messageStream: AsyncStream<MessageModel> {
    
    let stream:AsyncStream<MessageModel> = .init
    {
      continuations.append($0)
    }
    
    return stream
  }
}

/// Build router
///
func buildRouter() -> Router<AppRequestContext> {
  let router = Router(context: AppRequestContext.self)
  // Add middleware
  
  
  let assetsURL = Bundle.module.resourcePath!.appending("/Public")
  
  router.addMiddleware {
    // logging middleware
    LogRequestsMiddleware(.info)
    FileMiddleware(assetsURL, searchForIndexHtml: false)
  }
  // Add default endpoint
  router.get("/") { _,_ in
    HTMLResponse {
      Index(title: "Hello")
    }
  }
  router
    .group()
    .group(context: MessageContext.self)
    .post("/send", use: message)
  
  router.get("/messages") { _, _ in
    Response(
      status: .ok,
      headers: [.contentType: "text/event-stream"],
      body: .init { writer in
        for await message in await chatEngine.messageStream.cancelOnGracefulShutdown() {
          try await writer.writeSSE(html: Message(model: message))
        }
        try await writer.finish(nil)
      }
    )
  }
  return router
}


let chatEngine = ChatEngine()

@Sendable func message(_ request: Request, context: MessageContext) async throws -> HTTPResponse.Status {
  let messageRequest = try await request.decode(as: MessageRequest.self, context: context)
  let model: MessageModel = .init(
    sender: "Tomek",
    text: messageRequest.message
  )
  await chatEngine.addMessage(
    model
  )
  return .ok
}

extension ResponseBodyWriter {
  mutating func writeSSE(event: String? = nil, html: some HTML) async throws {
    if let event {
      try await write(ByteBuffer(string: "event: \(event)\n"))
    }
    try await write(ByteBuffer(string: "data: "))
    try await writeHTML(html)
    try await write(ByteBuffer(string: "\n\n"))
  }
}


struct MessageRequestDecoder: RequestDecoder {
  func decode<T>(_ type: T.Type, from request: Request, context: some RequestContext) async throws -> T where T: Decodable {
    /// if no content-type header exists or it is an unknown content-type return bad request
    guard let header = request.headers[.contentType] else { throw HTTPError(.badRequest) }
    guard let mediaType = MediaType(from: header) else { throw HTTPError(.badRequest) }
    switch mediaType {
    case .applicationJson:
      return try await JSONDecoder().decode(type, from: request, context: context)
    case .applicationUrlEncoded:
      return try await URLEncodedFormDecoder().decode(type, from: request, context: context)
    default:
      throw HTTPError(.badRequest)
    }
  }
}
