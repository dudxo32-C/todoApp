//
//  MainViewModel.swift
//  todoApp
//
//  Created by 조영태 on 2022/10/03.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift
import RealmSwift

enum ToDoListError: Error {
    case noItems
}

class MainViewModel: ViewModelProtocol {
    struct Input {
        //        let click:PublishRelay<Void>
    }
    struct Output {
        let isFetching: Driver<Bool>
        let items: Driver<[TodoModelProtocol]>
        let error: Driver<Error?>
    }

    var input: Input
    let output: Output

    var disposeBag = DisposeBag()
    let repo = TodoRepo(dataSource: MockTodoDS())

    private let fetchRelay = BehaviorRelay(value: false)
    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    private let itemsRelay = BehaviorRelay<[TodoModelProtocol]>(value: [])
    init() {
        self.input = Input()

        self.output = Output(
            isFetching: self.fetchRelay.asDriver(),
            items: itemsRelay.asDriver(),
            error: errorRelay.asDriver()
        )

        fetch()

    }

    func fetch() {
        
//        try! Realm().write {
//            
//            try Realm().add(TodoRealm(title: "title", date: Date(), contents: "contents"))
//        }
//        
//        print(Realm.Configuration.defaultConfiguration.fileURL?.absoluteString ?? "")
        Task {
            self.fetchRelay.accept(true)

            do {
                let response = try await repo.fetchTodoList()
                if response.isEmpty {
                    self.errorRelay.accept(ToDoListError.noItems)
                } else {
                    self.errorRelay.accept(nil)
                    self.itemsRelay.accept(response)
                }
            } catch {
                print(error)
//                self.errorRelay.accept(ToDoListError.noItems)
                self.errorRelay.accept(error)
            }

            self.fetchRelay.accept(false)
        }
    }
    
    func createTodoListItem(todo:TodoModelProtocol) {
        let arr = self.itemsRelay.value + [todo]
        self.itemsRelay.accept(arr)
    }
}
