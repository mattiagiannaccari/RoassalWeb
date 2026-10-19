Extension { #name : 'RSCircularShape' }

{ #category : '*Roassal-web' }
RSCircularShape >> svgAttributes [

	^ {
		#rx -> (self baseRectangle width / 2).
		#ry -> (self baseRectangle height / 2).
		self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSCircularShape >> svgTag [

	^ 'ellipse'
]
