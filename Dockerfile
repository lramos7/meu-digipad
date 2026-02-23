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

# 4. Define variáveis para o processo de BUILD
# O Vite precisa disso no momento da compilação para gerar os links corretos
ARG DOMAIN=https://digipad.aicortix.top
ENV DOMAIN=$DOMAIN
ENV NODE_ENV=production
ENV VITE_STORAGE=fs

# Limpa builds anteriores e gera o novo
RUN rm -rf dist && npm run build

EXPOSE 3000

# Garante permissões nas pastas que o app vai escrever
RUN mkdir -p public/uploads public/temp && chmod -R 777 public/uploads public/temp

# 5. Comando de inicialização
CMD ["pm2-runtime", "start", "ecosystem.config.cjs", "--env", "production"]
