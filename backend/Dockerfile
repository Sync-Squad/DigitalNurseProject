# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies for native modules (bcrypt)
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json .npmrc ./
COPY prisma ./prisma/

# Install all dependencies (including devDeps for building)
RUN npm ci --prefer-offline --no-audit

# Generate Prisma client (dummy URL for build-time validation)
RUN DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy" npx prisma generate

# Copy source code and build
COPY . .
RUN npm run build

# Prune devDependencies, keep only production deps
RUN npm prune --omit=dev

# Stage 2: Production
FROM node:20-alpine AS production

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001 -G nodejs

# Copy production node_modules (with generated Prisma client) from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy built application and prisma schema (needed for migrations)
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/package.json ./

# Set ownership
RUN chown -R nestjs:nodejs /app

USER nestjs

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]

# Run database migrations then start the app
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main.js"]
