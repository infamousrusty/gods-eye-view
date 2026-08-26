# ---- Build stage ----
FROM node:24-alpine AS builder

# Declare all build arguments (your full list)
ARG GOOGLE_MAPS_API_KEY
ARG CESIUM_ION_TOKEN
ARG OPENAI_API_KEY
ARG OPENAI_REALTIME_MODEL
ARG OPENAI_REALTIME_MODEL_MINI
ARG OPENAI_REALTIME_VOICE
ARG OPENAI_REALTIME_REASONING_EFFORT
ARG OPENAI_REALTIME_CONTEXT_TOKENS
ARG OPENAI_REALTIME_CONTEXT_RETENTION
ARG OPENAI_HUD_SUMMARY_MODEL
ARG OPENSKY_AUTH_MODE
ARG OPENSKY_CLIENT_ID
ARG OPENSKY_CLIENT_SECRET
ARG PORT
ARG VITE_AIS_LIVE_API_URL
ARG VITE_AIS_LIVE_MAX_ROWS
ARG VITE_AIS_LIVE_LABEL_MAX_ROWS
ARG AISSTREAM_API_KEY
ARG TOMTOM_API_KEY
ARG FIRMS_MAP_KEY

WORKDIR /app

# Copy package files and install
COPY package*.json ./
RUN npm ci

# Copy source
COPY . .

# ---- Create .env file from build arguments ----
RUN echo "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY" > .env && \
    echo "CESIUM_ION_TOKEN=$CESIUM_ION_TOKEN" >> .env && \
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env && \
    echo "OPENAI_REALTIME_MODEL=$OPENAI_REALTIME_MODEL" >> .env && \
    echo "OPENAI_REALTIME_MODEL_MINI=$OPENAI_REALTIME_MODEL_MINI" >> .env && \
    echo "OPENAI_REALTIME_VOICE=$OPENAI_REALTIME_VOICE" >> .env && \
    echo "OPENAI_REALTIME_REASONING_EFFORT=$OPENAI_REALTIME_REASONING_EFFORT" >> .env && \
    echo "OPENAI_REALTIME_CONTEXT_TOKENS=$OPENAI_REALTIME_CONTEXT_TOKENS" >> .env && \
    echo "OPENAI_REALTIME_CONTEXT_RETENTION=$OPENAI_REALTIME_CONTEXT_RETENTION" >> .env && \
    echo "OPENAI_HUD_SUMMARY_MODEL=$OPENAI_HUD_SUMMARY_MODEL" >> .env && \
    echo "OPENSKY_AUTH_MODE=$OPENSKY_AUTH_MODE" >> .env && \
    echo "OPENSKY_CLIENT_ID=$OPENSKY_CLIENT_ID" >> .env && \
    echo "OPENSKY_CLIENT_SECRET=$OPENSKY_CLIENT_SECRET" >> .env && \
    echo "PORT=$PORT" >> .env && \
    echo "VITE_AIS_LIVE_API_URL=$VITE_AIS_LIVE_API_URL" >> .env && \
    echo "VITE_AIS_LIVE_MAX_ROWS=$VITE_AIS_LIVE_MAX_ROWS" >> .env && \
    echo "VITE_AIS_LIVE_LABEL_MAX_ROWS=$VITE_AIS_LIVE_LABEL_MAX_ROWS" >> .env && \
    echo "AISSTREAM_API_KEY=$AISSTREAM_API_KEY" >> .env && \
    echo "TOMTOM_API_KEY=$TOMTOM_API_KEY" >> .env && \
    echo "FIRMS_MAP_KEY=$FIRMS_MAP_KEY" >> .env

# Build the app (it will read .env)
RUN npm run build

# ---- Production stage ----
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
