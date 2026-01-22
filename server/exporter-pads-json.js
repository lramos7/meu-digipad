import 'dotenv/config'
import path from 'path'
import fs from 'fs-extra'
import { createClient } from 'redis'
import { fileURLToPath } from 'url'
import dayjs from 'dayjs'

let db
let db_port = 6379
if (process.env.DB_PORT) {
	db_port = process.env.DB_PORT
}
if (process.env.NODE_ENV === 'production') {
	db = await createClient({
		url: 'redis://default:' + process.env.DB_PWD  + '@' + process.env.DB_HOST + ':' + db_port
	}).on('error', function (err) {
		console.log('redis: ', err)
	}).connect()
} else {
	db = await createClient({
		url: 'redis://localhost:' + db_port
	}).on('error', function (err) {
		console.log('redis: ' + err)
	}).connect()
}

const __dirname = path.dirname(fileURLToPath(import.meta.url))

exporterPadsJson()

async function exporterPadsJson () {
	const jours = 100
	let pad = await db.GET('pad')
	pad = parseInt(pad)
	for (let i = 0; i < pad + 1; i++) {
		const id = i
		const chemin = path.join(__dirname, '..', '/static/pads')
		const resultat = await db.EXISTS('pads:' + id)
		if (resultat === 1) {
			let d = await db.HGETALL('pads:' + id)
			d = Object.assign({}, d)
			if ((d.hasOwnProperty('modifie') && dayjs(new Date(d.modifie)).isBefore(dayjs().subtract(jours, 'days'))) || (d.hasOwnProperty('date') && dayjs(new Date(d.date)).isBefore(dayjs().subtract(jours, 'days')))) {
				const donneesPad = new Promise(async function (resolveMain) {
					let resultats = await db.HGETALL('pads:' + id)
					resultats = Object.assign({}, resultats)
					if (resultats === null) { resolveMain({}); return false }
					resolveMain(resultats)
				})
				const blocsPad = new Promise(async function (resolveMain) {
					const donneesBlocs = []
					const blocs = await db.ZRANGE('blocs:' + id, 0, -1)
					if (blocs === null) { resolveMain(donneesBlocs); return false }
					for (const bloc of blocs) {
						const donneesBloc = new Promise(async function (resolve) {
							let donnees = await db.HGETALL('pad-' + id + ':' + bloc)
							donnees = Object.assign({}, donnees)
							if (donnees === null) { resolve({}); return false }
							if (donnees && Object.keys(donnees).length > 0) {
								const donneesCommentaires = []
								const commentaires = await db.ZRANGE('commentaires:' + bloc, 0, -1)
								if (commentaires === null) { resolve(donnees); return false }
								for (let commentaire of commentaires) {
									donneesCommentaires.push(JSON.parse(commentaire))
								}
								donnees.commentaires = donneesCommentaires.length
								donnees.listeCommentaires = donneesCommentaires
								const evaluations = await db.ZRANGE('evaluations:' + bloc, 0, -1)
								if (evaluations === null) { resolve(donnees); return false }
								const donneesEvaluations = []
								evaluations.forEach(function (evaluation) {
									donneesEvaluations.push(JSON.parse(evaluation))
								})
								donnees.evaluations = donneesEvaluations.length
								donnees.listeEvaluations = donneesEvaluations
								resolve(donnees)
							} else {
								resolve({})
							}
						})
						donneesBlocs.push(donneesBloc)
					}
					Promise.all(donneesBlocs).then(function (resultat) {
						resolveMain(resultat)
					})
				})
				const activitePad = new Promise(async function (resolveMain) {
					const donneesEntrees = []
					const entrees = await db.ZRANGE('activite:' + id, 0, -1)
					if (entrees === null) { resolveMain(donneesEntrees); return false }
					for (let entree of entrees) {
						entree = JSON.parse(entree)
						const donneesEntree = new Promise(async function (resolve) {
							const resultat = await db.EXISTS('utilisateurs:' + entree.identifiant)
							if (resultat === null) { resolve({}) }
							if (resultat === 1) {
								resolve(entree)
							} else {
								resolve({})
							}
						})
						donneesEntrees.push(donneesEntree)
					}
					Promise.all(donneesEntrees).then(function (resultat) {
						resolveMain(resultat)
					})
				})
				Promise.all([donneesPad, blocsPad, activitePad]).then(async function (donnees) {
					if (donnees.length > 0 && donnees[0].id) {
						const parametres = {}
						parametres.pad = donnees[0]
						parametres.blocs = donnees[1]
						parametres.activite = donnees[2]
						await fs.writeFile(path.normalize(chemin + '/' + id + '.json'), JSON.stringify(parametres, '', 4), 'utf8')
						await fs.writeFile(path.normalize(chemin + '/pad-' + id + '.json'), JSON.stringify(parametres.pad, '', 4), 'utf8')
						// Suppression données redis
						const blocs = await db.ZRANGE('blocs:' + id, 0, -1)
						if (blocs !== null) {
							for (let i = 0; i < blocs.length; i++) {
								await db
								.multi()
								.DEL('commentaires:' + blocs[i])
								.DEL('evaluations:' + blocs[i])
								.DEL('pad-' + id + ':' + blocs[i])
								.exec()
							}
							await db
							.multi()
							.DEL('blocs:' + id)
							.DEL('pads:' + id)
							.DEL('activite:' + id)
							.exec()
							console.log(id)
						}
					}
				})
			}
		}
	}
}
