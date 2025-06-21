import SwiftUI

struct TooltipModifier: ViewModifier {
    let tooltip: String
    @Binding var showTooltips: Bool
    @State private var showThisTooltip = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showTooltips && showThisTooltip {
                        TooltipView(text: tooltip)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                if showTooltips {
                    withAnimation(.easeInOut.delay(0.5)) {
                        showThisTooltip = true
                    }
                }
            }
    }
}

struct TooltipView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                Triangle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 8)
                    .rotationEffect(.degrees(180))
                    .offset(y: -16),
                alignment: .top
            )
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
} 