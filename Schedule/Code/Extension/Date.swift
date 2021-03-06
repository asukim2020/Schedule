//
//  Date.swift
//  Schedule
//
//  Created by Asu on 2020/09/06.
//  Copyright © 2020 Asu. All rights reserved.
//

import Foundation

extension Date {
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
         return Calendar.current.component(.month, from: self)
    }
    
    var day: Int {
         return Calendar.current.component(.day, from: self)
    }
    
    var prevDay: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self.startOfDay)!
    }
    
    var nextDay: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay)!
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    // 0: 토요일, 1: 일요일 ... 6: 금요일
    var weekday: Int {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.weekday], from: self)

        if let weekday = comps.weekday {
            return (weekday % 7)
        } else {
            return -1
        }
    }
    
    var startOfWeek: Date {
            let date = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
            let dslTimeOffset = NSTimeZone.local.daylightSavingTimeOffset(for: date)
            return date.addingTimeInterval(dslTimeOffset)
        }

        var endOfWeek: Date {
            return Calendar.current.date(byAdding: .second, value: 604799, to: self.startOfWeek)!
        }
    
    var startOfMonth: Date {
        let from = Calendar.current.startOfDay(for: self)
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: from)
        return Calendar.current.date(from: dateComponents)!
    }

    var endOfMonth: Date {
        let dateComponents = DateComponents(month: 1, day: -1)
        return Calendar.current.date(
            byAdding: dateComponents,
            to: self.startOfMonth)!
    }
    
    var nextMonth: Date {
        let dateComponents = DateComponents(month: 1, day: 0)
        return Calendar.current.date(
            byAdding: dateComponents,
            to: self.startOfMonth)!
    }
    
    var prevMonth: Date {
        let dateComponents = DateComponents(month: -1, day: 0)
        return Calendar.current.date(
            byAdding: dateComponents,
            to: self.startOfMonth)!
    }
    
    func getNextCountDay(count: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: count, to: self.startOfDay)!
    }
    
    func dateToString() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy.MM"
        return format.string(from: self)
    }
    
    func dateToMonthDayString() -> String {
        let format = DateFormatter()
        format.dateFormat = "MMdd"
        return format.string(from: self)
    }
    
    func dateToLunarString() -> String {
        let dateFormatter = DateFormatter()

        dateFormatter.calendar = Calendar(identifier: .chinese)
        dateFormatter.dateFormat = "MMdd"
        return dateFormatter.string(from: self)
    }
    
    func LocaledateToString() -> String {
        let dateFormatter = DateFormatter()
        let locale = Locale.current.languageCode ?? "ko"
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: locale)

        let month = calendar.monthSymbols[self.month - 1]
        if locale == "ko" {
            dateFormatter.dateFormat = "yyyy년 \(month)"
        } else {
            dateFormatter.dateFormat = "\(month) yyyy"
        }
        return dateFormatter.string(from: self)
    }
    
    func LocaleYYYYMMDDToString() -> String {
        let dateFormatter = DateFormatter()
        let locale = Locale.current.languageCode ?? "ko"
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: locale)

        let month = calendar.monthSymbols[self.month - 1]
        
        let idx = self.weekday > 0 ? self.weekday - 1 : 6
        let weekday = calendar.shortWeekdaySymbols[idx]

        if locale == "ko" {
            dateFormatter.dateFormat = "yyyy년 \(month) \(self.day)일 (\(weekday))"
        } else {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
        }
        return dateFormatter.string(from: self)
    }
}
