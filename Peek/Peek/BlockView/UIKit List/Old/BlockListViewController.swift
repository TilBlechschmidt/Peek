//
//  BlockListViewController.swift
//  Peek
//
//  Created by Til Blechschmidt on 01.03.21.
//

import UIKit
import SwiftUI
import Combine
import MarkdownKit

class SelectionState: ObservableObject {
    private weak var blockManager: BlockManager?

    /// Whether text editing is enabled or we are in block selection mode.
    /// When this is true, only one block may be selected and it is the UIResponder (if applicable).
    @Published var textEditMode: Bool = false

    /// Horizontal offset of the caret. Nil value means infinity/end of document.
    ///
    /// Note that this does not represent the selected text range, if applicable.
    /// This is up to the ContentView to handle. This offset represents just the
    /// inset on the x-axis used for moving the cursor between blocks.
    @Published var offset: Int?

    @Published var blockSelection: [Block.ID] = []

    init(_ blockManager: BlockManager? = nil) {
        self.blockManager = blockManager
    }

    func moveSelectionToBlock(after identifier: Block.ID) {
        let id: Block.ID? = blockManager?.block(after: identifier)?.id
        DispatchQueue.main.async {
            self.blockSelection = id.flatMap { [$0] } ?? []
        }
    }

    func moveSelectionToBlock(before identifier: Block.ID) {
        let id: Block.ID? = blockManager?.block(before: identifier)?.id
        DispatchQueue.main.async {
            self.blockSelection = id.flatMap { [$0] } ?? []
        }
    }
}

class BlockListViewController: UIViewController {
    enum Section: CaseIterable {
        case main
    }

    struct Item: Hashable {
        let identifier: UUID

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.identifier)
        }
    }

    let tableView = UITableView(frame: .zero, style: .plain)

    var dataSource: UITableViewDiffableDataSource<Section, Item>! = nil
    var currentSnapshot: NSDiffableDataSourceSnapshot<Section, Item>! = nil

    static let reuseIdentifier = "reuse-identifier"

    var blockManagerCancellable: AnyCancellable?
    let blockManager: BlockManager

    var selectionStateCancellables: [AnyCancellable] = []
    var selectionState: SelectionState! {
        didSet {
            selectionStateCancellables.removeAll()

            selectionState.$textEditMode
                .sink { [weak self] in
                    self?.tableView.allowsSelection = !$0
                    self?.tableView.allowsMultipleSelection = !$0
                }
                .store(in: &selectionStateCancellables)

//            selectionState.$blockSelection
//                .sink { [weak self] state in
//                    if let self = self, let lastSelected = state.last, let index = self.blockManager.blockIDs.firstIndex(of: lastSelected) {
//                        self.tableView.scrollToRow(at: IndexPath(item: index, section: 0), at: .middle, animated: true)
//                    }
//                }
//                .store(in: &selectionStateCancellables)
        }
    }

    init(_ blockManager: BlockManager) {
        self.blockManager = blockManager
        self.selectionState = SelectionState(blockManager)

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func observeBlockManager() {
        blockManagerCancellable = blockManager.$blockIDs.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureDataSource()
//        updateUI(animated: false)
//        observeBlockManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        updateUI(animated: false)
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
}

extension BlockListViewController {
    func updateUI(animated: Bool = true) {
        currentSnapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        let items = blockManager.blockIDs.map { identifier -> Item in
            return Item(identifier: identifier)
        }
        currentSnapshot.appendSections([.main])
        currentSnapshot.appendItems(items, toSection: .main)

        DispatchQueue.main.async {
            self.dataSource.apply(self.currentSnapshot, animatingDifferences: animated)
        }
    }

    func configureDataSource() {
        self.dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, item: Item) -> UITableViewCell? in

            guard let self = self, let cell = tableView.dequeueReusableCell(withIdentifier: BlockListViewController.reuseIdentifier, for: indexPath) as? BlockListCell else {
                return nil
            }

            cell.delegate = self
            cell.block = self.blockManager[item.identifier]
//            cell.connection = self.blockManager.connections(for: item.identifier)
            cell.selection = self.selectionState

            return cell
        }

        self.dataSource.defaultRowAnimation = .fade
    }

    func configureTableView() {
        view.addSubview(tableView)
        view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.keyboardDismissMode = .interactive
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.register(BlockListCell.self, forCellReuseIdentifier: BlockListViewController.reuseIdentifier)
    }

    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillShow(notification:)),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide(notification:)),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // TODO Set a bottom contentInset of half the view height (in general) to allow the content to scroll "past" the document end.
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }
}

extension BlockListViewController: BlockListCellDelegate {
    func blockListCellRequestsDeletion(_ cell: BlockListCell) {
        blockManager.remove(cell.block.id)
    }

    func blockListCellRequestsNewParagraph(_ cell: BlockListCell) {
        blockManager.insert(UIBlock(admonition: cell.block.admonition, blockquote: cell.block.blockquote, content: .text("")), after: cell.block.id)
    }

    func blockListCellDidChangeLayout(_ cell: BlockListCell) {
        // TODO This sometimes causes updates (full re-dequeueing actually) of all visible cells
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()

            if let indexPath = self.tableView.indexPath(for: cell) {
                self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            }
        }
    }
}

struct UIKitList: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BlockListViewController {
        let vc = BlockListViewController(BlockManager([
            UIBlock(admonition: false, blockquote: false, content: .heading(level: 1, content: "Super important heading")),
            UIBlock(admonition: false, blockquote: false, content: .text("This is a wonderful and lovely test document! How about you do some research about what you can do?")),
            UIBlock(admonition: false, blockquote: false, content: .thematicBreak(.dots)),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: true, blockquote: false, content: .text("Hello world!")),
            UIBlock(admonition: false, blockquote: true, content: .text("Hello world!")),
            UIBlock(admonition: true, blockquote: true, content: .text("Hello world!")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: true, blockquote: false, content: .text("Connected admonition!")),
            UIBlock(admonition: true, blockquote: false, content: .text("Let us see how well this works.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: false, blockquote: true, content: .text("Connected blockquote!")),
            UIBlock(admonition: false, blockquote: true, content: .text("Let us see how well this works.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: true, blockquote: true, content: .text("Connecting both at the same time now!")),
            UIBlock(admonition: true, blockquote: true, content: .text("Let us see how well this works.")),
        ]))

        return vc
    }

    func updateUIViewController(_ uiViewController: BlockListViewController, context: Context) {
        // Nothing!
    }
}
