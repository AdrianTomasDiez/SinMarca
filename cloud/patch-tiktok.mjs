// Parche a cobalt (se ejecuta al construir la imagen): TikToks +18 con la sesión de una cuenta.
// - acepta cookies "tiktok" en COOKIES_JSON
// - TikTok usa esas cookies
// - un vídeo +18 solo da error si de verdad no llega el enlace del vídeo
// Si cobalt cambia y algún trozo ya no está, la construcción falla en vez de quedar a medias.
import { readFileSync, writeFileSync } from "node:fs";

function patch(file, pairs) {
  let src = readFileSync(file, "utf8");
  for (const [from, to] of pairs) {
    if (!src.includes(from)) throw new Error(`parche: no encuentro en ${file}: ${from}`);
    src = src.replace(from, to);
  }
  writeFileSync(file, src);
}

patch("src/processing/cookie/manager.js", [["'twitter',", "'twitter',\n    'tiktok',"]]);
patch("src/processing/services/tiktok.js", [
  ['import { updateCookie } from "../cookie/manager.js";', 'import { getCookie, updateCookie } from "../cookie/manager.js";'],
  ["const cookie = new Cookie({});", "const cookie = getCookie('tiktok') || new Cookie({});"],
  ["if (detail.isContentClassified) {", "if (detail.isContentClassified && !detail.video?.playAddr) {"],
]);
console.log("parche tiktok aplicado");
