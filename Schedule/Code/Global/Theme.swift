//
//  Theme.swift
//  Schedule
//
//  Created by Asu on 2020/09/05.
//  Copyright © 2020 Asu. All rights reserved.
//

import UIKit

class Theme {
    
    static var isDarkMode: Bool = {
        UITraitCollection.current.userInterfaceStyle == .dark
    }()
    
    static var bar: UIColor = {
        (isDarkMode ? UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1) : .white)
    }()
    
    static var font: UIColor = {
        isDarkMode ? UIColor(hexString: "#FAFAFA") : UIColor(hexString: "#202020")
    }()

    // TODO: - 색상보고 변경할 것
    static var lightFont: UIColor = {
        isDarkMode ? .lightGray : .lightGray
    }()
    
    static var background: UIColor = {
        isDarkMode ? UIColor(hexString: "#202020") : UIColor(hexString: "#FAFAFA")
    }()
    
    static var accent: UIColor = {
        isDarkMode ? UIColor(hexString: "#FAFAFA") : UIColor(hexString: "#202020")
    }()
//        UIColor(red: 0, green: 0.48, blue: 1, alpha: 1)
    
    static var separator: UIColor = UIColor.lightGray.withAlphaComponent(0.3)
    static var sunday: UIColor = UIColor.init(hexString: "#dc143c")
    static var saturday: UIColor = UIColor.init(hexString: "#4169E1")
    
    static var item: UIColor = UIColor.init(hexString: "#4169E1")
    static var today: UIColor = UIColor.init(hexString: "#3CB371")
    
    static var subViewBackground = UIColor(hexString: "#E8EAF6")
    static var hideViewColor = UIColor(hexString: "#ECEFF1")
}
