import SwiftUI

extension Color {
    // Colores del icono.
    static let brandPink = Color(red: 1.0, green: 0.25, blue: 0.51)
    static let brandViolet = Color(red: 0.54, green: 0.17, blue: 0.89)
    static let brandBlue = Color(red: 0.16, green: 0.38, blue: 1.0)
}

extension ShapeStyle where Self == LinearGradient {
    static var brand: LinearGradient {
        LinearGradient(colors: [.brandPink, .brandViolet, .brandBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension View {
    /// Liquid Glass en iOS 26; material translúcido en versiones anteriores.
    @ViewBuilder func glassCard(cornerRadius: CGFloat = 24) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder func glassButton(prominent: Bool = false) -> some View {
        if #available(iOS 26, *) {
            if prominent { buttonStyle(.glassProminent) } else { buttonStyle(.glass) }
        } else {
            if prominent { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
        }
    }
}

/// Fondo con manchas de color difuminadas, para que el cristal tenga algo que refractar.
struct Backdrop: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            Circle().fill(Color.brandPink.opacity(0.35)).frame(width: 360).blur(radius: 90).offset(x: -140, y: -300)
            Circle().fill(Color.brandViolet.opacity(0.30)).frame(width: 320).blur(radius: 90).offset(x: 160, y: -80)
            Circle().fill(Color.brandBlue.opacity(0.28)).frame(width: 380).blur(radius: 100).offset(x: -70, y: 330)
        }
        .ignoresSafeArea()
    }
}

/// El "icono" de la app dibujado con SF Symbols.
struct AppMark: View {
    var size: CGFloat = 76
    var body: some View {
        Image(systemName: "arrow.down.to.line")
            .font(.system(size: size * 0.44, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(.brand, in: .rect(cornerRadius: size * 0.27, style: .continuous))
            .shadow(color: .brandViolet.opacity(0.35), radius: 16, y: 8)
    }
}
