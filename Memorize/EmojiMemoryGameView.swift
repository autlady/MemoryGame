//
//  EmojiMemoryGameView.swift
//  Memorize
//
//  Created by  Юлия Григорьева on 14.09.2022.
//

import SwiftUI

struct EmojiMemoryGameView: View {

//    @State var emoji = [String]()

   @ObservedObject var game: EmojiMemoryGame
    @Namespace private var dealingNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Text("Memorize!")
                    .bold()
                    .foregroundStyle(CardConstants.color)
                    .padding()
                    .font(.system(size: 50, weight: .regular))
                    .lineLimit(1)
                gameBody
                HStack {
                    restart
                    Spacer()
                    shuffle
                }
                .padding(.horizontal)
            }
            deckBody

        }
//        HStack {
//            Group {
//                theme1
//                theme2
//                theme3
//            }
//            .font(.title)
//            .padding()
//        }
            .padding()

}
    @State private var dealt = Set<Int>()

    private func deal(_ card: EmojiMemoryGame.Card) {
        dealt.insert(card.id)
    }

    private func isUndealt(_ card: EmojiMemoryGame.Card) -> Bool {
        !dealt.contains(card.id)
    }

    private func dealAnimation(for card: EmojiMemoryGame.Card) -> Animation {
        var delay = 0.0
        if let index = game.cards.firstIndex(where: { $0.id == card.id }) {
            delay = Double(index) * (CardConstants.totalDealDuration / Double(game.cards.count))
        }
        return Animation.easeInOut(duration: CardConstants.dealDuration).delay(delay)
    }

    private func zIndex(of card: EmojiMemoryGame.Card) -> Double {
        -Double(game.cards.firstIndex(where: { $0.id == card.id }) ?? 0)

    }

    var gameBody: some View {
        AspectVGrid(items: game.cards, aspectRatio: CardConstants.aspectRatio) { card in
            if isUndealt(card) || (card.isMatched && !card.isFaceUp) {
                Color.clear //карты не показываются
                //                Rectangle().opacity(0)
            } else { // карты показываются
                CardView(card: card)
                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                    .padding(4)
                    //при совпадении карты уменьшаются при исчезновении
                    .transition(AnyTransition
                        .asymmetric(insertion: .identity, removal: .scale))
                    .zIndex(zIndex(of: card))
//                        .animation(.easeInOut(duration: 3)))
                    .onTapGesture {
                        withAnimation {
                            game.choose(card)
                        }
                    }
            }
        }

                .foregroundStyle(CardConstants.color)
    }

    var deckBody: some View {
        ZStack {
            ForEach(game.cards.filter(isUndealt)) { card in
                CardView(card: card)
                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                    .transition(AnyTransition
                        .asymmetric(insertion: .opacity, removal: .identity))
                    .zIndex(zIndex(of: card))
            }
        }
        .frame(width: CardConstants.undealWidth, height: CardConstants.undealHeight)
        .foregroundStyle(CardConstants.color)
        .onTapGesture {
            // сдача карт
            for card in game.cards {
                withAnimation(dealAnimation(for: card)) {
                    deal(card)
                }
            }
        }
    }

    var shuffle: some View {
        Button("Shuffle") {
            withAnimation {
                game.shuffle()
            }
        }
    }

    var restart: some View {
        Button ("New Game") {
            withAnimation {
                dealt = []
                game.restart()
            }
        }
    }

//    var theme1: some View {
//        Button {
//
//        } label: {
//            VStack() {
//                Image(systemName: "mouth.fill")
//                    .frame(width: 30, height: 30)
//                Text("Girls")
//            }
//        }
//    }
//
//    var theme2: some View {
//        Button {
//
//        } label: {
//            VStack {
//                Image(systemName: "face.dashed.fill")
//                    .frame(width: 30, height: 30)
//                Text("Emotions")
//            }
//        }
//
//    }
//
//    var theme3: some View {
//        Button {
//
//        } label: {
//            VStack {
//                Image(systemName: "mustache.fill")
//                    .frame(width: 30, height: 30)
//                Text("Boys")
//            }
//        }
//    }

    private struct CardConstants {
        static let color = LinearGradient(colors: [.blue, .red], startPoint: .bottom, endPoint: .top)
        static let aspectRatio: CGFloat = 2/3
        static let dealDuration: Double = 0.5
        static let totalDealDuration: Double = 2
        static let undealHeight: CGFloat = 90
        static let undealWidth = undealHeight * aspectRatio
    }
}



struct CardView: View {
    let card: EmojiMemoryGame.Card
    @State private var animatedBonusRemaining = 0.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if card.isConsumingBonusTime {
                        Pie(startAngle: Angle(degrees: 0-90), endAngle: Angle(degrees: (1 - animatedBonusRemaining) * 360 - 90))
                            .onAppear {
                                animatedBonusRemaining = card.bonusRemaining
                                withAnimation(.linear(duration: card.bonusTimeRemaining)) {
                                    animatedBonusRemaining = 0
                                }
                            }

                    } else {
                        Pie(startAngle: Angle(degrees: 0-90), endAngle: Angle(degrees: (1 - card.bonusRemaining) * 360 - 90))
                    }
                }
                .padding(5)
                .opacity(DrawingConstants.pieOpacity)

                Text(card.content)
                    .rotationEffect(Angle.degrees(card.isMatched ? 360 : 0))
                    .animation(Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false), value: card.isMatched)
                    .font(Font.system(size: DrawingConstants.fontSize))
                    .scaleEffect(scale (thatFits: geometry.size))
            }
            .cardify(isFaceUp: card.isFaceUp)
        }
        }
    private struct DrawingConstants {

        static let fontScale: CGFloat = 0.7
        static let fontSize: CGFloat = 32
        static let pieOpacity: CGFloat = 0.6
    }

    private func scale(thatFits size: CGSize) -> CGFloat {
        min(size.width, size.height) / (DrawingConstants.fontSize / DrawingConstants.fontScale)
    }

    }

extension View {
    func cardify(isFaceUp: Bool) -> some View {
        self.modifier(Cardify(isFaceUp: isFaceUp))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = EmojiMemoryGame()
        game.choose(game.cards.first!)
        return EmojiMemoryGameView(game: game)
            .preferredColorScheme(.light)
    }
}

//    .animation(Animation.linear(duration: 1)
//        .repeatForever(autoreverses: false),
//               value: card.isMatched)
