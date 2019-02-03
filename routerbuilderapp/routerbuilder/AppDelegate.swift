//
//  AppDelegate.swift
//  routerbuilder
//
//  Created by DianQK on 2019/2/11.
//  Copyright © 2019 DianQK. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard
            let viewControllerClassName = url.host,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems,
            let viewController = routes[viewControllerClassName]?(queryItems) else { // TODO: 参数校验
            return false
        }
        window?.rootViewController = viewController
        return true
    }

}

