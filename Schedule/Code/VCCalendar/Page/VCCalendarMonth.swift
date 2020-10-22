//
//  VCCalendarMonth.swift
//  Schedule
//
//  Created by Asu on 2020/09/06.
//  Copyright © 2020 Asu. All rights reserved.
//

import UIKit
import RealmSwift
import RxCocoa
import RxSwift

protocol CalendarTouchEventDelegate: class {
    func touchBegin()
    func touchMove(diff: CGFloat)
    func touchEnd(diff: CGFloat)
}

class VCCalendarMonth: UIViewController {
    var dayViews: [VwCalendarDay] = []
    private var date = Date()
    private var row: Int = 0
    
    private var beginPoint: CGPoint? = nil
    private var lastPoint: CGPoint? = nil
    
    weak var delegate: CalendarTouchEventDelegate? = nil
    var initSelectedDate: Date? = nil
    var isUp: Bool = false
    var preSelecedDay: VwCalendarDay? = nil
    private var preToday: VwCalendarDay? = nil
    
    convenience init(date: Date) {
        self.init(nibName:nil, bundle:nil)
        self.date = date
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addObserver()
        setUpUI()
        displayUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpData()
        setToday()
        setHoliday()
        setAlternativeHoliday()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if initSelectedDate != nil {
            
            for view in dayViews {
                if view.date == initSelectedDate {
                    preSelecedDay?.deselectedDay()
                    view.selectedDay()
                    preSelecedDay = view
                    loadViewIfNeeded()
                    break
                }
            }
            
            initSelectedDate = nil
        }
        
        if preSelecedDay == nil {
            for view in dayViews {
                if view.label.text ?? "0" == "1" {
                    view.selectedDay()
                    preSelecedDay = view
                    loadViewIfNeeded()
                    break
                }
            }
        } else {
            preSelecedDay?.selectedDay()
        }
        
        setGestrue()
    }
    
    private func setUpUI() {
        let curDate = Date()
        let today = curDate.startOfDay.day
        let month = curDate.month
        let lastDayMonth = date.startOfMonth.month
        
        let weekday = date.startOfMonth.weekday
        let lastDay = date.startOfMonth.endOfMonth.day
        let prevLastDay = date.prevMonth.endOfMonth.day
        
        let remainder = (weekday + lastDay - 1) % 7
        row = ((weekday + lastDay - 1) / 7) + 1
        
        if remainder == 0 {
            row -= 1
        }
        
        for i in 0..<(row * Global.calendarColumn) {
            let dayView = VwCalendarDay(row: row)
            dayView.translatesAutoresizingMaskIntoConstraints = false
            dayViews.append(dayView)
            
            let alpha: CGFloat = 0.4
            // 날짜 setText
            if i + 1 >= weekday {
                // 다음달
                if i+1-weekday >= lastDay {
                    let day = i + 2 - weekday - lastDay
                    dayView.setText(text: "\(day)")
                    dayView.setAlpha(alpha: alpha)
                } else {
                    // 현재달
                    let day = i + 2 - weekday
                    dayView.setText(text: "\(day)")
                    
                    if today == day
                        && month == lastDayMonth
                        && curDate.year == self.date.year {
                        let date = self.date.getNextCountDay(count: day - 1)
                        dayView.date = date
                        dayView.selectedDay()
                        dayView.setTodayView()
                        preToday = dayView
                        preSelecedDay = dayView
                    }
                }
            } else {
                // 이전달
                let day = prevLastDay - weekday + i + 2
                dayView.setText(text: "\(day)")
                dayView.setAlpha(alpha: alpha)
            }
        }
    }
    
    private func displayUI() {
        let dayCount = Global.dayCount
        for row in 0..<row {
            for column in 0..<Global.calendarColumn {
                let dayView = dayViews[(row * dayCount) + column]
                view.addSubview(dayView)
                
                if row == 0 {
                    dayView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                } else {
                    dayView.topAnchor.constraint(equalTo: dayViews[((row - 1) * dayCount) + column].bottomAnchor).isActive = true
                }
                
                if column == 0 {
                    dayView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                } else {
                    dayView.leadingAnchor.constraint(equalTo: dayViews[(row * dayCount) + column - 1].trailingAnchor).isActive = true
                }
                
                dayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0/CGFloat(dayCount)).isActive = true
                dayView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0/CGFloat(self.row)).isActive = true
            }
        }
    }
    
    // MARK: - Functions
    
    func getDate() -> Date {
        return date
    }
    
    @objc func tapDay(sender: UITapGestureRecognizer) {
        guard
            let view = sender.view as? VwCalendarDay,
            let date = view.date
            else { return }
        
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: NamesOfNotification.moveCalendarMonth),
            object: nil,
            userInfo: ["date": date]
        )
    }
    
    func moveDay(moveDate: Date) {
        DispatchQueue.main.async {
            self.preSelecedDay?.deselectedDay()
            
            for view in self.dayViews {
                if view.date?.startOfDay == moveDate.startOfDay {
                    view.selectedDay()
                    self.preSelecedDay = view
                    break
                }
            }
        }
    }
    
    func setUpData() {
        for view in dayViews {
            view.isUp = self.isUp
        }
        
        let weekday = date.startOfMonth.weekday
        let lastDay = date.startOfMonth.endOfMonth.day
        let prevLastDay = date.prevMonth.endOfMonth.day
        var list: [Item]? = nil
        for i in 0..<(row * Global.calendarColumn) {
            if i + 1 >= weekday {
                // 다음달
                if i+1-weekday >= lastDay {
                    let day = i + 1 - weekday - lastDay
                    let nextDate = date.nextMonth.getNextCountDay(count: day)
                    list = Item.getDayList(date: nextDate)
                    dayViews[safe: i]?.date = nextDate
                } else {
                    // 현재달
                    let day = i + 1 - weekday
                    let date = self.date.getNextCountDay(count: day)
                    list = Item.getDayList(date: date)
                    dayViews[safe: i]?.date = date
                }
            } else {
                // 이전달
                let day = prevLastDay - weekday + i + 1
                let count = day - prevLastDay
                let preDate = date.getNextCountDay(count: count)
                list = Item.getDayList(date: preDate)
                dayViews[safe: i]?.date = preDate
            }
            dayViews[safe: i]?.list = list
        }
    }
    
    func setHoliday() {
        guard
            let minDate = dayViews[safe: 0]?.date,
            let maxDate = dayViews[safe: dayViews.count - 1]?.date
        else { return }
        
        let minDay = minDate.dateToMonthDayString()
        let maxDay = maxDate.dateToMonthDayString()
        let holidayKeyList = Holiday.isHoliday(minDay: minDay, maxDay: maxDay)
        let dictionary = Holiday.getHolidayList(stringArray: holidayKeyList)
        
        let lunarMinDay = minDate.dateToLunarString()
        let lunarMaxDay = maxDate.dateToLunarString()
        let lunarHolidayKeyList = Holiday.isHoliday(minDay: lunarMinDay, maxDay: lunarMaxDay, isLunar: true)
        let lunarDictionary = Holiday.getHolidayList(stringArray: lunarHolidayKeyList, isLunar: true)
        
        for view in dayViews {
            var holidayList: [String] = []
            if let date = view.date {
                let dayString = "\(String(format: "%02d", date.month))\(String(format: "%02d", date.day))"
                if let value = dictionary[dayString] {
                    holidayList.append(value)
                }
            }
            view.holidayList = holidayList
        }
        
        guard lunarDictionary.count > 0 else { return }
        for (idx, view) in dayViews.enumerated() {
            var holidayList: [String] = []
            if let date = view.date {
                let dayString = date.dateToLunarString()
                if let value = lunarDictionary[dayString] {
                    holidayList.append(value)
                    view.holidayList = holidayList
                    if value == "설날" {
                        dayViews[safe: idx - 1]?.holidayList = ["설날 연휴"]
                    }
                }
            }
        }
    }
    
    func setAlternativeHoliday() {
        guard
            let minDate = dayViews[safe: 0]?.date,
            let maxDate = dayViews[safe: dayViews.count - 1]?.date
        else { return }
        
        guard let date = Holiday.getAlternativeHolidays(minDate: minDate, maxDate: maxDate) else { return }
        
        let month = date.month
        let day = date.day
        
        for view in dayViews {
            let viewMonth = view.date?.month
            let viewDay = view.date?.day
            
            if month == viewMonth
                && day == viewDay {
                view.holidayList = ["\(Holiday.alternativeHolidays)"]
            }
        }
    }
    
    func setGestrue() {
        for view in dayViews {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapDay(sender:)))
            view.addGestureRecognizer(tap)
        }
    }
    
    // MARK: - Touch Event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        self.beginPoint = touch.location(in: touch.view)
        delegate?.touchBegin()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let beginPoint = self.beginPoint
            else { return }
        
        lastPoint = touch.location(in: touch.view)
        let y = beginPoint.y - lastPoint!.y
        delegate?.touchMove(diff: y)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchEnd()
    }
    
    func touchEnd() {
        guard let beginPoint = self.beginPoint else { return }
        guard let lastPoint = self.lastPoint else { return }
        let y = beginPoint.y - lastPoint.y
        delegate?.touchEnd(diff: y)
        self.beginPoint = nil
    }
    
    // MARK: - Observer
    func addObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setTodayNotification),
            name: NSNotification.Name(rawValue: NamesOfNotification.setToday),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setIsUp),
            name: NSNotification.Name(rawValue: NamesOfNotification.calendarIsUp),
            object: nil
        )
    }
    
    @objc func setTodayNotification() {
        setToday()
    }
    
    func setToday() {
        let today = Date()
        let todayFlag = (today.startOfMonth == self.date.startOfMonth)
        let todayCount = today.day
        
        guard todayFlag else { return }
        
        for view in dayViews {
            if todayCount == Int(view.label.text ?? "0") {
                preToday?.removeTodayView()
                view.setTodayView()
                preToday = view
                loadViewIfNeeded()
                break
            } else {
                view.todayFlag = false
            }
        }
    }
    
    @objc func setIsUp(_ notification: Notification) {
        guard let isUp = notification.userInfo?["isUp"] as? Bool
        else {
                return
        }
        
        self.isUp = isUp
    }
}
