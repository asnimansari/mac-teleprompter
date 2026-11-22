import SwiftUI

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct PrompterView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var controller: PrompterController
    let size: PanelSize
    let topInset: CGFloat
    let hasNotch: Bool

    private var lineHeight: CGFloat { size.fontSize * 1.3 }

    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: hasNotch ? 0 : 14,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: hasNotch ? 0 : 14
            )
            .fill(.black)

            VStack(spacing: 0) {
                Color.clear.frame(height: topInset)
                GeometryReader { geo in
                    let readingY = geo.size.height / 3
                    Text(settings.script.isEmpty ? "Menu bar icon → Edit Script…" : settings.script)
                        .font(.system(size: size.fontSize, weight: .semibold))
                        .lineSpacing(size.fontSize * 0.3)
                        .foregroundStyle(settings.script.isEmpty ? .gray : .white)
                        .frame(width: geo.size.width - 40, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(GeometryReader { g in
                            Color.clear.preference(key: HeightKey.self, value: g.size.height)
                        })
                        .offset(x: 20, y: readingY - controller.offset)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                        .clipped()
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.28),
                                    .init(color: .black, location: 0.55),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .onPreferenceChange(HeightKey.self) { controller.textHeight = $0 }
                }
            }

            overlay
        }
        .onAppear { controller.lineHeight = lineHeight }
        .onChange(of: size) { controller.lineHeight = lineHeight }
    }

    @ViewBuilder private var overlay: some View {
        if let n = controller.countdown {
            Text("\(n)")
                .font(.system(size: size.fontSize * 2.4, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.75))
                .padding(.top, topInset)
        } else if let toast = controller.toast {
            VStack {
                Spacer()
                Text(toast)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.18)))
                    .padding(.bottom, 8)
            }
        }
    }
}
