//
//  TodoDetailViewModel.swift
//  todoApp
//
//  Created by 조영태 on 3/17/25.
//

import Foundation
import RxCocoa
import RxSwift

enum TodoUpdateError: Error {
    case error
}

class TodoDetailViewModel: ViewModelProtocol {
    struct Input {
        let title: BehaviorRelay<String?>
        let date: BehaviorRelay<Date?>
        let contents: BehaviorRelay<String?>
        let doEdit: PublishRelay<Void>
        
    }
    
    struct Output {
        let writtenTodo: Driver<TodoModel?>
        let updatedError: Driver<TodoUpdateError?>
    }
    
    let input: Input
    
    private let todoID: String?
    private let writeTodoRealy: BehaviorRelay<TodoModel?>
    private let updatedErrorRealy: BehaviorRelay<TodoUpdateError?>
    
    let output: Output
    
    var disposeBag = DisposeBag()
    
    let repo = TodoRepo(MockTodoDS())
    
    //    private let tempTodo: BehaviorRelay<TodoModel?>
    
    init(`protocol`: TodoModelProtocol?) {
        self.todoID = `protocol`?.id
        self.input = Input(
            title: .init(value: `protocol`?.title),
            date: .init(value: `protocol`?.date),
            contents: .init(value: `protocol`?.contents),
            doEdit: .init()
        )
        
        // init ouput
        self.writeTodoRealy = .init(value: nil)
        self.updatedErrorRealy = .init(value: nil)
        self.output = Output(
            writtenTodo: writeTodoRealy.asDriver(),
            updatedError: updatedErrorRealy.asDriver()
        )
        
        // bind
        //        self.bindTextInput()
        
        self.bindDoEdit()
    }
    //    private func getTempTodo() -> TodoModel {
    //        return self.tempTodo.value
    //    }
    
    //    private func bindTextInput() {
    //        self.input.title.bind { [weak self] title in
    //            guard let self = self else { return }
    //            if let newTodo = self.tempTodo.value?.copyWith(title: title) {
    //                self.tempTodo.accept(newTodo)
    //            }
    //
    //        }.disposed(by: self.disposeBag)
    //
    //        self.input.date.bind { [weak self] date in
    //            guard let self = self else { return }
    //            let newTodo = self.tempTodo.value.copyWith(date: date)
    //            self.tempTodo.accept(newTodo)
    //        }.disposed(by: self.disposeBag)
    //
    //        self.input.contents.bind { [weak self] contents in
    //            guard let self = self else { return }
    //            let newTodo = self.tempTodo.value.copyWith(contents: contents)
    //            self.tempTodo.accept(newTodo)
    //        }.disposed(by: self.disposeBag)
    //    }
    
    private func bindDoEdit() {
        self.input.doEdit.bind { _ in
            print(self.input.title.value)
        }.disposed(by: disposeBag)
        
//        self.input.doEdit.flatMap { self.editTodo() }.asSingle()
//            .subscribe { event in
//                switch event {
//                case .success(let value):
//                    
//                    self.writeTodoRealy.accept(value)
//                case .failure(let error):
//                    self.updatedErrorRealy.accept(TodoUpdateError.error)
//                }
//            }
//            .disposed(by: disposeBag)
    }
    
    private func editTodo() -> Single<TodoModel> {
        return Single.create { [weak self] single in
            
            if let self = self,
               let id = self.todoID,
               let title = self.input.title.value,
               let date = self.input.date.value,
               let contents = self.input.contents.value
            {
                
                Task {
                    do {
                        let todo = TodoModel(id: id, title: title, date: date, contents: contents)
                        let response = try await self.repo.updateTodo(todo: todo)
                        
                        single(.success(TodoModel(response)))
                        
                    } catch {
                        single(.failure(error))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    private func createTodo() -> Single<TodoModel> {
        return Single.create { [weak self] single in
            if let self = self,
               let title = self.input.title.value,
               let date = self.input.date.value,
               let contents = self.input.contents.value
            {
                
                Task {
                    do {
                        let response = try await self.repo.writeTodo(title: title, contents: contents, date: date)
                        
                        single(.success(TodoModel(response)))
                        
                    } catch {
                        single(.failure(error))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
