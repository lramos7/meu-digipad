FROM node:20-bookworm

# 1. Instala dependências de sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphicsmagick \
    ghostscript \
    libreoffice \
    && sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pm2

WORKDIR /usr/src/app

# 2. Instala dependências do Node
COPY package*.json ./
RUN npm install

# 3. Copia o código
COPY . .


# Forçamos a instalação limpa e o build com a variável de ambiente injetada
RUN npm run build

# Permissões de escrita para as pastas de dados
RUN mkdir -p public/uploads public/temp public/export && chmod -R 777 public/

EXPOSE 3000

# Comando para rodar
CMD ["pm2-runtime", "start", "ecosystem.config.cjs", "--env", "production"]
