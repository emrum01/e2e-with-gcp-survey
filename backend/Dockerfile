# Build stage
FROM golang:1.22-bullseye AS builder
WORKDIR /app

# 依存関係のコピーとダウンロード
COPY go.* ./
RUN go mod download

# ソースコードのコピーとビルド
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/api

# Runtime stage
FROM gcr.io/distroless/static-debian12
WORKDIR /app

# ビルドしたバイナリのコピー
COPY --from=builder /app/server .

EXPOSE 8080
USER nonroot:nonroot

CMD ["./server"]
