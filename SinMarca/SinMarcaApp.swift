import SwiftUI
import Photos

@main
struct SinMarcaApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @AppStorage("server") private var server = "http://192.168.1.15:9000"
    @AppStorage("apiKey") private var apiKey = ""
    @State private var link = ""
    @State private var status = ""
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Enlace de TikTok, X o Instagram") {
                    TextField("https://…", text: $link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    // PasteButton no muestra el aviso de "permitir pegar" de iOS.
                    PasteButton(payloadType: String.self) { strings in
                        link = strings.first ?? ""
                    }
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
                    TextField("http://192.168.1.15:9000", text: $server)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("API key (opcional)", text: $apiKey)
                }
            }
            .navigationTitle("SinMarca")
        }
    }

    func download() async {
        busy = true
        defer { busy = false }
        do {
            status = "Buscando el vídeo…"
            let items = try await resolve(link.trimmingCharacters(in: .whitespacesAndNewlines))
            guard await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized else {
                throw Failure("Sin permiso para guardar en Fotos (Ajustes › SinMarca › Fotos).")
            }
            for (i, item) in items.enumerated() {
                status = "Descargando \(i + 1) de \(items.count)…"
                let (tmp, response) = try await URLSession.shared.download(from: item.url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw Failure("El servidor no pudo entregar el archivo.")
                }
                // Fotos deduce el tipo por la extensión, así que renombramos el temporal.
                let file = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + "." + item.ext)
                try FileManager.default.moveItem(at: tmp, to: file)
                defer { try? FileManager.default.removeItem(at: file) }
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.forAsset()
                        .addResource(with: item.isPhoto ? .photo : .video, fileURL: file, options: nil)
                }
            }
            status = "✅ Guardado en Fotos"
            link = ""
        } catch {
            status = "❌ " + error.localizedDescription
        }
    }

    /// Pide a cobalt el enlace directo (sin marca de agua). Documentación: github.com/imputnet/cobalt/blob/main/docs/api.md
    func resolve(_ link: String) async throws -> [Media] {
        guard let endpoint = URL(string: server), endpoint.scheme != nil else {
            throw Failure("La dirección del servidor no es válida.")
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty { req.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONEncoder().encode(["url": link])

        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(CobaltResponse.self, from: data)
        switch res.status {
        case "tunnel", "redirect":
            guard let url = res.url.flatMap(URL.init(string:)) else { throw Failure("Respuesta sin enlace.") }
            let ext = URL(fileURLWithPath: res.filename ?? "").pathExtension.lowercased()
            let photoExts = ["jpg", "jpeg", "png", "webp", "heic", "gif"]
            return [Media(url: url, ext: ext.isEmpty ? "mp4" : ext, isPhoto: photoExts.contains(ext))]
        case "picker": // carrusel de Instagram, varios vídeos de X, etc.: se guarda todo
            return (res.picker ?? []).compactMap { item in
                guard let url = URL(string: item.url) else { return nil }
                switch item.type {
                case "photo": return Media(url: url, ext: "jpg", isPhoto: true)
                case "gif": return Media(url: url, ext: "gif", isPhoto: true)
                default: return Media(url: url, ext: "mp4", isPhoto: false)
                }
            }
        case "error":
            throw Failure("El servidor dijo: \(res.error?.code ?? "error desconocido")")
        default:
            throw Failure("Respuesta no soportada: \(res.status)")
        }
    }
}

struct Media {
    let url: URL
    let ext: String
    let isPhoto: Bool
}

struct Failure: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

private struct CobaltResponse: Decodable {
    struct Item: Decodable { let type: String; let url: String }
    struct Info: Decodable { let code: String }
    let status: String
    let url: String?
    let filename: String?
    let picker: [Item]?
    let error: Info?
}
