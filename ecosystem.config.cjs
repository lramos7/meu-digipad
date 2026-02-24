module.exports = {
  apps: [{
    name: 'Digipad',
    script: './dist/server/entry.mjs',
    node_args: [
      '--expose-gc'
    ],
    autorestart: true,
    max_restarts: 10,
    env: {
      NODE_ENV: 'production'
    }
  }]
}
