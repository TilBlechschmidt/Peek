//
//  BlockCollectionViewController.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit
import SwiftUI
import MarkdownKit

class BlockCollectionViewController: UICollectionViewController {
    var dataSource: UICollectionViewDiffableDataSource<Section, Block>!

    init() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.backgroundColor = .clear
        configuration.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        configureCollectionView()
        configureDataSource()
        updateUI()
    }
}

extension BlockCollectionViewController {
    enum Section: CaseIterable {
        case main
    }

    func updateUI() {
        var currentSnapshot = NSDiffableDataSourceSnapshot<Section, Block>()

        let blocks = (0..<1000).map { i in
            Block(admonition: arc4random_uniform(2) == 1, blockquote: arc4random_uniform(2) == 1, content: .text("Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 Hello world #17 #\(i)"))
        }

        currentSnapshot.appendSections([.main])
        currentSnapshot.appendItems(blocks, toSection: .main)

        dataSource.apply(currentSnapshot)
    }

    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Block>(collectionView: collectionView) { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, block: Block) -> UICollectionViewCell? in

            guard let cell = collectionView.dequeueReusableCell(matching: block, for: indexPath) else {
                return nil
            }

            cell.block = block

            cell.changeHandler = { [weak collectionView] in
//                DispatchQueue.main.async {
                    print("Reloading \(indexPath.row)")
                collectionView?.collectionViewLayout.invalidateLayout()
//                    let invalidationContext = UICollectionViewLayoutInvalidationContext()
//                    invalidationContext.invalidateItems(at: collectionView?.indexPathsForVisibleItems ?? [])
//                    UIView.animate(withDuration: 0.25) {
//                        collectionView?.collectionViewLayout.invalidateLayout(with: invalidationContext)
//                        collectionView?.setNeedsLayout()
//                        collectionView?.setNeedsDisplay()
//                        collectionView?.layoutIfNeeded()
//                    }
//                }
            }

            return cell
        }
    }

    func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive

        collectionView.register(BlockCell.self, forCellWithReuseIdentifier: BlockCell.reuseIdentifier)
        collectionView.register(TextBlockCell.self, forCellWithReuseIdentifier: TextBlockCell.reuseIdentifier)
    }
}

extension UICollectionView {
    func dequeueReusableCell(matching block: Block, for indexPath: IndexPath) -> BlockCell? {
        switch block.content {
        case .text:
            return dequeueReusableCell(withReuseIdentifier: TextBlockCell.reuseIdentifier, for: indexPath) as? BlockCell
        default:
            return dequeueReusableCell(withReuseIdentifier: BlockCell.reuseIdentifier, for: indexPath) as? BlockCell
        }
    }
}

class BlockCell: UICollectionViewCell {
    class var reuseIdentifier: String { "unknown-block" }

    var changeHandler: (() -> Void)?

    var block: Block! {
        didSet {
            blockChanged()
        }
    }

    func blockChanged() {
        replaceContent(with: block.content)
    }

    func replaceContent(with newContent: Block.Content) {}


    override func prepareForReuse() {
        changeHandler = nil
    }
}

class TextBlockCell: BlockCell {
    static override var reuseIdentifier: String { "text-block" }

    override var intrinsicContentSize: CGSize {
        textView.sizeThatFits(CGSize(width: contentView.bounds.width, height: .infinity))
    }

    override func replaceContent(with newContent: Block.Content) {
//        print("Displaying \(newContent)")

        guard case .text(let text) = newContent else {
            fatalError()
        }

        textView.text = text
    }

    let textView = InlineMarkdownTextView()

    var isHeightCalculated: Bool = false

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        //Exhibit A - We need to cache our calculation to prevent a crash.
//        if !isHeightCalculated {
            setNeedsLayout()
            layoutIfNeeded()
        let size = textView.sizeThatFits(CGSize(width: 768.0, height: .infinity))
        print(size)
            var newFrame = layoutAttributes.frame
            newFrame.size.height = size.height
            layoutAttributes.frame = newFrame
            isHeightCalculated = true
//        }

        return layoutAttributes
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        textView.font = .systemFont(ofSize: 16)
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TextBlockCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        isHeightCalculated = false
//        self.setNeedsLayout()
//        self.invalidateIntrinsicContentSize()
        self.changeHandler?()
//        print(textView.sizeThatFits(CGSize(width: contentView.bounds.width, height: .infinity))) //, textView.sizeThatFits(CGSize(width: contentView.bounds.width, height: .infinity)))
    }
}

struct BlockCollectionView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BlockCollectionViewController {
        let vc = BlockCollectionViewController()

        return vc
    }

    func updateUIViewController(_ uiViewController: BlockCollectionViewController, context: Context) {
        // Nothing!
    }
}
