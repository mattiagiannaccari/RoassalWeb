Extension { #name : 'RSBitmap' }

{ #category : '*Roassal-web' }
RSBitmap >> svgAttributes [

	| pngStream |
	pngStream := WriteStream on: ByteArray new.
	PNGReadWriter putForm: self form onStream: pngStream.
	^ {
		#href -> ('data:image/png;base64,', pngStream contents base64Encoded).
		#x -> self baseRectangle left.
		#y -> self baseRectangle top.
		#width -> self baseRectangle width.
		#height -> self baseRectangle height.
		self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSBitmap >> svgTag [

	^ 'image'
]
