import SwiftUI
import UIKit

@main
struct SaverApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @AppStorage("server") private var server = Settings.defaultServer
    @AppStorage("apiKey") private var apiKey = ""
    @State private var link = ""
    @State private var status = ""
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://…", text: $link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Pegar") {
                        link = UIPasteboard.general.url?.absoluteString ?? UIPasteboard.general.string ?? ""
                    }
                } header: {
                    Text("Enlace de TikTok, X o Instagram")
                } footer: {
                    Text("También puedes compartir el vídeo directamente a Saver desde la app.")
                }
                Section {
                    Button {
                        Task { await download() }
                    } label: {
                        if busy { ProgressView() } else { Text("Descargar a Fotos") }
                    }
                    .disabled(busy || link.isEmpty || server.isEmpty)
                    if !status.isEmpty {
                        Text(status).foregroundStyle(.secondary)
                    }
                }
                Section("Servidor cobalt") {
                    TextField(Settings.defaultServer, text: $server)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("API key (opcional)", text: $apiKey)
                }
            }
            .navigationTitle("Saver")
        }
    }

    func download() async {
        busy = true
        defer { busy = false }
        do {
            guard let url = firstURL(in: link) else { throw Failure("Eso no parece un enlace.") }
            try await Downloader.save(link: url, server: server, apiKey: apiKey) { status = $0 }
            status = "✅ Guardado en Fotos"
            link = ""
        } catch {
            status = "❌ " + error.localizedDescription
        }
    }
}
