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
    
    private var dateList: [[Item]?] = []
    private var holidayList: [TimeInterval] = []
    
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
        sentToDataList()
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
        
        let weekday = date.startOfMonth.weekday == 0 ? 7 : date.startOfMonth.weekday
        
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
            dayView.vcMonthCalendar = self
            dayViews.append(dayView)
            
            let alpha: CGFloat = 0.5
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
        dateList.removeAll()
        for view in dayViews {
            view.isUp = self.isUp
        }
        
        let weekday = date.startOfMonth.weekday == 0 ? 7 : date.startOfMonth.weekday
        
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
                    if date.month == 8 && date.day == 15 {
                        print("idx: \(day), date: \(date)")
                    }
                }
            } else {
                // 이전달
                let day = prevLastDay - weekday + i + 1
                let count = day - prevLastDay
                let preDate = date.getNextCountDay(count: count)
                list = Item.getDayList(date: preDate)
                dayViews[safe: i]?.date = preDate
            }
//            dayViews[safe: i]?.list = list
            dateList.append(list)
        }
    }
    
    func setHoliday() {
        guard
            let minDate = dayViews[safe: 0]?.date,
            let maxDate = dayViews[safe: dayViews.count - 1]?.date
        else { return }
        self.holidayList.removeAll()
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
                let dayString = date.dateToMonthDayString()
                if let value = dictionary[dayString] {
                    holidayList.append(value)
                    self.holidayList.append(date.startOfDay.timeIntervalSince1970)
                    print("\(value), date: \(date)")
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
                    self.holidayList.append(date.startOfDay.timeIntervalSince1970)
                    view.holidayList = holidayList
                    print("\(value), date: \(date)")
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
                self.holidayList.append(date.startOfDay.timeIntervalSince1970)
                view.holidayList = ["\(Holiday.alternativeHolidays)"]
                print("\(Holiday.alternativeHolidays), date: \(date)")
            }
        }
    }
    
    // 공휴일과 이틀이상 이벤트가 겹치는 경우
    // 이틀이상 이벤트를 한칸 밑으로 옮기는 함수
    // + 각 일간 뷰에 list를 넣어줌
    func sentToDataList() {
        let column = Global.calendarColumn
        for i in 0 ..< row {
            guard
                let startDate = dayViews[i * column].date,
                let endDate = dayViews[i * column + (column - 1)].date
            else { return }
            
            var proirityList: [Item] = []
            let startTime = startDate.timeIntervalSince1970
            let endTime = endDate.timeIntervalSince1970
            
            let holidayList = self.holidayList.filter { (time) -> Bool in
                startTime <= time && time <= endTime
            }

            if holidayList.count > 0 {
                var dateList: [Item] = []
                
                for j in 0 ..< column {
                    if let list = self.dateList[(i * column) + j] {
                        dateList.append(contentsOf: list)
                    }
                }
                dateList = Array(Set(dateList))
                proirityList = dateList.filter { (item) -> Bool in
                    for time in holidayList {
                        if item.startDate <= time && time <= item.endDate {
                            return true
                        }
                    }
                    
                    return false
                }
            }
            
            for j in 0 ..< column {
                guard proirityList.count > 0,
                      var list = self.dateList[(i * column) + j],
                      let time = dayViews[(i * column) + j].date?.startOfDay.timeIntervalSince1970,
                      !holidayList.contains(time)
                      else {
                    dayViews[(i * column) + j].list = self.dateList[(i * column) + j]
                    continue
                }
                var removeIdxList: [Int] = []
                var removeItemList: [Item] = []
                
                for (idx, item) in list.enumerated() {
                    for proirityItem in proirityList {
                        if item.key == proirityItem.key {
                            removeIdxList.append(idx)
                        }
                    }
                }
                
                removeIdxList = removeIdxList.sorted(by: {$0 > $1})
                for idx in removeIdxList {
                    removeItemList.append(list.remove(at: idx))
                }
                
                if list.count == 0 {
                    list.append(Item())
                }
                
                for removeItem in removeItemList {
                    list.insert(removeItem, at: 1)
                }
                
                dayViews[(i * column) + j].list = list
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
        let month = today.month
        let todayFlag = (today.startOfMonth == self.date.startOfMonth)
        let todayCount = today.day
        
        guard todayFlag else { return }
        
        for view in dayViews {
            if todayCount == Int(view.label.text ?? "0")
                && month == view.date?.month {
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
