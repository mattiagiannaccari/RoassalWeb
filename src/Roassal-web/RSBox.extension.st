Extension { #name : 'RSBox' }

{ #category : '*Roassal-web' }
RSBox >> svgAttributes [

	^ {
		#x -> self baseRectangle left.
		#y -> self baseRectangle top.
		#width -> self baseRectangle width.
		#height -> self baseRectangle height.
		#rx -> self svgCornerRadius.
		#ry -> self svgCornerRadius.
		self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSBox >> svgCornerRadius [

	| maximumRadius |
	self hasCornerRadius ifFalse: [ ^ 0 ].
	maximumRadius := self baseRectangle width / 2 min: self baseRectangle height / 2.
	^ (cornerRadius topLeft min: maximumRadius) max: 0
]

{ #category : '*Roassal-web' }
RSBox >> svgTag [

	^ 'rect'
]
