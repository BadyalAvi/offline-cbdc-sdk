# ══════════════════════════════════════════════════════════════
# 🏦 CBDC Master Settlement Server - Production Dockerfile
# ══════════════════════════════════════════════════════════════
# Multi-stage build for optimal security and minimal image size
# Base: Alpine Linux (minimal attack surface)
# Security: Non-root user execution
# Optimization: Layer caching and production-only dependencies
# ══════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────
# STAGE 1: Builder - Install all dependencies
# ──────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# Install ALL dependencies (including devDependencies for potential build steps)
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application source code
COPY . .

# ──────────────────────────────────────────────────────────────
# STAGE 2: Production - Minimal runtime image
# ──────────────────────────────────────────────────────────────
FROM node:20-alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code from builder stage
COPY --from=builder /app/server.js ./

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 3000

# Health check for container orchestration (Kubernetes, ECS, etc.)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "server.js"]

# Made with Bob
