Extension { #name : 'RSSVGPath' }

{ #category : '*Roassal-web' }
RSSVGPath >> buildSvgPathData [
	
	| isRelative |
	isRelative := false.
	
	^ String streamContents: [ :stream |
		segments do: [ :segment | | selector arguments |
			selector := segment first.
			arguments := segment second.
			selector = #absolute ifTrue: [ isRelative := false ].
			selector = #relative ifTrue: [ isRelative := true ].
			selector = #ellipticalArc:xrot:large:sweep:to:relative:
				ifTrue: [ arguments := arguments allButLast ].
			
			self commandLetters at: selector ifPresent: [ :letter |
				stream << (isRelative
					ifTrue: [ letter asLowercase ]
					ifFalse: [ letter ]).
				
				arguments do: [ :argument |
					stream space.
					argument isPoint
						ifTrue: [ stream << argument x asString; space; << argument y asString ]
						ifFalse: [ stream << argument asString ] ].
				
				stream space ] ] ]
]

{ #category : '*Roassal-web' }
RSSVGPath >> commandLetters [

	^ {
		#moveTo: -> 'M'.
		#lineTo: -> 'L'.
		#hLineTo: -> 'H'.
		#vLineTo: -> 'V'.
		#curveVia:to: -> 'Q'.
		#curveVia:and:to: -> 'C'.
		#reflectedCurveVia:to: -> 'S'.
		#ellipticalArc:xrot:large:sweep:to:relative: -> 'A'.
		#close -> 'Z' } asDictionary
]

{ #category : '*Roassal-web' }
RSSVGPath >> svgAttributes [

	^ {
		#d -> self svgPathData.
		self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSSVGPath >> svgPathData [
	
	segments ifNil: [ ^ '' ].
	^ self buildSvgPathData
]

{ #category : '*Roassal-web' }
RSSVGPath >> svgTag [

	^ 'path'
]
