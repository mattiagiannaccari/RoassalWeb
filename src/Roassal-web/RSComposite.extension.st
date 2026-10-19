Extension { #name : 'RSComposite' }

{ #category : '*Roassal-web' }
RSComposite >> bubbleUpClick [

	self children do: [ :eachChild |
		eachChild
			when: RSMouseClick
			do: [ :event |
				event shape: self.
				self announce: event ]
			for: eachChild ]
]

{ #category : '*Roassal-web' }
RSComposite >> bubbleUpLeftClick [

	self children do: [ :eachChild |
		eachChild
			when: RSMouseLeftClick
			do: [ :event |
				event shape: self.
				self announce: event ]
			for: eachChild ]
]

{ #category : '*Roassal-web' }
RSComposite >> svgAttributes [

	^ { self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSComposite >> svgContent [

	| background |
	background := RSBox new
		extent: self baseRectangle extent;
		paint: self paint;
		border: self border;
		yourself.
	
	^ ({ background }, self children collect: [ :shape |
		shape toSVG ]) joinUsing: String cr
]

{ #category : '*Roassal-web' }
RSComposite >> svgTag [

	^ 'g'
]
