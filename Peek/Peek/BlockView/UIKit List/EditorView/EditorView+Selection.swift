//
//  EditorView+Selection.swift
//  Peek
//
//  Created by Til Blechschmidt on 21.04.21.
//

import UIKit

extension BlockEditorViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }

    override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}

extension BlockEditorViewController: FocusEngineSelectionDelegate {
    func focusEngine(didChangeSelectionBy delta: CollectionDifference<UUID>) {
        let changes = delta.reduce(into: (insertions: Set<UUID>(), removals: Set<UUID>())) { result, change in
            switch change {
            case .insert(_, let element, _):
                result.insertions.insert(element)
            case .remove(_, let element, _):
                result.removals.insert(element)
            }
        }

        for removal in changes.removals {
            guard let indexPath = dataSource.indexPath(for: removal) else { continue }
            tableView.deselectRow(at: indexPath, animated: true)
        }

        for insertion in changes.insertions {
            guard let indexPath = dataSource.indexPath(for: insertion) else { continue }
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
}
