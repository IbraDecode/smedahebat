FROM node:22-alpine AS builder
WORKDIR /app
COPY apps/api/package.json ./
RUN npm install
COPY apps/api/ .
RUN npm run build

FROM node:22-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY apps/api/package.json ./
EXPOSE 4000
CMD ["node", "dist/main"]
