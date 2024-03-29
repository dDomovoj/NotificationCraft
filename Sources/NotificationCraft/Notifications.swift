//
//  Notifications.swift
//
//  Created by dDomovoj on 6/14/22.
//

import Foundation

public enum NotificationName {
  case string(String)
  case notification(Foundation.Notification.Name)
}
public protocol INotification {
  
  associatedtype Data
  
  static var name: NotificationName { get }
  static var userInfoKey: String? { get }
  
}

public final class RegisteredNotification {
  
  let token: NSObjectProtocol
  fileprivate let center: NotificationCenter
  fileprivate let name: Foundation.Notification.Name
  fileprivate var unmanaged: Unmanaged<RegisteredNotification>?
  fileprivate var isBinded = false
  
  // MARK: - Init
  
  fileprivate init(token: NSObjectProtocol, center: NotificationCenter, name: NSNotification.Name) {
    self.token = token
    self.center = center
    self.name = name
  }
  
  deinit {
    center.removeObserver(token, name: name, object: nil)
  }
  
  // MARK: - Public
  
  public func bind(to object: NSObject) {
    if unmanaged != nil { return }
    
    unmanaged = .passRetained(self)
    object.onDeinit = { [weak self] in
      guard let self = self else { return }
      
      self.unmanaged?.release()
      self.unmanaged = nil
    }
  }
  
}

// MARK: - Public

public extension INotification {
  
  private static var center: NotificationCenter { .default }
  private static var _name: Foundation.Notification.Name {
    switch name {
    case .notification(let name): return name
    case .string(let name): return .init(name)
    }
  }
  
  static var name: NotificationName { .string("notification.\(self)") }
  static var userInfoKey: String? { "data" }
  
  static func post(_ data: Data) {
    let userInfo: [AnyHashable: Any]? = userInfoKey.map { [$0: data] }
    center.post(name: _name, object: nil, userInfo: userInfo)
  }
  
  static func observe(on queue: OperationQueue? = nil,
                      block: @escaping (Data) -> Void) -> RegisteredNotification {
    let queue = queue ?? .current
    let token = center.addObserver(forName: _name, object: nil, queue: queue) { notification in
      if Data.self == Void.self,
         let data = Void() as? Data {
        block(data)
        return
      }
      
      guard let key = userInfoKey,
            let data = notification.userInfo?[key] as? Data else { return }
      
      block(data)
    }
    let result = RegisteredNotification(token: token, center: center, name: _name)
    return result
  }
  
}

public extension INotification where Data == Void {
  
  static var userInfoKey: String? { nil }
  
  static func post() {
    center.post(name: _name, object: nil, userInfo: nil)
  }
  
}
