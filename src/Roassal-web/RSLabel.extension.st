Extension { #name : 'RSLabel' }

{ #category : '*Roassal-web' }
RSLabel >> svgAttributes [

	^ {
		'font-family' -> (self fontName, ', sans-serif').
		'font-size' -> self font pixelSize.
		'font-weight' -> (self isBold ifTrue: [ 'bold' ] ifFalse: [ 'normal' ]).
		'font-style' -> (self isItalic ifTrue: [ 'italic' ] ifFalse: [ 'normal' ]).
		'text-decoration' -> self svgTextDecoration.
		'text-anchor' -> 'middle'.
		'dominant-baseline' -> 'central'.
		self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSLabel >> svgContent [

	^ self text asHTMLString
]

{ #category : '*Roassal-web' }
RSLabel >> svgTag [

	^ 'text'
]

{ #category : '*Roassal-web' }
RSLabel >> svgTextDecoration [

	| decorations |
	decorations := OrderedCollection new.
	self isUnderlined ifTrue: [ decorations add: 'underline' ].
	self isStruckOut ifTrue: [ decorations add: 'line-through' ].
	^ decorations
		ifEmpty: [ 'none' ]
		ifNotEmpty: [ decorations joinUsing: ' ' ]
]
