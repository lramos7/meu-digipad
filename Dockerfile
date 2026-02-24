FROM node:20-alpine

WORKDIR /app

# Dependências para build nativo (eiows, sharp, etc.)
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    build-base

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["node", "dist/server/entry.mjs"]
