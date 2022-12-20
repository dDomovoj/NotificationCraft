//
//  DeinitObserver.swift
//
//  Created by dDomovoj on 20/12/2022.
//

import Foundation

private enum OnDeinitKeys {
    static var onDeinit: UInt = 0
}

protocol Deinitable: AnyObject { }
extension NSObject: Deinitable { }

extension Deinitable {

  fileprivate var deinitObserver: DeinitObserver? {
    get { objc_getAssociatedObject(self, &OnDeinitKeys.onDeinit) as? DeinitObserver }
    set { objc_setAssociatedObject(self, &OnDeinitKeys.onDeinit, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  var onDeinit: (() -> Void)? {
    get {
      deinitObserver?.onDeinit
    }
    set {
      if let observer = deinitObserver {
        observer.onDeinit = newValue
      }
      else {
        deinitObserver = .init(newValue)
      }
    }
  }

}

private final class DeinitObserver {

  var onDeinit: (() -> Void)?

  // MARK: - Init

  init(_ block: (() -> Void)?) {
    onDeinit = block
  }

  deinit { onDeinit?() }

}
