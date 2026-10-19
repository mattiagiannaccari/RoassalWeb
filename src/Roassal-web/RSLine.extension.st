Extension { #name : 'RSLine' }

{ #category : '*Roassal-web' }
RSLine >> svgAttributes [

	^ {
		#x1 -> self startPoint x.
		#y1 -> self startPoint y.
		#x2 -> self endPoint x.
		#y2 -> self endPoint y }
]

{ #category : '*Roassal-web' }
RSLine >> svgTag [

	^ 'line'
]
