# ---- Build stage ----
FROM node:24-alpine AS builder

# Accept build arguments (for inline client‑side env vars, if any)
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

COPY package*.json ./
RUN npm ci

COPY . .

# Write .env for Vite to inline (if it uses import.meta.env)
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

# Build the client bundle
RUN npm run build

# ---- Production stage ----
FROM node:24-alpine

WORKDIR /app

# Copy built client files and server files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/server ./server  # if server code is in a 'server' folder
# If server entry is at root, also copy that:
COPY --from=builder /app/index.js ./
# Or if there's a specific server file, adjust accordingly

# Install only production dependencies (including any server dependencies)
RUN npm ci --omit=dev

# Copy the .env file from builder (or we can set environment variables at runtime)
COPY --from=builder /app/.env ./.env

# Expose the port (defined in .env, default 4173)
EXPOSE 4173

# Start the Node server (adjust the command to match your server entry)
CMD ["npm", "start"]
