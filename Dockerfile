FROM node:20-bookworm

RUN apt-get update && apt-get install -y \
    graphicsmagick \
    ghostscript \
    libreoffice \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

RUN npm install -g pm2

ENV NODE_ENV=production

EXPOSE 3000

CMD ["pm2-runtime", "ecosystem.config.cjs"]
