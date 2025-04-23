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

    fileprivate var doneButton = CircularCheckButton()

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

            titleLabel.text = newValue.title

            desLabel.text = newValue.contents

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            formatter.locale = Locale(identifier: "ko")

            let str = formatter.string(from: newValue.date)
            dateLabel.text = str

            doneButton.isDone = newValue.isDone
        }
    }
    // MARK: - RX
    var disposeBag = DisposeBag()

    // MARK: -
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Binding
    private func bindDoneButton() {
        doneButton.isDoneChanged
            .withUnretained(self)
            .bind { (self, isDone) in
                let color = isDone ? UIColor.systemGray3 : UIColor.black
                self.titleLabel.textColor = color
                self.desLabel.textColor = color
                self.dateLabel.textColor = color
            }
            .disposed(by: disposeBag)

    }
    
    // MARK: - SetUI
    private func setupViews() {
        contentView.addSubview(doneButton)

        doneButton.snp.makeConstraints {
            $0.width.height.equalTo(30)
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        let hStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel]).then
        {
            $0.axis = .horizontal
            $0.spacing = 8
        }

        self.contentView.addSubview(hStack)
        self.contentView.addSubview(desLabel)

        hStack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.trailing.equalToSuperview().inset(C_margin16)
            $0.leading.equalTo(doneButton.snp.trailing).offset(C_margin16)
        }

        self.dateLabel.snp.makeConstraints { make in
            make.width.equalTo(titleLabel).multipliedBy(0.3)
        }

        self.desLabel.snp.makeConstraints {
            $0.top.equalTo(hStack.snp.bottom).offset(8)
            $0.trailing.equalToSuperview().inset(C_margin16)
            $0.leading.equalTo(doneButton.snp.trailing).offset(C_margin16)
            $0.bottom.equalToSuperview().inset(8)
        }
    }
    
    // MARK: -
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()  // ✅ 바인딩 리셋
        // cell 이 재사용 되었기에 새롭게 바인딩
        self.bindDoneButton()

    }
}

extension Reactive where Base: TodoCell {
    var doneTap: ControlEvent<Void> {
        base.doneButton.rx.tap
    }
}

private class CircularCheckButton: UIButton {
    var isDone = false {
        didSet {
            updateAppearance()
            isDoneChanged.accept(isDone)
        }
    }

    fileprivate let isDoneChanged = PublishRelay<Bool>.init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.height / 2
    }

    private func setup() {
        self.backgroundColor = .systemGray5
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.systemBlue.cgColor
        self.tintColor = .systemGray5
        self.clipsToBounds = true
    }

    private func updateAppearance() {
        self.layer.borderColor =
            (isDone ? UIColor.systemGray5 : UIColor.systemBlue).cgColor

        self.backgroundColor = isDone ? .systemBlue : .systemGray5
    }
}
