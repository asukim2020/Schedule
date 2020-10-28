//
//  File.swift
//  Schedule
//
//  Created by Asu on 2020/09/11.
//  Copyright © 2020 Asu. All rights reserved.
//

import RealmSwift
import RxCocoa
import RxSwift

@objcMembers class Item: Object {
    
    // 생성 시간
    dynamic var key: Int64 = -1
    
    // 제목
    dynamic var title: String = ""
    
    // 시작 날짜
    dynamic var startDate: TimeInterval = 0.0
    
    // 종료 날짜
    dynamic var endDate: TimeInterval = 0.0
    
    // TODO: - 시작 시간, 종료 시간 지정 시 startTime, endTime 인자 추가 할 것
    
    override static func primaryKey() -> String? {
        return "key"
    }
    
    // MARK: - funcsion
    static func add(
        item: Item,
        title: String,
        startDate: Date,
        endDate: Date
    ) -> Observable<Item> {
        // TODO: - 여러 인자 추가 시, 추가 반영
        return Observable.create { observer in
            do {
                let realm = try Realm()
                if item.key == -1 {
                    item.key = Int64(Date().timeIntervalSince1970 * 1000)
                }
                
                try realm.write {
                    item.title = title
                    item.startDate = startDate.startOfDay.timeIntervalSince1970
                    item.endDate = endDate.endOfDay.timeIntervalSince1970
                    realm.add(item, update: .all)
                    try realm.commitWrite()
                    observer.on(.next(item))
                    observer.on(.completed)
                }
                
            } catch {
                observer.on(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
//    static func getDayList(
//        date: Date
//    ) -> [Item]? {
//        do {
//            let startOfDay = date.startOfDay.timeIntervalSince1970
//            let endOfDay = date.endOfDay.timeIntervalSince1970
//
//            let realm = try Realm()
//            let startIncludeList = realm.objects(Item.self).filter(
//                "%@ <= startDate AND startDate <= %@",
//                startOfDay,
//                endOfDay
//            )
//
//            let endIncludeList = realm.objects(Item.self).filter(
//                "%@ <= endDate AND endDate <= %@",
//                startOfDay,
//                endOfDay
//            )
//
//            if startIncludeList.count == 0
//                && endIncludeList.count == 0 {
//                return nil
//            }
//
//            var itemList: [Item] = []
//            itemList.append(contentsOf: startIncludeList)
//            itemList.append(contentsOf: endIncludeList)
//            return Array(Set(itemList)).sorted(by: {($0.endDate - $0.startDate) > ($1.endDate - $1.startDate)})
//        } catch {
//            return nil
//        }
//    }

    static func getDayList(
        date: Date
    ) -> [Item]? {
        do {
            let startOfDay = date.startOfDay.timeIntervalSince1970
            let realm = try Realm()
            let list = realm.objects(Item.self).filter(
                "startDate <= %@ AND %@ <= endDate",
                startOfDay,
                startOfDay
            )
            
            if list.count == 0 {
                return nil
            }

            return list.sorted(by: {($0.endDate - $0.startDate) > ($1.endDate - $1.startDate)})
        } catch {
            return nil
        }
    }
    
    func remove() -> Observable<Bool> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                
                try realm.write {
                    if self.isInvalidated == false {
                        realm.delete(self)
                        observer.on(.next(true))
                    } else {
                        observer.on(.next(false))
                    }
                    observer.on(.completed)
                }
                
            } catch {
                observer.on(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    static func removeAll() -> Observable<Results<Item>> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let items = realm.objects(Item.self)
                
                try realm.write {
                    realm.delete(items)
                    observer.on(.next(items))
                    observer.on(.completed)
                }
                
            } catch {
                observer.on(.error(error))
            }
            
            return Disposables.create()
        }
    }
}
