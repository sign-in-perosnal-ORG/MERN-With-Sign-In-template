# Stage 1: Build the React frontend
FROM node:20-alpine AS frontend-builder

WORKDIR /app/Frontend

COPY Frontend/package*.json Frontend/yarn.lock* ./
RUN npm install

COPY Frontend/ ./
RUN npm run build

# Stage 2: Backend runtime
FROM node:20-alpine AS backend

WORKDIR /app

COPY Backend/package*.json ./
RUN npm install --omit=dev

COPY Backend/ ./

# Copy the built frontend into the backend for static serving
COPY --from=frontend-builder /app/Frontend/dist ./public

EXPOSE 3000

CMD ["node", "src/server.js"]
