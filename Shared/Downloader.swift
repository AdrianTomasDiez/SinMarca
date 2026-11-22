import Foundation
import Photos

// Config (servidor y clave) la genera GitHub Actions desde sus secretos: ver .github/workflows/build.yml.

@MainActor
enum Downloader {
    /// Pide el vídeo a cobalt, lo descarga y lo guarda en Fotos. `progress` recibe el texto a mostrar.
    static func save(link: String, server: String, apiKey: String, progress: (String) -> Void) async throws {
        guard let endpoint = URL(string: server), endpoint.scheme != nil else {
            throw Failure("La dirección del servidor no es válida.")
        }
        progress("Buscando el vídeo…")
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty { req.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization") }
        // Máxima calidad; H.265 deja a TikTok dar su mejor versión (el iPhone lo reproduce sin problema).
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "url": link, "videoQuality": "max", "allowH265": true,
        ] as [String: Any])
        let (data, _) = try await URLSession.shared.data(for: req)
        let items = try parseCobalt(data)

        guard await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized else {
            throw Failure("Sin permiso para guardar en Fotos (Ajustes › Saver › Fotos).")
        }
        for (i, item) in items.enumerated() {
            progress(items.count == 1 ? "Descargando…" : "Descargando \(i + 1) de \(items.count)…")
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
    }
}
