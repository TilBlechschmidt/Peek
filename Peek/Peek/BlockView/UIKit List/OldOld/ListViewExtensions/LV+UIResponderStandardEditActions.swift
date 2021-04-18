//
//  LV+UIResponderStandardEditActions.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.03.21.
//

import UIKit

extension NewBlockListViewController {
    override func selectAll(_ sender: Any?) {
        editorState.focusEngine.selectAll()
    }

    // TODO Implement these :)
//    override func cut(_ sender: Any?) {
//        <#code#>
//    }
//
//    override func copy(_ sender: Any?) {
//        <#code#>
//    }
//
//    override func paste(_ sender: Any?) {
//        <#code#>
//    }

    override func delete(_ sender: Any?) {
        deleteSelection()
    }
}
