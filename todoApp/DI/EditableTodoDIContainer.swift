//
//  File.swift
//  todoApp
//
//  Created by 조영태 on 4/8/25.
//

import Foundation
import Swinject

class EditableTodoDIContainer {
    private let container: Container
    private let assembler: Assembler

    init(parentContainer: Container? = nil) {
        self.container = Container(parent: parentContainer)

        self.assembler = Assembler(
            [TodoEditableAssembly()],
            container: self.container
        )
    }

    func makeCreateTodoVC() -> CreateTodoVC {
        return assembler.resolver.resolve(CreateTodoVC.self)!
    }

    func makeEditTodoVC(_ model: TodoModelProtocol) -> EditTodoVC {
        return assembler.resolver.resolve(EditTodoVC.self, argument: model)!
    }
}

final class TodoEditableAssembly: Assembly {
    func assemble(container: Container) {
        // 생성 화면 등록
        container.register(CreateTodoVC.self) { _ in
            return CreateTodoVC(
                CreateTodoVM()
            )
        }

        // 수정 화면 등록
        container.register(EditTodoVC.self) { (_, model: TodoModelProtocol) in
            return EditTodoVC(
                model: model,
                viewModel: EditTodoVM(model: model)
            )
        }
    }

}
