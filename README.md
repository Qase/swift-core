# Core

The package contains various infrastructure-level libraries.
Such libraries are designed to simplify iOS development by providing generally re-occuring functionalities.

### CombineExtensions

Provides additional operators and functions for the Apple's [Combine framework](https://developer.apple.com/documentation/combine).  

### Utils

Provides generally useful extensions, functions and types.

### CoreDatabase

Provides a reactive layer over Apple's [CoreData framework](https://developer.apple.com/documentation/coredata). It also provides an ability to map CoreData's class-type entities to much safer struct-type entities.  

### ErrorReporting

Provides the `ErrorReporting` protocol that custom errors can conform in order to improve error-handling solution within an application. 

By conforming the `ErrorReporting` protocol, each error becomes a part of a linked list. If using a multi-layer application architecture, each error origins at some place and might be further modified while travelling through individual layers of the architecture. An error at each level may be traversed all the way to the error origin by using its `underlyingError` property.

Each linked list of errors represents a single error travelling from its origin all the way to where it is presented to a user. Such linked list of errors is identified by `stackID` property of the `ErrorReporting` protocol. 

`ErrorReporting` additionaly requires each error to conform to `Equatable` protocol. 

### KeyValueStorage

Provides an abstraction for any key-value storage implementation. Currently it also provides built-in implementations for `UserDefaults` and `Keychain`.

### ModelConvertible

Provides a tool helping to implement any custom type-to-type conversion logic.
 
### Networking

Provides tools enabling any REST API network communication. 

- `NetworkClient` can be used for simple non-authorized network communication.
- `AuthorizedNetworkClient` further builds on top of `NetworkClient` to additionaly provide an authorization layer. Using an instance of `TokenClient`, the `AuthorizedNetworkClient` is able to validate and further refresh tokens provided for a request. The `AuthorizedNetworkClinet` is also responsible for queuing token refreshing jobs if multiple requests require to refresh a token at the same time.
 
## NetworkMonitoring

Provides a Combine-like tool to observe the internet connection of a device. 

### RequestBuilder

Provides `Request`, a tool for constructing instances of `URLRequest` in a declarative way. The `Request` is implemented using the `@resultBuilder` technique.  



