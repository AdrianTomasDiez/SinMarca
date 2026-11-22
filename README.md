# SinMarca

App de iPhone para guardar en Fotos vídeos de TikTok, X e Instagram sin marca de agua.
Usa un servidor [cobalt](https://github.com/imputnet/cobalt) propio para sacar el vídeo original.
Solo para uso personal: no resubas vídeos de otros.

## 1. Servidor (en el PC)

1. Abre Docker Desktop.
2. En la carpeta `server`: `docker compose up -d`
3. Si la IP del PC no es `192.168.1.15`, cámbiala en `server/docker-compose.yml` y en la app.

El iPhone tiene que estar en la misma wifi y el PC encendido.

## 2. Compilar la app (GitHub Actions)

1. Sube este proyecto a un repositorio de GitHub (si es público, los minutos de Mac son gratis).
2. Cada `push` compila. En la pestaña **Actions** → última ejecución → descarga `SinMarca-ipa`.

## 3. Instalar en el iPhone (desde Windows)

1. Instala iTunes (versión web de Apple, no la de Microsoft Store) y [Sideloadly](https://sideloadly.io).
2. Conecta el iPhone por cable, arrastra `SinMarca.ipa` a Sideloadly y entra con tu Apple ID.
3. En el iPhone: Ajustes › General › VPN y gestión de dispositivos → confía en tu Apple ID.
4. Activa el Modo desarrollador si lo pide (Ajustes › Privacidad y seguridad).

Con Apple ID gratuito la app caduca a los 7 días: vuelve a instalarla con Sideloadly
(o usa AltStore, que la renueva sola por wifi).

## Uso

Copia el enlace en TikTok/X/Instagram → abre SinMarca → **Pegar** → **Descargar a Fotos**.
