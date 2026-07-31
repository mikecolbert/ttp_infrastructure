FROM python-base:latest

WORKDIR "/app"

COPY ./src/ttp_sensor_api/requirements.txt /app
RUN uv self update
RUN --mount=type=cache,target=/root/.cache uv pip install -r requirements.txt

COPY src/ttp_sensor_api /app

# Make sure we have the latest web server if the bases are cached.
RUN --mount=type=cache,target=/root/.cache uv pip install --upgrade "granian[pname]"

# Set the command to run when the container starts (Granián)
ENTRYPOINT [  \
    "/venv/bin/granian",\
    "app:app", \
    "--host","0.0.0.0", \
    "--port","15001", \
    "--interface","wsgi", \
    "--no-ws", \
    "--workers","2", \
    "--backpressure", "40", \
    "--runtime-mode", "mt", \
    "--runtime-threads", "4",\
    "--log-level","info",\
    "--log", \
    "--process-name", \
    "granian [ttp-sensor-api]" \
    ]
