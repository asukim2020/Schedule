//
//  VCCalendarMonthPage.swift
//  Schedule
//
//  Created by Asu on 2020/09/07.
//  Copyright © 2020 Asu. All rights reserved.
//

import UIKit

class VCCalendarMonthPage: UIPageViewController {
    
    weak var touchDelegate: CalendarTouchEventDelegate? = nil
    weak var calendarDelegate: CalendarDelegate? = nil
    
    var isUp: Bool = false {
        didSet {
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: NamesOfNotification.calendarIsUp),
                object: nil,
                userInfo: ["isUp": self.isUp]
            )
        }
    }
    
    override init(
        transitionStyle style: UIPageViewController.TransitionStyle,
        navigationOrientation: UIPageViewController.NavigationOrientation,
        options: [UIPageViewController.OptionsKey : Any]? = nil
    ) {
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: navigationOrientation,
            options: options
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        addObserver()
    }
    
    func setUpUI() {
        delegate = self
        dataSource = self
        
        let date = Date().startOfMonth
        let firstPage = VCCalendarMonth(date: date)
        firstPage.delegate = self
        
        setViewControllers([firstPage], direction: .forward, animated: false, completion: nil)
        
        postTitleNotification(date.LocaledateToString())
    }
    
    // MARK: - Functions
    
    func postTitleNotification(_ title: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: NamesOfNotification.setCalendarTitle),
            object: nil,
            userInfo: ["title": title]
        )
    }
    
    func moveDay(moveDate: Date, isToday: Bool = false) {
        DispatchQueue.main.async {
            guard let vc = (self.viewControllers?[safe: 0] as? VCCalendarMonth) else { return }
            let curDate = vc.getDate()
            guard
                curDate.month != moveDate.month
                || curDate.year != moveDate.year
            else {
                if !isToday {
                    self.touchDelegate?.touchBegin()
                    self.touchDelegate?.touchEnd(diff: 30.0)
                }
                vc.moveDay(moveDate: moveDate)
                self.calendarDelegate?.setDatePickerDate(date: moveDate)
                return
            }
            
            let date = moveDate.startOfMonth
            let firstPage = VCCalendarMonth(date: date)
            firstPage.delegate = self
            firstPage.isUp = true
            firstPage.initSelectedDate = moveDate.startOfDay
            
            if isToday && !self.isUp {
                firstPage.isUp = false
            }
            
            self.postTitleNotification(date.LocaledateToString())
            var direction: NavigationDirection
            var animated: Bool = true
            if self.view.bounds.size.height >= VwCalendar.getMaxCalendarHeight() && !isToday {
                animated = false
                self.touchDelegate?.touchBegin()
                self.touchDelegate?.touchEnd(diff: 30.0)
            }
            
            if curDate < moveDate {
                direction = .forward
            } else {
                direction = .reverse
            }
            self.calendarDelegate?.setDatePickerDate(date: moveDate)
            self.setViewControllers([firstPage], direction: direction, animated: animated, completion: nil)
        }
    }
    
    func addObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceivedAddNotification),
            name: NSNotification.Name(rawValue: NamesOfNotification.refreshCalendar),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceivedMoveCalendarMonth),
            name: NSNotification.Name(rawValue: NamesOfNotification.moveCalendarMonth),
            object: nil
        )
        
    }
    
    @objc func didReceivedAddNotification() {
        viewControllers?[safe: 0]?.viewWillAppear(false)
    }
    
    @objc func didReceivedMoveCalendarMonth(_ notification: Notification) {
        guard let date = notification.userInfo?["date"] as? Date
        else {
                return
        }
        let isToday = notification.userInfo?["isToday"] as? Bool
        moveDay(moveDate: date, isToday: isToday ?? false)
    }
    
    func setDataSource(isOn: Bool) {
        if isOn {
            dataSource = self
        } else {
            dataSource = nil
        }
    }
}

// MARK: - UIPageViewControllerDelegate, UIPageViewControllerDataSource
extension VCCalendarMonthPage: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let vc = viewController as? VCCalendarMonth
            else {
                return nil
        }
        let date = vc.getDate()
        let prevVC = VCCalendarMonth(date: date.prevMonth)
        prevVC.isUp = self.isUp
        prevVC.delegate = self
        return prevVC
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let vc = viewController as? VCCalendarMonth
            else {
                return nil
        }
        let date = vc.getDate()
        let nextVC = VCCalendarMonth(date: date.nextMonth)
        nextVC.isUp = self.isUp
        nextVC.delegate = self
        return nextVC
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard let vc = pageViewController.viewControllers?[safe: 0] as? VCCalendarMonth
        else {
                return
        }
        postTitleNotification(vc.getDate().LocaledateToString())
    }
}


// MARK: - CalendarTouchEventDelegate
extension VCCalendarMonthPage: CalendarTouchEventDelegate {
    
    func touchBegin() {
        touchDelegate?.touchBegin()
        dataSource = nil
    }
    
    func touchMove(diff: CGFloat) {
        touchDelegate?.touchMove(diff: diff)
    }
    
    func touchEnd(diff: CGFloat) {
        touchDelegate?.touchEnd(diff: diff)
        dataSource = self
    }
}
