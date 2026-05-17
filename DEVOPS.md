# 🏦 CBDC Master Settlement Server - DevOps Documentation

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Docker Deployment](#docker-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Production Deployment](#production-deployment)
- [Monitoring & Health Checks](#monitoring--health-checks)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This document provides comprehensive DevOps guidelines for deploying and maintaining the CBDC Master Settlement Server. The infrastructure is designed for enterprise-grade scalability, security, and reliability.

### Key Features
- ✅ **Multi-stage Docker builds** for optimal image size
- ✅ **Automated CI/CD** with GitHub Actions
- ✅ **Code quality gates** with ESLint
- ✅ **Security hardening** (non-root user, minimal base image)
- ✅ **Health checks** for container orchestration
- ✅ **Production-ready** configuration

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  server.js   │  │ Dockerfile   │  │  .github/    │      │
│  │              │  │              │  │  workflows/  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Push to main
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐      │
│  │  Lint    │→ │  Build   │→ │  Docker Validation   │      │
│  │ (ESLint) │  │  (npm)   │  │  (Multi-stage)       │      │
│  └──────────┘  └──────────┘  └──────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Deploy
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  Production Environment                      │
│  ┌────────────────────────────────────────────────┐         │
│  │         Docker Container (Alpine Linux)        │         │
│  │  ┌──────────────────────────────────────────┐ │         │
│  │  │  Node.js 20 (Non-root user: nodejs)     │ │         │
│  │  │  ┌────────────────────────────────────┐ │ │         │
│  │  │  │  Express Server (Port 3000)        │ │ │         │
│  │  │  │  ├─ Cryptographic Verification     │ │ │         │
│  │  │  │  ├─ Supabase PostgreSQL Client     │ │ │         │
│  │  │  │  └─ WebSocket Support              │ │ │         │
│  │  │  └────────────────────────────────────┘ │ │         │
│  │  └──────────────────────────────────────────┘ │         │
│  └────────────────────────────────────────────────┘         │
│                       │                                      │
│                       │ Secure Connection                    │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────┐         │
│  │      Supabase PostgreSQL (Cloud Vault)         │         │
│  │      Table: central_ledger                     │         │
│  └────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Required Software
- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher
- **Docker**: v20.10 or higher (for containerization)
- **Git**: For version control

### Cloud Services
- **Supabase Account**: For PostgreSQL database
  - Sign up at: https://supabase.com
  - Create a new project
  - Get your API credentials from Project Settings → API

---

## 💻 Local Development

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd CBDC-Master-Server
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Configure Environment Variables
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your actual credentials
# Required variables:
# - SUPABASE_URL
# - SUPABASE_KEY
# - PORT (optional, defaults to 3000)
```

### 4. Run the Server
```bash
# Development mode
npm run dev

# Production mode
npm start
```

### 5. Verify Server is Running
```bash
curl http://localhost:3000/
# Expected response: {"status":"active","node":"Simulated RBI CBDC Node (PostgreSQL Active)"}
```

### 6. Run Code Quality Checks
```bash
# Run ESLint
npm run lint

# Auto-fix linting issues
npm run lint:fix
```

---

## 🐳 Docker Deployment

### Build Docker Image
```bash
# Build the image
npm run docker:build

# Or manually:
docker build -t cbdc-master-server:latest .
```

### Run Docker Container
```bash
# Using npm script (requires .env file)
npm run docker:run

# Or manually with environment variables:
docker run -d \
  --name cbdc-server \
  -p 3000:3000 \
  -e SUPABASE_URL=your-url \
  -e SUPABASE_KEY=your-key \
  -e PORT=3000 \
  cbdc-master-server:latest
```

### Docker Image Details
- **Base Image**: `node:20-alpine` (minimal, secure)
- **Image Size**: ~150MB (optimized with multi-stage build)
- **User**: Non-root (`nodejs` user, UID 1001)
- **Health Check**: Built-in HTTP health check on port 3000
- **Security**: Minimal attack surface, no unnecessary packages

### Docker Commands Reference
```bash
# View running containers
docker ps

# View logs
docker logs cbdc-server

# Stop container
docker stop cbdc-server

# Remove container
docker rm cbdc-server

# Remove image
docker rmi cbdc-master-server:latest

# Execute shell in running container
docker exec -it cbdc-server sh
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The CI/CD pipeline automatically runs on:
- Push to `main` or `master` branch
- Pull requests to `main` or `master` branch

### Pipeline Stages

#### 1. **Code Quality Check (Lint)**
- Checks out code
- Sets up Node.js 20
- Installs dependencies
- Runs ESLint for code quality

#### 2. **Docker Build Validation**
- Builds Docker image using multi-stage Dockerfile
- Validates build success
- Uses GitHub Actions cache for faster builds
- Tags image with commit SHA

#### 3. **Pipeline Summary**
- Generates comprehensive summary
- Reports status of all jobs
- Provides deployment readiness status

### Viewing Pipeline Results

1. Go to your GitHub repository
2. Click on **Actions** tab
3. Select the latest workflow run
4. View detailed logs for each job

### Pipeline Configuration

The pipeline is defined in `.github/workflows/ci-cd.yml`. Key features:

- **Parallel Execution**: Lint and build run in sequence for safety
- **Caching**: npm and Docker layer caching for speed
- **Fail Fast**: Pipeline stops on first failure
- **Detailed Logging**: Comprehensive output for debugging

---

## 🚀 Production Deployment

### Deployment Options

#### Option 1: Docker on Cloud VM (AWS EC2, Azure VM, GCP Compute)

```bash
# 1. SSH into your server
ssh user@your-server-ip

# 2. Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 3. Clone repository
git clone <your-repo-url>
cd CBDC-Master-Server

# 4. Create .env file with production credentials
nano .env

# 5. Build and run
docker build -t cbdc-master-server:latest .
docker run -d \
  --name cbdc-server \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  cbdc-master-server:latest

# 6. Verify deployment
curl http://localhost:3000/
```

#### Option 2: Kubernetes Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cbdc-master-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cbdc-server
  template:
    metadata:
      labels:
        app: cbdc-server
    spec:
      containers:
      - name: cbdc-server
        image: cbdc-master-server:latest
        ports:
        - containerPort: 3000
        env:
        - name: SUPABASE_URL
          valueFrom:
            secretKeyRef:
              name: cbdc-secrets
              key: supabase-url
        - name: SUPABASE_KEY
          valueFrom:
            secretKeyRef:
              name: cbdc-secrets
              key: supabase-key
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: cbdc-server-service
spec:
  selector:
    app: cbdc-server
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
```

#### Option 3: Docker Compose (Multi-container setup)

```yaml
# docker-compose.yml
version: '3.8'

services:
  cbdc-server:
    build: .
    container_name: cbdc-master-server
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_KEY=${SUPABASE_KEY}
      - PORT=3000
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
```

### Production Checklist

- [ ] Environment variables configured securely
- [ ] Firewall rules configured (allow port 3000)
- [ ] SSL/TLS certificate installed (use reverse proxy like Nginx)
- [ ] Monitoring and logging configured
- [ ] Backup strategy for Supabase database
- [ ] Auto-restart policy enabled
- [ ] Health checks configured
- [ ] Resource limits set (CPU, memory)

---

## 📊 Monitoring & Health Checks

### Built-in Health Check

The Docker container includes a health check that runs every 30 seconds:

```bash
# Check container health status
docker inspect --format='{{.State.Health.Status}}' cbdc-server
```

Health check endpoint: `GET http://localhost:3000/`

Expected response:
```json
{
  "status": "active",
  "node": "Simulated RBI CBDC Node (PostgreSQL Active)"
}
```

### Monitoring Recommendations

1. **Application Monitoring**
   - Use PM2 for process management
   - Implement logging with Winston or Bunyan
   - Set up error tracking (Sentry, Rollbar)

2. **Infrastructure Monitoring**
   - CPU and memory usage
   - Network traffic
   - Disk I/O
   - Container restart count

3. **Database Monitoring**
   - Supabase dashboard for query performance
   - Connection pool status
   - Transaction throughput

### Logging

View container logs:
```bash
# Real-time logs
docker logs -f cbdc-server

# Last 100 lines
docker logs --tail 100 cbdc-server

# Logs with timestamps
docker logs -t cbdc-server
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Container Won't Start

**Symptom**: Container exits immediately after starting

**Solution**:
```bash
# Check logs
docker logs cbdc-server

# Common causes:
# - Missing environment variables
# - Invalid Supabase credentials
# - Port already in use

# Verify environment variables
docker exec cbdc-server env | grep SUPABASE
```

#### 2. Cannot Connect to Supabase

**Symptom**: "FATAL ERROR: Supabase credentials missing"

**Solution**:
```bash
# Verify .env file exists and has correct values
cat .env

# Test Supabase connection manually
curl -X GET "https://your-project.supabase.co/rest/v1/" \
  -H "apikey: your-key" \
  -H "Authorization: Bearer your-key"
```

#### 3. Port Already in Use

**Symptom**: "Error: listen EADDRINUSE: address already in use :::3000"

**Solution**:
```bash
# Find process using port 3000
# Windows:
netstat -ano | findstr :3000

# Linux/Mac:
lsof -i :3000

# Kill the process or use a different port
docker run -p 3001:3000 cbdc-master-server:latest
```

#### 4. ESLint Errors in CI/CD

**Symptom**: Pipeline fails at lint stage

**Solution**:
```bash
# Run lint locally to see errors
npm run lint

# Auto-fix issues
npm run lint:fix

# Commit fixes
git add .
git commit -m "fix: resolve linting issues"
git push
```

#### 5. Docker Build Fails

**Symptom**: "ERROR [internal] load metadata for docker.io/library/node:20-alpine"

**Solution**:
```bash
# Check Docker daemon is running
docker info

# Pull base image manually
docker pull node:20-alpine

# Retry build
docker build -t cbdc-master-server:latest .
```

### Debug Mode

Run container in interactive mode for debugging:
```bash
docker run -it --rm \
  --env-file .env \
  cbdc-master-server:latest \
  sh
```

---

## 🔐 Security Best Practices

1. **Never commit `.env` file** - Already in `.gitignore`
2. **Use secrets management** - For production, use AWS Secrets Manager, Azure Key Vault, or Kubernetes Secrets
3. **Regular updates** - Keep dependencies updated (`npm audit fix`)
4. **Network security** - Use firewall rules and VPC
5. **HTTPS only** - Use reverse proxy (Nginx, Traefik) with SSL
6. **Rate limiting** - Implement API rate limiting
7. **Input validation** - Already implemented in server.js

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Supabase Documentation](https://supabase.com/docs)
- [ESLint Rules](https://eslint.org/docs/rules/)

---

## 🤝 Support

For issues or questions:
1. Check this documentation
2. Review GitHub Actions logs
3. Check Docker container logs
4. Verify environment configuration

---

**Last Updated**: 2026-05-17  
**Version**: 1.0.0  
**Maintainer**: CBDC Development Team