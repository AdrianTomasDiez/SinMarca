import Foundation

// Solo Foundation: GitHub Actions compila este archivo junto a Tests/main.swift para comprobarlo.

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

/// Convierte la respuesta de cobalt en la lista de archivos a guardar.
/// Formato: github.com/imputnet/cobalt/blob/main/docs/api.md
func parseCobalt(_ data: Data) throws -> [Media] {
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

/// Primer enlace web dentro de un texto ("Mira este vídeo https://vm.tiktok.com/…").
func firstURL(in text: String) -> String? {
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    return detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        .compactMap(\.url)
        .first { $0.scheme == "http" || $0.scheme == "https" }?
        .absoluteString
}
