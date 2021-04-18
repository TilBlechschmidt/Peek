//
//  BlockStackViewController.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit
import Combine
import SwiftUI

class BlockStackViewController: UIViewController {
    let scrollView = UIScrollView()
    let stackView = UIStackView()

    func makeLabel(_ i: Int) -> UIView {
//        let label = UILabel()
//
//        label.text = "Hello World!"
//        label.textColor = .black
//        label.backgroundColor = color
//        label.textAlignment = .center
//        label.snp.makeConstraints { make in
//            make.width.equalTo(700)
//            make.height.equalTo(400)
//        }
//
//        return label
        let view = TextContentView()
        view.text = "# \(i) Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.\n\n"
        view.delegate = self
//        view.admonition = arc4random_uniform(2) == 1
//        view.blockquote = arc4random_uniform(2) == 1
        return view
    }

    func addLabel(_ i: Int) {
        let label = makeLabel(i)
        stackView.addArrangedSubview(label)
        label.snp.makeConstraints { make in
            make.width.equalTo(scrollView)
        }

        label.isHidden = true
        stackView.removeArrangedSubview(label)
    }

    override func loadView() {
        stackView.axis = .vertical
//        stackView.distribution = .fillProportionally

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
        }

        for i in 0..<1000 {
            addLabel(i)
        }

//        stackView.addArrangedSubview(makeLabel(.systemBlue))
//        stackView.addArrangedSubview(makeLabel(.systemGreen))
//        stackView.addArrangedSubview(makeLabel(.systemRed))

        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO
    }
}

extension BlockStackViewController: BlockInteractionDelegate {
    func blockRequestsDeletion() {

    }

    func blockRequestsNewParagraph() {

    }

    func blockDidChangeLayout() {
        UIView.animate(withDuration: 0.25) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}

struct UIKitStack: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BlockStackViewController {
        let vc = BlockStackViewController()

        return vc
    }

    func updateUIViewController(_ uiViewController: BlockStackViewController, context: Context) {
        // Nothing!
    }
}
