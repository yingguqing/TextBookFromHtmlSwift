//
//  YyNotification.swift
//  TextBookFromHtml
//
//  Created by 影孤清 on 2017/6/12.
//  Copyright © 2017年 影孤清. All rights reserved.
//

import Cocoa

// Notification的扩展类,

public protocol Notifier {//给这个协议增加一个关联类型
    associatedtype Notification: RawRepresentable
}

public extension Notifier where Notification.RawValue == String {
    private static func nameFor(notification: Notification) -> String {
        return "\(self).\(notification.rawValue)"
    }
    
    private func postNotification(notification: Notification, object: AnyObject? = nil) {
        self.postNotification(notification: notification, object: object)
    }
    
    private func postNotification(notification: Notification, object: AnyObject? = nil, userInfo: [String : AnyObject]? = nil) {
        self.postNotification(notification: notification, object: object, userInfo: userInfo)
    }
    
    static func postNotification(notification: Notification, object: AnyObject? = nil, userInfo: [AnyHashable : Any]? = nil) {
        let name = nameFor(notification: notification)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: name), object: object, userInfo: userInfo)
    }
    
    // Add
    static func addObserver(observer: AnyObject, selector: Selector, notification: Notification) {
        let name = nameFor(notification: notification)
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: name), object: nil)
    }
    
    // Remove
    static func removeObserver(observer: AnyObject, notification: Notification, object: AnyObject? = nil) {
        let name = nameFor(notification: notification)
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: name), object: object)
    }
}

class YNotification: Notifier {
    enum Notification : String {
        case reloadRuleFileData// 重新获取规则数据
    }
}
