FROM node:18-alpine AS builder

RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash openssl python3 make g++ dos2unix

WORKDIR /evolution

COPY ./package*.json ./
COPY ./tsconfig.json ./
COPY ./tsup.config.ts ./

RUN npm install --legacy-peer-deps

COPY ./src ./src
COPY ./public ./public
COPY ./prisma ./prisma
COPY ./manager ./manager
COPY ./.env.example ./.env
COPY ./runWithProvider.js ./
COPY ./Docker ./Docker

RUN chmod +x ./Docker/scripts/* && dos2unix ./Docker/scripts/*
RUN ./Docker/scripts/generate_database.sh
RUN npm run build

FROM node:18-alpine AS final

RUN apk update && apk add --no-cache tzdata ffmpeg bash openssl

WORKDIR /evolution

COPY --from=builder /evolution ./

EXPOSE 8080
ENTRYPOINT ["/bin/bash", "-c", ". ./Docker/scripts/deploy_database.sh && npm run start:prod" ]
