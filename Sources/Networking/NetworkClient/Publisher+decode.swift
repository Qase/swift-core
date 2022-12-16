import Combine
import CombineExtensions
import ErrorReporting
import Foundation
import RequestBuilder

public extension Publisher {
  func decode<Item, Coder, DecodeError>(
    type: Item.Type,
    decoder: Coder,
    mapError errorMapper: @escaping (Error) -> DecodeError
  )
  -> AnyPublisher<(headers: [HTTPHeader], object: Item), DecodeError>
  where Item: Decodable,
  Coder: TopLevelDecoder,
  Coder.Input == Data,
  Self.Output == (headers: [HTTPHeader], body: Data),
  Self.Failure == DecodeError {
    let sharedUpstream = share(replay: 1)

    return sharedUpstream.map(\.body)
      .decode(type: Item.self, decoder: decoder)
      .mapError {
        guard let upstreamError = $0 as? DecodeError else {
          return errorMapper($0)
        }

        return upstreamError
      }
      .combineLatest(sharedUpstream.map(\.headers))
      .map { (headers: $1, object: $0) }
      .eraseToAnyPublisher()
  }
}
