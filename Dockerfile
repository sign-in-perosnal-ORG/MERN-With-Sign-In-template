# ─────────────────────────────────────────────────────────────────────────────
# Stage 1 – frontend-builder
# Uses a lightweight Node 20 Alpine image just to compile the React app.
# This stage is discarded after the build; its output (dist/) is copied later.
# ─────────────────────────────────────────────────────────────────────────────

# Use the official Node.js 20 image (Alpine variant = minimal OS, smaller image)
FROM node:20-alpine AS frontend-builder

# Set the working directory inside the container for all subsequent commands
WORKDIR /app/Frontend

# Copy only the dependency manifests first so Docker can cache this layer.
# If package.json / yarn.lock haven't changed, npm install won't re-run on rebuild.
COPY Frontend/package*.json Frontend/yarn.lock* ./

# Install all frontend dependencies (including dev deps needed to run Vite)
RUN npm install

# Copy the rest of the frontend source code into the container
COPY Frontend/ ./

# Run Vite's production build — outputs optimised static files to ./dist
RUN npm run build


# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 – backend (final image)
# Only this stage ends up in the final Docker image that gets shipped/run.
# ─────────────────────────────────────────────────────────────────────────────

# Start from the same base image for consistency
FROM node:20-alpine AS backend

# Set the working directory for the backend application
WORKDIR /app

# Copy only the backend dependency manifests to leverage Docker layer caching
COPY Backend/package*.json ./

# Install only production dependencies (skips devDependencies to keep image lean)
RUN npm install --omit=dev

# Copy the full backend source code into the container
COPY Backend/ ./

# Copy the compiled React app from the builder stage into ./public so the
# Express server can optionally serve it as static files
COPY --from=frontend-builder /app/Frontend/dist ./public

# Inform Docker (and users) that this container listens on port 3000
EXPOSE 3000

# Start the Express server — this is the process that runs when the container starts
CMD ["node", "src/server.js"]
