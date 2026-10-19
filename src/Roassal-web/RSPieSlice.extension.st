Extension { #name : 'RSPieSlice' }

{ #category : '*Roassal-web' }
RSPieSlice >> clampedCornerRadius [

	^ cornerRadii min: (externalRadius - innerRadius) abs / 2
]

{ #category : '*Roassal-web' }
RSPieSlice >> cornerTangentPointsFrom: aStartPoint to: anEndPoint arcRadius: anArcRadius cornerRadius: aCornerRadius [

	| edge offset shiftedStart shiftedEnd middle delta squaredLength reducedRadius cross root perpendicular firstCenter secondCenter center |
	edge := aStartPoint - anEndPoint.
	offset := (edge y @ edge x negated) * (aCornerRadius negated / edge r).
	shiftedStart := aStartPoint + offset.
	shiftedEnd := anEndPoint + offset.
	middle := (shiftedStart + shiftedEnd) / 2.
	delta := shiftedEnd - shiftedStart.
	squaredLength := delta dotProduct: delta.
	reducedRadius := anArcRadius - aCornerRadius.
	cross := shiftedStart crossProduct: shiftedEnd.
	root := ((reducedRadius squared * squaredLength) - cross squared max: 0) sqrt.
	delta y < 0 ifTrue: [ root := root negated ].
	perpendicular := (delta y @ delta x negated) * cross.
	firstCenter := (perpendicular - (delta * root)) / squaredLength.
	secondCenter := (perpendicular + (delta * root)) / squaredLength.
	center := (firstCenter distanceTo: middle) > (secondCenter distanceTo: middle)
		ifTrue: [ secondCenter ]
		ifFalse: [ firstCenter ].
	^ (center - offset) -> (center * (anArcRadius / reducedRadius))
]

{ #category : '*Roassal-web' }
RSPieSlice >> intersectionOfLineFrom: aStart to: anEnd withLineFrom: anotherStart to: anotherEnd [

	| direction otherDirection position |
	direction := anEnd - aStart.
	otherDirection := anotherEnd - anotherStart.
	position := (otherDirection crossProduct: aStart - anotherStart) / (direction crossProduct: otherDirection).
	^ aStart + (direction * position)
]

{ #category : '*Roassal-web' }
RSPieSlice >> largeArcFlagFor: someAngles [

	^ someAngles last - someAngles first > Float pi
		ifTrue: [ 1 ]
		ifFalse: [ 0 ]
]

{ #category : '*Roassal-web' }
RSPieSlice >> largeArcFlagFrom: aPoint to: anotherPoint [

	^ (aPoint crossProduct: anotherPoint) > 0
		ifTrue: [ 1 ]
		ifFalse: [ 0 ]
]

{ #category : '*Roassal-web' }
RSPieSlice >> paddedAnglesAtRadius: aRadius [

	| startAngle endAngle padRadius removedAngle |
	startAngle := alphaAngle degreesToRadians.
	endAngle := betaAngle degreesToRadians.
	aRadius isZero ifTrue: [ ^ { startAngle. endAngle } ].
	padRadius := (innerRadius squared + externalRadius squared) sqrt.
	removedAngle := (padRadius * (segmentSpacing / 2) degreesToRadians sin / aRadius min: 1) arcSin.
	^ endAngle - startAngle > (2 * removedAngle)
		ifTrue: [ { startAngle + removedAngle. endAngle - removedAngle } ]
		ifFalse: [ Array new: 2 withAll: (startAngle + endAngle) / 2 ]
]

{ #category : '*Roassal-web' }
RSPieSlice >> pointAtRadius: aRadius angle: anAngleInRadians [

	^ (aRadius * anAngleInRadians cos) @ (aRadius * anAngleInRadians sin) negated
]

{ #category : '*Roassal-web' }
RSPieSlice >> svgArcTo: aPoint radius: aRadius largeArcFlag: aLargeArcFlag sweepFlag: aSweepFlag [

	^ 'A {1} {1} 0 {2} {3} {4} {5} ' format: {
		aRadius abs.
		aLargeArcFlag.
		aSweepFlag.
		aPoint x.
		aPoint y }
]

{ #category : '*Roassal-web' }
RSPieSlice >> svgAttributes [

	^ {
		#d -> self svgPathData.
		self svgTransformAttribute }
]

{ #category : '*Roassal-web' }
RSPieSlice >> svgFullCirclePathData [

	| startAngle oppositeAngle outerStart outerOpposite innerStart innerOpposite |
	startAngle := alphaAngle degreesToRadians.
	oppositeAngle := startAngle + Float pi.
	outerStart := self pointAtRadius: externalRadius angle: startAngle.
	outerOpposite := self pointAtRadius: externalRadius angle: oppositeAngle.
	innerStart := self pointAtRadius: innerRadius angle: startAngle.
	innerOpposite := self pointAtRadius: innerRadius angle: oppositeAngle.
	^ 'M {1} {2} A {3} {3} 0 1 0 {4} {5} A {3} {3} 0 1 0 {1} {2} Z M {6} {7} A {8} {8} 0 1 1 {9} {10} A {8} {8} 0 1 1 {6} {7} Z' format: {
		outerStart x.
		outerStart y.
		externalRadius.
		outerOpposite x.
		outerOpposite y.
		innerStart x.
		innerStart y.
		innerRadius.
		innerOpposite x.
		innerOpposite y }
]

{ #category : '*Roassal-web' }
RSPieSlice >> svgPathData [

	| outerAngles innerAngles outerStart outerEnd innerEnd innerStart |
	
	betaAngle - alphaAngle >= 360 ifTrue: [ ^ self svgFullCirclePathData ].
	self clampedCornerRadius > 0.001 ifTrue: [ ^ self svgRoundedPathData ].
	
	outerAngles := self paddedAnglesAtRadius: externalRadius.
	innerAngles := self paddedAnglesAtRadius: innerRadius.
	outerStart := self pointAtRadius: externalRadius angle: outerAngles first.
	outerEnd := self pointAtRadius: externalRadius angle: outerAngles last.
	innerEnd := self pointAtRadius: innerRadius angle: innerAngles last.
	innerStart := self pointAtRadius: innerRadius angle: innerAngles first.
	
	^ 'M {1} {2} A {3} {3} 0 {4} 0 {5} {6} L {7} {8} A {9} {9} 0 {10} 1 {11} {12} Z' format: {
		outerStart x.
		outerStart y.
		externalRadius.
		self largeArcFlagFor: outerAngles.
		outerEnd x.
		outerEnd y.
		innerEnd x.
		innerEnd y.
		innerRadius.
		self largeArcFlagFor: innerAngles.
		innerStart x.
		innerStart y }
]

{ #category : '*Roassal-web' }
RSPieSlice >> svgRoundedPathData [

	| cornerRadius outerAngles innerAngles outerStart outerEnd innerEnd innerStart outerCornerRadius innerCornerRadius startOuterCorner endOuterCorner startInnerCorner endInnerCorner |
	cornerRadius := self clampedCornerRadius.
	outerAngles := self paddedAnglesAtRadius: externalRadius.
	innerAngles := self paddedAnglesAtRadius: innerRadius.
	outerAngles last - outerAngles first < 0.001 ifTrue: [ ^ '' ].
	outerStart := self pointAtRadius: externalRadius angle: outerAngles first.
	outerEnd := self pointAtRadius: externalRadius angle: outerAngles last.
	innerEnd := self pointAtRadius: innerRadius angle: innerAngles last.
	innerStart := self pointAtRadius: innerRadius angle: innerAngles first.
	outerCornerRadius := cornerRadius.
	innerCornerRadius := cornerRadius.
	betaAngle - alphaAngle < 180 ifTrue: [
		| edgesIntersection toStart toEnd cosine centerDistanceFactor intersectionDistance |
		edgesIntersection := self
			intersectionOfLineFrom: outerStart
			to: innerStart
			withLineFrom: outerEnd
			to: innerEnd.
		toStart := outerStart - edgesIntersection.
		toEnd := outerEnd - edgesIntersection.
		cosine := (toStart dotProduct: toEnd) / (toStart r * toEnd r).
		centerDistanceFactor := 1 / (((cosine min: 1) max: -1) arcCos / 2) sin.
		intersectionDistance := edgesIntersection r.
		outerCornerRadius := outerCornerRadius min: externalRadius - intersectionDistance / (centerDistanceFactor + 1).
		innerCornerRadius := innerCornerRadius min: innerRadius - intersectionDistance / (centerDistanceFactor - 1) ].
	startOuterCorner := self cornerTangentPointsFrom: innerStart to: outerStart arcRadius: externalRadius cornerRadius: outerCornerRadius.
	endOuterCorner := self cornerTangentPointsFrom: outerEnd to: innerEnd arcRadius: externalRadius cornerRadius: outerCornerRadius.
	^ String streamContents: [ :stream |
		stream << ('M {1} {2} ' format: { startOuterCorner key x. startOuterCorner key y }).
		outerCornerRadius = cornerRadius
			ifTrue: [
				stream
					<< (self svgArcTo: startOuterCorner value radius: outerCornerRadius largeArcFlag: 0 sweepFlag: 0);
					<< (self svgArcTo: endOuterCorner value radius: externalRadius largeArcFlag: (self largeArcFlagFrom: startOuterCorner value to: endOuterCorner value) sweepFlag: 0);
					<< (self svgArcTo: endOuterCorner key radius: outerCornerRadius largeArcFlag: 0 sweepFlag: 0) ]
			ifFalse: [
				stream << (self svgArcTo: endOuterCorner key radius: outerCornerRadius largeArcFlag: 1 sweepFlag: 0) ].
		innerRadius isZero
			ifTrue: [ stream << 'L 0 0 ' ]
			ifFalse: [
				startInnerCorner := self cornerTangentPointsFrom: outerStart to: innerStart arcRadius: innerRadius cornerRadius: innerCornerRadius negated.
				endInnerCorner := self cornerTangentPointsFrom: innerEnd to: outerEnd arcRadius: innerRadius cornerRadius: innerCornerRadius negated.
				stream << ('L {1} {2} ' format: { endInnerCorner key x. endInnerCorner key y }).
				(innerCornerRadius = cornerRadius and: [ innerAngles last > innerAngles first ])
					ifTrue: [
						stream
							<< (self svgArcTo: endInnerCorner value radius: innerCornerRadius largeArcFlag: 0 sweepFlag: 0);
							<< (self svgArcTo: startInnerCorner value radius: innerRadius largeArcFlag: (self largeArcFlagFrom: startInnerCorner value to: endInnerCorner value) sweepFlag: 1);
							<< (self svgArcTo: startInnerCorner key radius: innerCornerRadius largeArcFlag: 0 sweepFlag: 0) ]
					ifFalse: [
						stream << (self svgArcTo: startInnerCorner key radius: innerCornerRadius largeArcFlag: 0 sweepFlag: 0) ] ].
		stream << 'Z' ]
]

{ #category : '*Roassal-web' }
RSPieSlice >> svgTag [

	^ 'path'
]
