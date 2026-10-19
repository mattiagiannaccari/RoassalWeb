Extension { #name : 'RSAbstractLine' }

{ #category : '*Roassal-web' }
RSAbstractLine >> toSVG [

	| markerElements |
	markerElements := OrderedCollection new.
	self markerShapesInPositionDo: [ :markerShape |
		markerElements add: markerShape toSVG ].
	^ super toSVG, (markerElements joinUsing: '')
]
