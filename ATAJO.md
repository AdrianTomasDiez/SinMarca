# Atajo "Saver" para iPhone (sin instalar nada)

Desde **Compartir** en TikTok, X o Instagram guarda el vídeo en Fotos.
Lo creas una vez en tu iPhone (2 minutos) y se lo pasas a quien quieras con un enlace de iCloud.

Necesitas tu **clave**: el texto entre comillas de `server/keys.json` (tipo `1a2b3c4d-…`). No la publiques.

## 1. Crear el atajo

App **Atajos** → **+** → arriba pulsa el nombre y llámalo **Saver**.

Pulsa **ⓘ** y activa **Mostrar en hoja de compartir**. Arriba aparecerá *Recibir … de Hoja de compartir*:
- Toca el tipo y deja marcados solo **URL** y **Texto**.
- En *Si no hay entrada*, elige **Obtener portapapeles** (así también funciona copiando el enlace y abriendo el atajo).

## 2. Las 2 acciones

1. **Obtener contenido de la URL**. En el campo URL pega esto (con tu clave en vez de `TU-CLAVE`):

   ```
   https://saver-n6tc.onrender.com/descargar?key=TU-CLAVE&url=
   ```
   Con el cursor al final, toca **Entrada del atajo** en la barra de encima del teclado.
   Debe quedar `…&url=` seguido de una burbuja azul **Entrada del atajo**.
2. **Guardar en el álbum de fotos**.

(El servidor saca el enlace del vídeo aunque la app comparta un texto con el enlace dentro.)

Listo. Si el servidor estaba dormido, la primera vez puede tardar hasta un minuto.
En carruseles de Instagram el atajo guarda solo el primer elemento (la app Saver los guarda todos).

## 3. Probar

En TikTok: **Compartir → Más → Saver** (en X/Instagram: Compartir → Saver).
La primera vez iOS pregunta si permites conectarte a `saver-n6tc.onrender.com` y guardar en Fotos:
**Permitir siempre**.

Si falla, iOS muestra un texto tipo `Error: error.api.…`: ese es el motivo que da el servidor.

## 4. Pasárselo a un amigo

Mantén pulsado el atajo → **Compartir** → **Copiar enlace de iCloud** y mándaselo.
Él lo abre en su iPhone → **Añadir atajo**. No caduca ni hay que instalar nada.

La clave va dentro del atajo: dáselo solo a gente de confianza. Si se filtra, se cambia la clave
en `server/keys.json`, en Render (`KEYS_JSON`) y en GitHub (`COBALT_API_KEY`), y se rehace el atajo.
