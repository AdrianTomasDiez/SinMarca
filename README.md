# Saver

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
2. Cada `push` compila. En la pestaña **Actions** → última ejecución → descarga `Saver-ipa`.

## 3. Instalar en el iPhone (desde Windows)

1. Instala iTunes (versión web de Apple, no la de Microsoft Store) y [Sideloadly](https://sideloadly.io).
2. Conecta el iPhone por cable, arrastra `Saver.ipa` a Sideloadly y entra con tu Apple ID.
3. En el iPhone: Ajustes › General › VPN y gestión de dispositivos → confía en tu Apple ID.
4. Activa el Modo desarrollador si lo pide (Ajustes › Privacidad y seguridad).

Con Apple ID gratuito la app caduca a los 7 días: vuelve a instalarla con Sideloadly
(o usa AltStore, que la renueva sola por wifi).

## Uso

- **Desde la app de vídeos:** Compartir → Saver (en TikTok: Compartir → Más). Se guarda solo en Fotos.
  Si no ves Saver, desliza los iconos hasta el final → Más → actívala.
- **Desde Saver:** copia el enlace → abre Saver → **Pegar** → **Descargar a Fotos**.

Abre Saver una vez antes de usar Compartir, para aceptar los permisos de red local y de Fotos.
El servidor y la clave se meten en la app al compilar, desde GitHub:
Settings → Secrets and variables → Actions → variable `SERVER_URL` y secreto `COBALT_API_KEY`.

## Servidor en la nube (Render, gratis)

1. En https://dashboard.render.com → **New → Blueprint** → elige este repositorio.
2. Cuando pida `KEYS_JSON`, pega el contenido de `server/keys.json`.
3. La dirección queda como `https://saver-xxxx.onrender.com`. Ponla en la variable `SERVER_URL` de GitHub.

`.github/workflows/despertar.yml` lo visita cada 10 minutos para que no se duerma.
