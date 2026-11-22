import Foundation

// Comprobación rápida de Shared/Cobalt.swift. GitHub Actions: swiftc Shared/Cobalt.swift Tests/main.swift
func check(_ ok: Bool, _ what: String) {
    if !ok { print("FALLO: \(what)"); exit(1) }
}

check(firstURL(in: "Mira este vídeo https://vm.tiktok.com/ZMabc123/ jaja") == "https://vm.tiktok.com/ZMabc123/", "enlace dentro de texto")
check(firstURL(in: "https://x.com/user/status/123") == "https://x.com/user/status/123", "enlace solo")
check(firstURL(in: "hola") == nil, "texto sin enlace")

let tunnel = try parseCobalt(Data(#"{"status":"tunnel","url":"http://s/tunnel?id=1","filename":"tiktok_123.mp4"}"#.utf8))
check(tunnel.count == 1 && tunnel[0].ext == "mp4" && !tunnel[0].isPhoto, "tunnel de vídeo")

let photo = try parseCobalt(Data(#"{"status":"redirect","url":"http://s/a.jpg","filename":"instagram_1.jpg"}"#.utf8))
check(photo[0].isPhoto && photo[0].ext == "jpg", "redirect de foto")

let picker = try parseCobalt(Data(#"{"status":"picker","picker":[{"type":"photo","url":"http://s/1"},{"type":"video","url":"http://s/2"},{"type":"gif","url":"http://s/3"}]}"#.utf8))
check(picker.map(\.isPhoto) == [true, false, true] && picker.map(\.ext) == ["jpg", "mp4", "gif"], "carrusel")

var threw = false
do { _ = try parseCobalt(Data(#"{"status":"error","error":{"code":"error.api.link.invalid"}}"#.utf8)) } catch { threw = true }
check(threw, "error de cobalt lanza excepción")

print("OK: todas las comprobaciones pasan")
