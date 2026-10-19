Extension { #name : 'RSBoundingShape' }

{ #category : '*Roassal-web' }
RSBoundingShape >> svgTransformAttribute [

	^ #transform -> ('matrix({1},{2},{3},{4},{5},{6})' format: {
		matrix sx.
		matrix shy.
		matrix shx.
		matrix sy.
		matrix x.
		matrix y })
]
