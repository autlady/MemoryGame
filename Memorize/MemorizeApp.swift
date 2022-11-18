//
//  MemorizeApp.swift
//  Memorize
//
//  Created by  Юлия Григорьева on 14.09.2022.
//

import SwiftUI

@main
struct MemorizeApp: App {
    private let game = EmojiMemoryGame()
    var body: some Scene {
        WindowGroup {
            EmojiMemoryGameView(game: game)
        }
    }
}

