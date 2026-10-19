Extension { #name : 'RSSVGPathLine' }

{ #category : '*Roassal-web' }
RSSVGPathLine >> svgAttributes [

	^ { #d -> (svgPath value: self) }
]

{ #category : '*Roassal-web' }
RSSVGPathLine >> svgTag [

	^ 'path'
]
