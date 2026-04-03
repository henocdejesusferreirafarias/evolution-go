FROM golang:1.25.0-alpine AS build

# Instalar dependências do sistema (o 'git' já está aqui, o que é perfeito)
RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

WORKDIR /build

# 1. Copiar PRIMEIRO os arquivos de módulo do projeto principal
COPY go.mod go.sum ./

# 2. A MÁGICA AQUI: Em vez de tentar copiar do Easypanel, o Docker baixa o submódulo na hora.
# ATENÇÃO: Substitua a URL abaixo pelo link real do repositório da whatsmeow-lib que você está usando!
RUN git clone git@github.com:EvolutionAPI/whatsmeow.git ./whatsmeow-lib

# 3. Fazer o download das dependências aproveitando a pasta que o git acabou de baixar
RUN go mod download

# 4. Copiar o restante do código-fonte da aplicação
COPY . .

ARG VERSION=dev
RUN CGO_ENABLED=1 go build -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

# ==========================================
# ESTÁGIO FINAL
# ==========================================
FROM alpine:3.19.1 AS final

RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp

WORKDIR /app

COPY --from=build /build/server .
COPY --from=build /build/manager/dist ./manager/dist
COPY --from=build /build/VERSION ./VERSION

ENV TZ=America/Sao_Paulo

ENTRYPOINT ["/app/server"]
