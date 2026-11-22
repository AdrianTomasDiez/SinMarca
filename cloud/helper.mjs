// Puerta pública del servidor. GET /descargar?key=CLAVE&url=ENLACE redirige al vídeo (para el Atajo);
// todo lo demás (la app Saver, las descargas /tunnel) pasa tal cual a cobalt, que corre en el puerto 9000.
import http from "node:http";
import { spawn } from "node:child_process";

const PORT = Number(process.env.PORT || 7860);
const COBALT = "http://127.0.0.1:9000";

const cobalt = spawn("node", ["src/cobalt"], { stdio: "inherit", env: { ...process.env, API_PORT: "9000" } });
cobalt.on("exit", (code) => process.exit(code ?? 1)); // si cobalt cae, que Render reinicie todo

function send(res, code, text) {
  res.writeHead(code, { "Content-Type": "text/plain; charset=utf-8" }).end(text);
}

async function descargar(req, res) {
  // Atajos a veces codifica la dirección (&, =, :, /…): se decodifica entera y se buscan las piezas.
  let raw = req.url;
  try { raw = decodeURIComponent(raw); } catch {}
  const key = raw.match(/key=([0-9a-f-]{36})/i)?.[1];
  const link = raw.match(/https?:\/\/\S+/)?.[0]; // el primer enlace es el del vídeo (puede traer sus ? y &)
  if (!key || !link) {
    const seen = raw.replace(/key=[0-9a-f-]*/i, "key=…");
    return send(res, 400, `Error: falta ${key ? "el enlace del vídeo" : "la clave"}. Ha llegado: ${seen}`);
  }

  const r = await fetch(COBALT + "/", {
    method: "POST",
    headers: { Accept: "application/json", "Content-Type": "application/json", Authorization: `Api-Key ${key}` },
    body: JSON.stringify({ url: link, videoQuality: "max", allowH265: true }),
  });
  const data = await r.json();
  // shortcut: en carruseles el Atajo guarda solo el primero; la app Saver los guarda todos.
  const target = data.url ?? data.picker?.[0]?.url;
  if (!target) return send(res, 502, `Error: ${data.error?.code ?? data.status}`);
  res.writeHead(302, { Location: target }).end();
}

http
  .createServer((req, res) => {
    if (req.url.startsWith("/descargar")) {
      return descargar(req, res).catch((e) => send(res, 502, `Error: ${e.message}`));
    }
    const upstream = http.request(COBALT + req.url, { method: req.method, headers: req.headers }, (r) => {
      res.writeHead(r.statusCode, r.headers);
      r.pipe(res);
    });
    upstream.on("error", (e) => send(res, 502, `Error: ${e.message}`));
    req.pipe(upstream);
  })
  .listen(PORT, () => console.log(`saver helper en el puerto ${PORT}`));
