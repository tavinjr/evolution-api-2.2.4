# Etapa de build
FROM node:18-alpine AS builder

RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash openssl python3 make g++ dos2unix

LABEL version="2.2.4" description="Api to control whatsapp features through http requests." 
LABEL maintainer="Davidson Gomes" git="https://github.com/tavinjr/evolution-api-2.2.4"
LABEL contact="contato@evolution-api.com"

WORKDIR /evolution

COPY ./package*.json ./
COPY ./tsconfig.json ./
COPY ./tsup.config.ts ./

# instala dependências com mais tolerância
RUN npm install --legacy-peer-deps

COPY ./src ./src
COPY ./public ./public
COPY ./prisma ./prisma
COPY ./manager ./manager
COPY ./.env.example ./.env
COPY ./runWithProvider.js ./
COPY ./Docker ./Docker

# corrige scripts sh
RUN chmod +x ./Docker/scripts/* && dos2unix ./Docker/scripts/*

# gera o banco
RUN ./Docker/scripts/generate_database.sh

# compila o projeto
RUN npm run build

# Etapa final
FROM node:18-alpine AS final

RUN apk update && \
    apk add --no-cache tzdata ffmpeg bash openssl

ENV TZ=America/Sao_Paulo
ENV DOCKER_ENV=true

WORKDIR /evolution

COPY --from=builder /evolution/package.json ./package.json
COPY --from=builder /evolution/package-lock.json ./package-lock.json
COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/prisma ./prisma
COPY --from=builder /evolution/manager ./manager
COPY --from=builder /evolution/public ./public
COPY --from=builder /evolution/.env ./.env
COPY --from=builder /evolution/Docker ./Docker
COPY --from=builder /evolution/runWithProvider.js ./runWithProvider.js
COPY --from=builder /evolution/tsup.config.ts ./tsup.config.ts

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "-c", ". ./Docker/scripts/deploy_database.sh && npm run start:prod" ]
