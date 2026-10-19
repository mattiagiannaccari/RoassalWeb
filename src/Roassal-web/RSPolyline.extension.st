Extension { #name : 'RSPolyline' }

{ #category : '*Roassal-web' }
RSPolyline >> svgAttributes [

	^ {
		#points -> ((self controlPoints collect: [ :point |
			'{1},{2}' format: { point x. point y } ]) joinUsing: ' ') }
]

{ #category : '*Roassal-web' }
RSPolyline >> svgTag [

	^ 'polyline'
]
