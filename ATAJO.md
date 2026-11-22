# Atajo "Saver" para iPhone (sin instalar nada)

Hace lo mismo que la app: desde **Compartir** en TikTok, X o Instagram guarda el vídeo en Fotos.
Lo creas una vez en tu iPhone y se lo pasas a quien quieras con un enlace de iCloud.

Necesitas dos datos:
- **Servidor:** `https://saver-n6tc.onrender.com/`
- **Clave:** el texto entre comillas de `server/keys.json` (tipo `1a2b3c4d-…`). No la publiques.

Los nombres de las acciones son los de iOS en español; búscalas con el buscador de acciones.

## 1. Crear el atajo

App **Atajos** → **+** → arriba pulsa el nombre y llámalo **Saver** (elige un icono de flecha hacia abajo).

Pulsa **ⓘ** (o el nombre → Detalles) y activa **Mostrar en hoja de compartir**.
Arriba aparecerá *Recibir … de Hoja de compartir*:
- Toca el tipo y deja marcados solo **URL** y **Texto**.
- En *Si no hay entrada*, elige **Obtener portapapeles** (así también funciona copiando el enlace y abriendo el atajo).

## 2. Acciones (en este orden)

1. **Obtener URL de la entrada** → entrada: *Entrada del atajo*.
2. **Obtener elemento de la lista** → *Primer elemento* de *URL*.
3. **Obtener contenido de la URL**
   - URL: `https://saver-n6tc.onrender.com/`
   - Pulsa **Mostrar más**:
     - Método: **POST**
     - Cabeceras (añade 3):
       - `Accept` → `application/json`
       - `Content-Type` → `application/json`
       - `Authorization` → `Api-Key TU-CLAVE` (escribe "Api-Key", un espacio y la clave)
     - Cuerpo de la solicitud: **JSON**, añade 3 campos:
       - `url` (Texto) → la variable *Elemento de la lista*
       - `videoQuality` (Texto) → `max`
       - `allowH265` (Booleano) → activado
4. **Obtener valor del diccionario** → *Valor* de la clave `status` en *Contenido de la URL*.
5. **Si** *Valor del diccionario* **es** `picker` (carrusel con varias fotos/vídeos):
   1. **Obtener valor del diccionario** → clave `picker` en *Contenido de la URL*.
   2. **Repetir con cada** elemento de ese valor:
      1. **Obtener valor del diccionario** → clave `url` en *Elemento de repetición*.
      2. **Obtener contenido de la URL** → esa URL (método GET, sin nada más).
      3. **Guardar en el álbum de fotos** → *Contenido de la URL*, álbum *Recientes*.
6. **De lo contrario**:
   1. **Obtener valor del diccionario** → clave `url` en el primer *Contenido de la URL* (el del paso 3).
   2. **Obtener contenido de la URL** → esa URL (GET).
   3. **Guardar en el álbum de fotos** → *Contenido de la URL*.
7. **Finalizar si** (aparece solo).
8. **Mostrar notificación** → `Guardado en Fotos ✅`.

Si algo falla, el atajo se para y muestra el error de iOS. Si el servidor estaba dormido,
la primera vez puede tardar hasta un minuto.

## 3. Probar

En TikTok: **Compartir → Más → Saver** (en X/Instagram: Compartir → Saver).
La primera vez iOS pregunta si permites conectarte a `saver-n6tc.onrender.com` y guardar en Fotos:
**Permitir siempre**.

## 4. Pasárselo a un amigo

Mantén pulsado el atajo → **Compartir** → **Copiar enlace de iCloud** y mándaselo.
Él lo abre en su iPhone → **Añadir atajo**. Ya está: no caduca ni hay que instalar nada.

La clave va dentro del atajo: dáselo solo a gente de confianza. Si se filtra, se cambia la clave
en `server/keys.json`, en Render (`KEYS_JSON`) y en GitHub (`COBALT_API_KEY`), y se rehace el atajo.
