//
//  UIBlockContentView.swift
//  Peek
//
//  Created by Til Blechschmidt on 03.03.21.
//

import UIKit
import SnapKit
import MarkdownKit

protocol BlockDisplayView: UIView {
    var delegate: BlockInteractionDelegate? { get set }

    func select(offset: Int?)
}

class UIBlockContentView: UIView {
    private var contentView = UIView()

//    override var keyCommands: [UIKeyCommand]? {
//        let commands = UIKeyCommand(input: "X", modifierFlags: .control, action: #selector(test))
//        return [commands]
//    }
//
//    @objc func test() {
//        print("TEST")
//    }

    var content: Block.Content = .text("") {
        didSet {
            updateContentView()
        }
    }

    weak var delegate: BlockInteractionDelegate? {
        didSet {
            if let blockView = contentView as? BlockDisplayView {
                blockView.delegate = delegate
            }
        }
    }

//    override var canBecomeFirstResponder: Bool {
//        true
////        contentView.canBecomeFirstResponder
//    }
//
//    override func becomeFirstResponder() -> Bool {
//        super.becomeFirstResponder()
////        contentView.becomeFirstResponder()
//    }
//
//    override var next: UIResponder? {
//        contentView
//    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContentView() {
        let newContentView = content.createView(reusing: contentView)
        replaceContentView(with: newContentView)
    }

    private func replaceContentView(with view: UIView) {
        if contentView !== view {
            contentView.removeFromSuperview()
            addSubview(view)
        }

        view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            // Since the table view asynchronously updates the cell height
            // we would run into height constraint breakages. So we make it low priority.
            make.bottom.equalToSuperview().priority(.low)
        }

        contentView = view

        if let blockView = contentView as? BlockDisplayView {
            blockView.delegate = delegate
        }
    }

    func select(offset: Int?) {
        if let blockView = contentView as? BlockDisplayView {
            blockView.select(offset: offset)
        }
    }
}

extension Block.Content {
    func createView(reusing oldView: UIView) -> UIView {
        switch self {
        case .text(let text):
            let view = oldView as? TextContentView ?? TextContentView()
            view.text = text
            return view
        case .thematicBreak(let variant):
            let view = oldView as? ThematicBreakView ?? ThematicBreakView()
            view.variant = variant
            return view
        default:
            let view = UILabel()
            view.text = "Unknown block type"
            return view
        }
    }
}

class ThematicBreakView: UIView {
    var variant: ThematicBreak.Variant = .dots {
        didSet {
            switch variant {
            case .dots:
                heightConstraint.update(offset: 3)
            case .line:
                heightConstraint.update(offset: 0.5)
            case .thickLine:
                heightConstraint.update(offset: 1.5)
            }

            setNeedsDisplay()
        }
    }

    private var heightConstraint: Constraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        
        self.snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(5).constraint
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        switch variant {
        case .dots:
            drawDots()
        case .line:
            drawLine(color: .gray)
        case .thickLine:
            drawLine(color: .white)
        }
    }

    private func drawDots() {
        let height = bounds.size.height
        let width = bounds.size.width

        UIColor.gray.setStroke()

        // Draw three dots. One defaultPadding left of center, one on center, one defaultPadding right of center
        // We need to extend the actual line by height/2 (the diameter of the dots) on each end to fit the dots in
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width / 2 - Constant.defaultPadding - height / 2, y: height / 2))
        path.addLine(to: CGPoint(x: width / 2 + Constant.defaultPadding + height / 2, y: height / 2))
        path.lineWidth = height
        path.lineCapStyle = .round
        path.setLineDash([0.0, Constant.defaultPadding], count: 3 * 2, phase: 0)
        path.stroke()
    }

    private func drawLine(color: UIColor) {
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: .allCorners,
                                cornerRadii: CGSize(width: bounds.size.height / 2, height: bounds.size.height / 2))
        color.setFill()
        path.fill()
    }
}

class TextContentView: UIView, BlockDisplayView {
    func select(offset: Int?) {
        if textView.becomeFirstResponder() {
            DispatchQueue.main.async {
                // TODO Make this work :D
//                self.textView.beginFloatingCursor(at: CGPoint(x: offset.flatMap { CGFloat($0) } ?? self.textView.bounds.width, y: 0.0))
//                self.textView.endFloatingCursor()
                self.textView.selectedRange = .init(location: offset ?? self.textView.text.count, length: 0)
                self.textView.updateFocusIfNeeded()
            }
        }
    }

    private let textStorage = FancyTextStorage()
    private let textView: InlineMarkdownTextView

    weak var delegate: BlockInteractionDelegate?

    var text: String {
        get {
            textView.text
        }
        set {
            textView.text = newValue
        }
    }

    override var canBecomeFirstResponder: Bool {
        textView.canBecomeFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        let result = textView.becomeFirstResponder()
        DispatchQueue.main.async {
            self.textView.selectedRange = .init(location: 5, length: 10)
        }
        return result
    }

    override init(frame: CGRect) {
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: .zero)
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        textView = InlineMarkdownTextView(frame: .zero, textContainer: container)
        textView.textColor = .label
        textView.backgroundColor = .clear

        textView.font = UIFont.preferredFont(forTextStyle: .body).withSize(16)

        textView.isScrollEnabled = false
        textView.alwaysBounceVertical = false
        textView.isUserInteractionEnabled = true

        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        super.init(frame: frame)
        textView.delegate = self

        backgroundColor = .clear
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.setNeedsLayout()

        textView.text = "Hello!"
        textView.inlineDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TextContentView: UITextViewDelegate, InlineMarkdownTextViewDelegate {
    func textViewDidReceiveDeletionRequest() {
        delegate?.blockRequestsDeletion()
    }

    func textViewDidReceiveNextParagraphRequest() {
        delegate?.blockRequestsNewParagraph()
    }

    func textViewDidChange(_ textView: UITextView) {
        delegate?.blockDidChangeLayout()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        textStorage.textViewDidChangeSelection(textView)
//        layoutChangeHandler?()
//        print("SELECT")
    }
}
