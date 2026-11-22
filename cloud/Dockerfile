# Servidor cobalt en la nube (Render; también vale para Hugging Face Spaces).
# Necesita el secreto KEYS_JSON = contenido de server/keys.json.
# API_URL se toma de RENDER_EXTERNAL_URL en Render; en otros sitios hay que definirla.
FROM ghcr.io/imputnet/cobalt:11

ENV API_PORT=7860 \
    API_KEY_URL=file:///tmp/keys.json \
    API_AUTH_REQUIRED=1

# La clave llega como secreto (no va en el código) y se escribe al arrancar.
CMD ["sh", "-c", "printf '%s' \"$KEYS_JSON\" > /tmp/keys.json && export API_URL=\"${API_URL:-$RENDER_EXTERNAL_URL/}\" && exec node src/cobalt"]
