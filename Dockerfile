FROM node:20-bookworm

# Instala dependências de sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphicsmagick \
    ghostscript \
    libreoffice \
    && sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pm2

WORKDIR /usr/src/app

# Copia arquivos e instala dependências
COPY package*.json ./
RUN npm install

# Copia o resto do código
COPY . .

# CRUCIAL: O Build precisa das variáveis de ambiente durante a compilação
# Substitua a URL abaixo se ela mudar
ARG DOMAIN=https://aicortix-digipad.s1q8w8.easypanel.host
ENV DOMAIN=$DOMAIN
ENV NODE_ENV=production

RUN npm run build

EXPOSE 3000

# Garante que as pastas de uploads existam
RUN mkdir -p public/uploads public/temp

CMD ["pm2-runtime", "start", "ecosystem.config.cjs", "--env", "production"]
