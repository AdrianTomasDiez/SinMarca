import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Aparece en el menú Compartir de TikTok, X, Instagram… y guarda el vídeo directamente en Fotos.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let host = UIHostingController(rootView: ShareView(items: items) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        })
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }
}

struct ShareView: View {
    let items: [NSExtensionItem]
    let close: () -> Void
    @State private var status = "Buscando el vídeo…"
    @State private var state = 0 // 0 trabajando, 1 hecho, 2 error

    var body: some View {
        VStack(spacing: 20) {
            AppMark(size: 64)
            VStack(spacing: 14) {
                switch state {
                case 0: ProgressView().controlSize(.large)
                case 1: Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                default: Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40)).foregroundStyle(.red)
                }
                Text(status)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .glassCard(cornerRadius: 28)
            if state == 2 {
                Button("Cerrar", action: close)
                    .font(.headline)
                    .glassButton(prominent: true)
                    .controlSize(.large)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Backdrop() }
        .tint(.brandViolet)
        .animation(.spring(duration: 0.4), value: state)
        .sensoryFeedback(trigger: state) { _, new in new == 1 ? .success : new == 2 ? .error : nil }
        .task {
            do {
                guard let link = await sharedLink() else { throw Failure("No he encontrado ningún enlace.") }
                // shortcut: la extensión no ve los ajustes de la app (haría falta un App Group, que
                // Sideloadly con Apple ID gratis no garantiza); usa el servidor por defecto.
                try await Downloader.save(link: link, server: Settings.defaultServer, apiKey: "") { status = $0 }
                status = "Guardado en Fotos"
                state = 1
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                close()
            } catch {
                status = error.localizedDescription
                state = 2
            }
        }
    }

    /// Las apps comparten un URL o un texto con el enlace dentro.
    func sharedLink() async -> String? {
        for provider in items.flatMap({ $0.attachments ?? [] }) {
            for type in [UTType.url, UTType.plainText] where provider.hasItemConformingToTypeIdentifier(type.identifier) {
                let item = try? await provider.loadItem(forTypeIdentifier: type.identifier)
                if let url = item as? URL, !url.isFileURL { return url.absoluteString }
                if let text = item as? String, let link = firstURL(in: text) { return link }
            }
        }
        return nil
    }
}
