//
//  EditableTextView.swift
//  todoApp
//
//  Created by 조영태 on 4/2/25.
//

import Foundation
import RxCocoa
import SnapKit
import Then
import UIKit

class TextInputStackView: UIStackView {
    // MARK: - UI Components
    private let titleTextInput = UITextField().then {
        $0.placeholder = "제목을 입력하세요"
    }

    private let contentTextInput = UITextView().then {
        $0.isScrollEnabled = true
        $0.isEditable = true
        $0.font = UIFont.systemFont(ofSize: 17)
        $0.returnKeyType = .default
        $0.textContainer.lineFragmentPadding = 0
        $0.backgroundColor = nil
    }

    private let contentPlaceholderLabel = UILabel().then {
        $0.text = "내용을 입력하세요..."
        $0.textAlignment = .center
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = UIColor.lightGray
    }

    private let divider = UIView().then {
        $0.backgroundColor = UIColor.lightGray
        $0.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
    }

    // MARK: - Snap
    private var contentHeightContraint: Constraint?  // 높이 제약 저장
    
    // MARK: - Rx
    var titleTextRX: ControlProperty<String?> {
        return self.titleTextInput.rx.text
    }
    
    var contentTextRX: ControlProperty<String?> {
        return self.contentTextInput.rx.text
    }
    

    // MARK: - Init
    init(title: String?, content: String?) {
        self.titleTextInput.text = title
        self.contentTextInput.text = content
        self.contentPlaceholderLabel.isHidden = !(content ?? "").isEmpty

        super.init(frame: .zero)

        self.contentTextInput.delegate = self

        axis = .vertical
        spacing = 8
        layoutMargins = .init(top: 8, left: 8, bottom: 8, right: 8)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 8
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1

        setUI()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUI() {
        self.addArrangedSubview(self.titleTextInput)
        self.addArrangedSubview(self.divider)
        self.addArrangedSubview(self.contentTextInput)
        self.contentTextInput.addSubview(self.contentPlaceholderLabel)

        // 한줄일때 입력 텍스트의 높이
        let inputTextHeightByContent = self.getContentHeight()

        self.titleTextInput.snp.makeConstraints { make in
            make.height.equalTo(inputTextHeightByContent)
        }

        self.contentTextInput.snp.makeConstraints { make in
            self.contentHeightContraint =
                make.height.equalTo(inputTextHeightByContent).constraint
        }

        self.contentPlaceholderLabel.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
                .inset(contentTextInput.textContainerInset)
        }
    }

    private func getContentHeight() -> CGFloat {
        let height = self.contentTextInput.sizeThatFits(
            CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        ).height

        return height > 300 ? 300 : height
    }
}

extension TextInputStackView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        contentPlaceholderLabel.isHidden = !contentTextInput.text.isEmpty

        let height = self.getContentHeight()
        contentHeightContraint?.update(offset: height)
    }

    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        // 텍스트 뷰에서 줄 바꿈이 가능하게 하도록 처리
        textView.resignFirstResponder()
        return true
    }
}
