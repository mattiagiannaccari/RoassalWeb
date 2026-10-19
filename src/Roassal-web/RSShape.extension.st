Extension { #name : 'RSShape' }

{ #category : '*Roassal-web' }
RSShape >> borderAttributes [

	self border
		ifNil: [ ^ { 'stroke' -> 'none' } ]
		ifNotNil: [ ^ {
			'stroke' -> ('#', self border paint asHexString).
			'stroke-width' -> self border width.
			'stroke-opacity' -> self border paint alpha },
				self borderStyleAttributes ]
]

{ #category : '*Roassal-web' }
RSShape >> borderStyleAttributes [

	| style |
	style := self border style.
	style ifNil: [ ^ { } ].
	^ {
		'stroke-dasharray' -> (style dashArray
			ifNil: [ 'none' ]
			ifNotNil: [ :dashes | (dashes collect: [ :dash | dash asString ]) joinUsing: ' ' ]).
		'stroke-dashoffset' -> style dashOffset.
		'stroke-linecap' -> (style capStyle
			ifNil: [ 'butt' ]
			ifNotNil: [ :cap | (cap allButFirst: 3) asLowercase ]).
		'stroke-linejoin' -> (style joinStyle
			ifNil: [ 'miter' ]
			ifNotNil: [ :join | (join allButFirst: 4) asLowercase ]) }
]

{ #category : '*Roassal-web' }
RSShape >> contextMenuItemAt: anItemPath [

	| items item |
	items := self contextMenuItems.
	anItemPath do: [ :index |
		(index between: 1 and: items size) ifFalse: [ ^ nil ].
		item := items at: index.
		items := item subMenu
			ifNil: [ #() ]
			ifNotNil: [ :subMenu | subMenu items ] ].
	^ item
]

{ #category : '*Roassal-web' }
RSShape >> contextMenuItems [

	| menu |
	menu := MenuMorph new.
	self menuInteraction menuBlock value: menu value: self.
	^ menu items
]

{ #category : '*Roassal-web' }
RSShape >> escapeAttributeValue: aValue [

	^ aValue asString asHTMLString copyReplaceAll: '"' with: '&quot;'
]

{ #category : '*Roassal-web' }
RSShape >> hasClickHandler [

	^ self hasHandlerFor: RSMouseClick
]

{ #category : '*Roassal-web' }
RSShape >> hasDragHandler [

	^ self hasHandlerFor: RSMouseDragging
]

{ #category : '*Roassal-web' }
RSShape >> hasHandlerFor: anEventClass [

	self hasEventCallback ifFalse: [ ^ false ].
	^ self announcer subscriptions subscriptions anySatisfy: [ :subscription |
		(subscription announcementClass includesBehavior: anEventClass) and: [
			((subscription subscriber isKindOf: RSAbstractPopupInteraction)
				or: [ subscription subscriber isKindOf: RSMenuActivable ]) not ] ]
]

{ #category : '*Roassal-web' }
RSShape >> menuInteraction [

	self hasEventCallback ifFalse: [ ^ nil ].
	^ (self getInteractionsForClass: RSMenuActivable)
		ifEmpty: [ nil ]
		ifNotEmpty: [ :menus | menus first ]
]

{ #category : '*Roassal-web' }
RSShape >> paintAttributes [

	self paint
		ifNil: [ ^ { 'fill' -> 'none' } ]
		ifNotNil: [ ^ {
			'fill' -> ('#', self paint asHexString).
			'fill-opacity' -> self paint alpha } ]
]

{ #category : '*Roassal-web' }
RSShape >> popupInteraction [

	self hasEventCallback ifFalse: [ ^ nil ].
	
	^ (self getInteractionsForClass: RSPopup)
		ifEmpty: [ nil ]
		ifNotEmpty: [ :popups | popups first ]
]

{ #category : '*Roassal-web' }
RSShape >> svgAttributes [

	^ self subclassResponsibility
]

{ #category : '*Roassal-web' }
RSShape >> svgClickAttributes [

	self hasClickHandler ifFalse: [ ^ #() ].
	^ { 'onclick' -> ('event.stopPropagation(); fetch(''/click?id={1}'').then(() => location.reload())' format: { self svgId }) }
]

{ #category : '*Roassal-web' }
RSShape >> svgContent [

	^ ''
]

{ #category : '*Roassal-web' }
RSShape >> svgContextMenu [

	^ '<g id="{1}" class="context-menu" visibility="hidden">{2}</g>' format: {
		self svgContextMenuId.
		self svgContextMenuRowsFor: self contextMenuItems path: '' }
]

{ #category : '*Roassal-web' }
RSShape >> svgContextMenuId [

	^ 'menu-', self svgId
]

{ #category : '*Roassal-web' }
RSShape >> svgContextMenuRowsFor: someMenuItems path: aPathPrefix [

	| labels icons iconColumnWidth rowWidth rowHeight rows frame |
	labels := someMenuItems collect: [ :item |
		RSLabel new
			text: (item subMenu
				ifNil: [ item contents asString ]
				ifNotNil: [ item contents asString, '  ▸' ]);
			color: Color black;
			yourself ].
	icons := someMenuItems collect: [ :item | item icon ].
	iconColumnWidth := icons inject: 0 into: [ :widest :icon |
		icon ifNil: [ widest ] ifNotNil: [ widest max: icon width + 4 ] ].
	rowWidth := (labels inject: 0 into: [ :widest :label | widest max: label width ]) + iconColumnWidth + 16.
	rowHeight := ((labels inject: 0 into: [ :tallest :label | tallest max: label height ])
		max: (icons inject: 0 into: [ :tallest :icon | icon ifNil: [ tallest ] ifNotNil: [ tallest max: icon height ] ])) + 8.
	rows := someMenuItems withIndexCollect: [ :item :index |
		| itemPath rowCenterY label iconSVG background |
		itemPath := aPathPrefix, index printString.
		rowCenterY := (index - 0.5) * rowHeight.
		label := labels at: index.
		iconSVG := (icons at: index)
			ifNil: [ '' ]
			ifNotNil: [ :icon |
				(RSBitmap new
					form: icon;
					translateTo: 8 + (icon width / 2) @ rowCenterY;
					yourself) toSVG ].
		background := RSBox new
			extent: rowWidth @ rowHeight;
			color: Color white;
			translateTo: rowWidth / 2 @ rowCenterY;
			yourself.
		label translateTo: 8 + iconColumnWidth + (label width / 2) @ rowCenterY.
		'<g class="context-menu-item"{1}>{2}{3}{4}{5}</g>' format: {
			item subMenu
				ifNil: [ ' onclick="chooseContextMenuItem(''{1}'', ''{2}'')"' format: { self svgId. itemPath } ]
				ifNotNil: [ '' ].
			background toSVG.
			iconSVG.
			label toSVG.
			self svgContextSubmenuOf: item path: itemPath at: rowWidth @ ((index - 1) * rowHeight) } ].
	frame := RSBox new
		extent: rowWidth @ (rowHeight * labels size);
		noPaint;
		withBorder;
		translateTo: rowWidth / 2 @ (rowHeight * labels size / 2);
		yourself.
	^ (rows joinUsing: String cr), frame toSVG
]

{ #category : '*Roassal-web' }
RSShape >> svgContextSubmenuOf: aMenuItem path: anItemPath at: aPoint [

	aMenuItem subMenu ifNil: [ ^ '' ].
	^ '<g class="context-menu-submenu" visibility="hidden" transform="translate({1} {2})">{3}</g>' format: {
		aPoint x.
		aPoint y.
		self svgContextMenuRowsFor: aMenuItem subMenu items path: anItemPath, '.' }
]

{ #category : '*Roassal-web' }
RSShape >> svgDragAttributes [

	self hasDragHandler ifFalse: [ ^ #() ].
	^ { 'data-drag-id' -> self svgId }
]

{ #category : '*Roassal-web' }
RSShape >> svgElementAttributes [

	^ self svgAttributes, self svgStyleAttributes, self svgClickAttributes, self svgRightClickAttributes, self svgDragAttributes, self svgTooltipAttributes
]

{ #category : '*Roassal-web' }
RSShape >> svgId [

	^ self propertyAt: #svgId ifAbsentPut: [ UUID new asString ]
]

{ #category : '*Roassal-web' }
RSShape >> svgRightClickAttributes [

	self menuInteraction ifNotNil: [
		^ { 'oncontextmenu' -> ('event.stopPropagation(); showContextMenu(event, ''{1}''); return false' format: { self svgContextMenuId }) } ].
	self hasClickHandler ifFalse: [ ^ #() ].
	^ { 'oncontextmenu' -> ('event.stopPropagation(); fetch(''/rightClick?id={1}'').then(() => location.reload()); return false' format: { self svgId }) }
]

{ #category : '*Roassal-web' }
RSShape >> svgStyleAttributes [

	^ self paintAttributes, self borderAttributes
]

{ #category : '*Roassal-web' }
RSShape >> svgTag [

	^ self subclassResponsibility
]

{ #category : '*Roassal-web' }
RSShape >> svgTooltip [

	| popup popupShape |
	
	popup := self popupInteraction.
	popupShape := popup shapeBuilder shapeFor: (popup modelFor: self).
	popupShape translateTo: popupShape extent / 2.
	
	^ '<g id="{1}" visibility="hidden" pointer-events="none">{2}</g>' format: {
		self svgTooltipId.
		popupShape toSVG }
]

{ #category : '*Roassal-web' }
RSShape >> svgTooltipAttributes [

	self popupInteraction ifNil: [ ^ #() ].
	^ {
		'onmouseenter' -> ('placeTooltip(event, ''{1}'')' format: { self svgTooltipId }).
		'onmousemove' -> ('placeTooltip(event, ''{1}'')' format: { self svgTooltipId }).
		'onmouseleave' -> ('hideTooltip(''{1}'')' format: { self svgTooltipId }) }
]

{ #category : '*Roassal-web' }
RSShape >> svgTooltipId [

	^ 'tooltip-', self svgId
]

{ #category : '*Roassal-web' }
RSShape >> toSVG [

	
	^ '<{1} {2}>{3}</{1}>' format: {
		self svgTag.
		(self svgElementAttributes collect: [ :attribute |
			'{1}="{2}"' format: {
				attribute key.
				self escapeAttributeValue: attribute value }
		]) joinUsing: ' '.
		self svgContent }
]
