# Build from plugins/presentations: docker compose -f hosted/docker-compose.yml build
FROM python:3.13-slim
RUN apt-get update && apt-get install -y --no-install-recommends chromium git fonts-liberation && rm -rf /var/lib/apt/lists/*
COPY skills/editing-presentations/assets/server.py skills/editing-presentations/assets/deck_source.py \
     skills/editing-presentations/assets/overlay.js skills/editing-presentations/assets/overlay-edit.js \
     skills/editing-presentations/assets/overlay-gates.js hosted/picker.py /app/
# Chromium's own sandbox needs privileges a container does not have. It only ever loads the deck from 127.0.0.1.
ENV DECK_EDITOR_CHROME_ARGS="--no-sandbox --disable-gpu" HOME=/tmp
ENTRYPOINT ["python3", "/app/picker.py"]
