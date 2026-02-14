//
//  PopoverSizePreferenceKey.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-09.
//

import SwiftUI

/// NSPopoverのサイズをSwiftUIからAppKitに伝播するためのPreferenceKey
struct PopoverSizePreferenceKey: PreferenceKey {
    static var defaultValue: NSSize = NSSize(width: 550, height: 700)

    static func reduce(value: inout NSSize, nextValue: () -> NSSize) {
        value = nextValue()
    }
}

/// ポップオーバーサイズを設定するViewModifier
struct PopoverSizeModifier: ViewModifier {
    let size: NSSize

    func body(content: Content) -> some View {
        content
            .preference(key: PopoverSizePreferenceKey.self, value: size)
    }
}

extension View {
    /// ポップオーバーのサイズを設定
    func popoverSize(_ size: NSSize) -> some View {
        modifier(PopoverSizeModifier(size: size))
    }
}
