//
//  ContentView.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.02.21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        EditorView()
            .padding()
            .frame(maxWidth: 800)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
