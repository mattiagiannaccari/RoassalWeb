Extension { #name : 'RSPolygon' }

{ #category : '*Roassal-web' }
RSPolygon >> svgAttributes [

	^ {
		#points -> ((self points collect: [ :point |
			'{1},{2}' format: { point x. point y } ]) joinUsing: ' ').
		self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSPolygon >> svgTag [

	^ 'polygon'
]
