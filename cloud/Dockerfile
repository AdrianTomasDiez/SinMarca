# Servidor cobalt en la nube (Render; también vale para Hugging Face Spaces).
# Necesita el secreto KEYS_JSON = contenido de server/keys.json.
# API_URL se toma de RENDER_EXTERNAL_URL en Render; en otros sitios hay que definirla.
FROM ghcr.io/imputnet/cobalt:11

ENV PORT=7860 \
    API_KEY_URL=file:///tmp/keys.json \
    API_AUTH_REQUIRED=1

# helper.mjs escucha en PORT, arranca cobalt en el 9000 y añade /descargar para el Atajo.
COPY helper.mjs /app/helper.mjs

# La clave llega como secreto (no va en el código) y se escribe al arrancar.
# COOKIES_JSON (opcional) = sesión de X para vídeos +18: {"twitter":["auth_token=…; ct0=…"]}
CMD ["sh", "-c", "printf '%s' \"$KEYS_JSON\" > /tmp/keys.json && if [ -n \"$COOKIES_JSON\" ]; then printf '%s' \"$COOKIES_JSON\" > /tmp/cookies.json && export COOKIE_PATH=/tmp/cookies.json; fi && export API_URL=\"${API_URL:-$RENDER_EXTERNAL_URL/}\" && exec node helper.mjs"]
