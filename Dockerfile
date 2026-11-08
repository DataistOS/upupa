# Dockerfile

FROM dart:3.3 AS frontend-builder
WORKDIR /app/frontend

COPY upupa_frontend/pubspec.* ./
RUN dart pub get

COPY upupa_frontend/ ./

RUN flutter build web --release

FROM golang:1.22-alpine AS backend-builder
WORKDIR /app/backend

COPY upupa_backend/go.mod upupa_backend/go.sum ./
RUN go mod download

COPY upupa_backend/ ./

COPY --from=frontend-builder /app/frontend/build/web ./internal/server/public

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/bin/upupa ./cmd/serve.go

FROM alpine:latest
WORKDIR /app

RUN apk --no-cache add ca-certificates

COPY --from=backend-builder /app/bin/upupa /app/upupa

EXPOSE 8090

CMD ["./upupa", "serve"]