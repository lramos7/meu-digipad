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

# Copia .env para dentro da imagem antes do build
# (ou use ARG/ENV se preferir)
COPY .env .env

# Build com variáveis corretas
RUN npm run build

ENV NODE_ENV=production

EXPOSE 3000

CMD ["npm", "run", "prod"]
