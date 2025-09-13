export { onBeforeRender }

function onBeforeRender (pageContext) {
	const urlOriginal = pageContext.urlOriginal
	const hote = pageContext.hote
	const langue = pageContext.langue
	const titre = 'Admin - Digipad by La Digitale'
	const pageProps = { urlOriginal, hote, langue, titre }
	return {
		pageContext: {
			pageProps
		}
	}
}
