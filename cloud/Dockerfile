# Servidor cobalt para Hugging Face Spaces (Docker, CPU gratis).
# En el Space hay que definir:
#   Variable API_URL  = https://<usuario>-<space>.hf.space/
#   Secreto  KEYS_JSON = contenido de server/keys.json
FROM ghcr.io/imputnet/cobalt:11

ENV API_PORT=7860 \
    API_KEY_URL=file:///tmp/keys.json \
    API_AUTH_REQUIRED=1

# La clave llega como secreto (no va en el código) y se escribe al arrancar.
CMD ["sh", "-c", "printf '%s' \"$KEYS_JSON\" > /tmp/keys.json && exec node src/cobalt"]
