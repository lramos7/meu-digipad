# Estágio de Build e Execução
FROM node:20-bookworm

# 1. Instalar dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphicsmagick \
    ghostscript \
    libreoffice \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Instalar PM2 globalmente
RUN npm install -g pm2

WORKDIR /usr/src/app

# 3. Baixar o código e instalar dependências do Node
# O Easypanel já baixa o código, mas garantimos a instalação aqui
COPY . .
RUN npm install

# 4. Rodar o build do projeto (conforme instruções do Digipad)
RUN npm run build

# 5. Variáveis de ambiente padrão para o container
ENV NODE_ENV=production
ENV PORT=3000

# Porta que o app escuta
EXPOSE 3000

# 6. Comando de inicialização usando o arquivo cjs que você mencionou
CMD ["pm2-runtime", "start", "ecosystem.config.cjs", "--env", "production"]
