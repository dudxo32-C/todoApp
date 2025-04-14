//
//  TodoCell.swift
//  todoApp
//
//  Created by 조영태 on 4/14/25.
//

import Foundation
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

class TodoCell: UITableViewCell {
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 16)
        $0.numberOfLines = 1
    }

    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.7
        $0.textAlignment = .right
    }

    private let desLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    // MARK: - Get/Set
    private var _model: TodoModelProtocol?
    
    var todoModel: TodoModelProtocol {
        get {
            guard let model = self._model else {
                preconditionFailure("todoModel을 set 해야합니다.")
            }

            return model
        }

        set {
            self._model = newValue

            Observable.just(newValue.title)
                .bind(to: self.titleLabel.rx.text)
                .disposed(by: self.disposedBag)

            Observable.just(newValue.contents)
                .bind(to: self.desLabel.rx.text)
                .disposed(by: self.disposedBag)

            Observable.just(newValue.date)
                .map { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy/MM/dd"
                    formatter.locale = Locale(identifier: "ko")

                    let str = formatter.string(from: date)

                    return str
                }
                .bind(to: self.dateLabel.rx.text)
                .disposed(by: self.disposedBag)
        }
    }
    // MARK: - RX
    private let disposedBag = DisposeBag()
    // MARK: -
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: -
    private func setupViews() {
        let hStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel]).then
        {
            $0.axis = .horizontal
            $0.spacing = 8
        }

        self.contentView.addSubview(hStack)
        self.contentView.addSubview(desLabel)

        hStack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.leading.trailing.equalToSuperview()
        }

        self.dateLabel.snp.makeConstraints { make in
            make.width.equalTo(titleLabel).multipliedBy(0.3)
        }

        self.desLabel.snp.makeConstraints {
            $0.top.equalTo(hStack.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
        }
    }
}
