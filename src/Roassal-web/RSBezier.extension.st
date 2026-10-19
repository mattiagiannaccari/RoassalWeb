Extension { #name : 'RSBezier' }

{ #category : '*Roassal-web' }
RSBezier >> svgAttributes [

	| points curvePoints command |
	points := self controlPoints.
	curvePoints := points allButFirst first: (points size - 1 min: 3).
	command := #('L' 'Q' 'C') at: curvePoints size.
	^ {
		#d -> ('M {1} {2} {3} {4}' format: {
			points first x.
			points first y.
			command.
			(curvePoints collect: [ :point |
				'{1} {2}' format: { point x. point y } ]) joinUsing: ' ' }) }
]

{ #category : '*Roassal-web' }
RSBezier >> svgTag [

	^ 'path'
]
