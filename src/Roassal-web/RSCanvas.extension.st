Extension { #name : 'RSCanvas' }

{ #category : '*Roassal-web' }
RSCanvas >> announceEvent: aMouseEventClass toShapeRequestedBy: aRequest [

	| shape handlerDone |
	shape := self shapeWithSVGId: (aRequest uri queryAt: 'id' ifAbsent: [ nil ]).
	shape ifNil: [ ^ ZnResponse notFound: aRequest uri ].
	handlerDone := Semaphore new.
	UIManager default defer: [
		[ shape announce: (aMouseEventClass new
			canvas: self;
			shape: shape;
			yourself) ]
				ensure: [ handlerDone signal ] ].
	handlerDone wait.
	^ ZnResponse noContent
]

{ #category : '*Roassal-web' }
RSCanvas >> handleClick: aRequest [

	^ self announceEvent: RSMouseLeftClick toShapeRequestedBy: aRequest
]

{ #category : '*Roassal-web' }
RSCanvas >> handleContextMenuItem: aRequest [

	| shape itemPath handlerDone |
	shape := self shapeWithSVGId: (aRequest uri queryAt: 'id' ifAbsent: [ nil ]).
	shape ifNil: [ ^ ZnResponse notFound: aRequest uri ].
	itemPath := ((aRequest uri queryAt: 'path' ifAbsent: [ '' ]) substrings: '.')
		collect: [ :index | index asInteger ifNil: [ 0 ] ].
	handlerDone := Semaphore new.
	UIManager default defer: [
		[ (shape contextMenuItemAt: itemPath) ifNotNil: [ :item | item doButtonAction ] ]
			ensure: [ handlerDone signal ] ].
	handlerDone wait.
	^ ZnResponse noContent
]

{ #category : '*Roassal-web' }
RSCanvas >> handleDrag: aRequest [

	| shape step handlerDone |
	shape := self shapeWithSVGId: (aRequest uri queryAt: 'id' ifAbsent: [ nil ]).
	shape ifNil: [ ^ ZnResponse notFound: aRequest uri ].
	step := ((aRequest uri queryAt: 'dx' ifAbsent: [ '0' ]) asNumber
		@ (aRequest uri queryAt: 'dy' ifAbsent: [ '0' ]) asNumber) * self camera scale.
	handlerDone := Semaphore new.
	UIManager default defer: [
		[ shape announce: (RSMouseDragStart new canvas: self; shape: shape; yourself).
		shape announce: (RSMouseDragging new canvas: self; shape: shape; step: step; yourself).
		shape announce: (RSMouseDragEnd new canvas: self; shape: shape; yourself) ]
			ensure: [ handlerDone signal ] ].
	handlerDone wait.
	^ ZnResponse noContent
]

{ #category : '*Roassal-web' }
RSCanvas >> handleRightClick: aRequest [

	^ self announceEvent: RSMouseRightClick toShapeRequestedBy: aRequest
]

{ #category : '*Roassal-web' }
RSCanvas >> serve [

	self serveOn: 8080
]

{ #category : '*Roassal-web' }
RSCanvas >> serveOn: aNumber [

	ZnManagingMultiThreadedServer allInstances
		select: [ :each | each port = aNumber ]
		thenDo: [ :each | each stop ].

	ZnManagingMultiThreadedServer new
		port: aNumber;
		delegate: (ZnDefaultServerDelegate empty
			map: 'index' to: [ :request |
				ZnResponse ok: (ZnEntity xml: self toSVG ) ];
			map: '/' to: 'index';
			map: 'click' to: [ :request | self handleClick: request ];
			map: 'rightClick' to: [ :request | self handleRightClick: request ];
			map: 'menuItem' to: [ :request | self handleContextMenuItem: request ];
			map: 'drag' to: [ :request | self handleDrag: request ]
		);
		start
]

{ #category : '*Roassal-web' }
RSCanvas >> shapeWithSVGId: anId [

	^ self allChildren
		detect: [ :shape | (shape propertyAt: #svgId ifAbsent: [ nil ]) = anId ]
		ifNone: [ nil ]
]

{ #category : '*Roassal-web' }
RSCanvas >> svgContextMenuScript [

	^ '<style>.context-menu-item:hover > rect { fill: #DDDDDD; }
.context-menu-item:hover > .context-menu-submenu { visibility: visible; }</style>
<script><![CDATA[
function showContextMenu(event, id) {
	hideContextMenus();
	const menu = document.getElementById(id);
	const screenToSVG = menu.ownerSVGElement.getScreenCTM().inverse();
	const corner = new DOMPoint(event.clientX, event.clientY).matrixTransform(screenToSVG);
	menu.setAttribute("transform", "translate(" + corner.x + " " + corner.y + ") scale(" + screenToSVG.a + ")");
	menu.setAttribute("visibility", "visible");
}
function hideContextMenus() {
	document.querySelectorAll(".context-menu").forEach(menu => menu.setAttribute("visibility", "hidden"));
}
function chooseContextMenuItem(shapeId, itemPath) {
	hideContextMenus();
	fetch("/menuItem?id=" + shapeId + "&path=" + itemPath).then(() => location.reload());
}
document.addEventListener("pointerdown", event => {
	if (!event.target.closest(".context-menu")) hideContextMenus();
}, true);
document.addEventListener("keydown", event => {
	if (event.key === "Escape") hideContextMenus();
});
]]></script>'
]

{ #category : '*Roassal-web' }
RSCanvas >> svgContextMenus [

	| shapesWithMenu |
	shapesWithMenu := self allChildren select: [ :shape | shape menuInteraction isNotNil ].
	shapesWithMenu ifEmpty: [ ^ '' ].
	^ self svgContextMenuScript, ((shapesWithMenu collect: [ :shape | shape svgContextMenu ]) joinUsing: String cr)
]

{ #category : '*Roassal-web' }
RSCanvas >> svgDragScript [

	(self allChildren anySatisfy: [ :shape | shape hasDragHandler ]) ifFalse: [ ^ '' ].
	^ '<script><![CDATA[
let shapeDrag = null;
let isClickAfterDrag = false;
document.addEventListener("pointerdown", event => {
	if (event.button !== 0) return;
	const element = event.target.closest("[data-drag-id]");
	if (!element) return;
	event.stopPropagation();
	shapeDrag = {
		element: element,
		id: element.getAttribute("data-drag-id"),
		transform: element.getAttribute("transform") || "",
		screenToSVG: element.ownerSVGElement.getScreenCTM().inverse(),
		startX: event.clientX,
		startY: event.clientY,
		deltaX: 0,
		deltaY: 0,
		hasMoved: false
	};
}, true);
window.addEventListener("pointermove", event => {
	if (!shapeDrag) return;
	const pixelsX = event.clientX - shapeDrag.startX;
	const pixelsY = event.clientY - shapeDrag.startY;
	if (Math.abs(pixelsX) + Math.abs(pixelsY) > 3) shapeDrag.hasMoved = true;
	shapeDrag.deltaX = pixelsX * shapeDrag.screenToSVG.a;
	shapeDrag.deltaY = pixelsY * shapeDrag.screenToSVG.a;
	shapeDrag.element.setAttribute("transform", "translate(" + shapeDrag.deltaX + " " + shapeDrag.deltaY + ") " + shapeDrag.transform);
});
window.addEventListener("pointerup", () => {
	if (!shapeDrag) return;
	const drag = shapeDrag;
	shapeDrag = null;
	if (!drag.hasMoved) {
		drag.element.setAttribute("transform", drag.transform);
		return;
	}
	isClickAfterDrag = true;
	setTimeout(() => { isClickAfterDrag = false; }, 0);
	fetch("/drag?id=" + drag.id + "&dx=" + drag.deltaX + "&dy=" + drag.deltaY).then(() => location.reload());
});
window.addEventListener("click", event => {
	if (isClickAfterDrag) event.stopPropagation();
}, true);
]]></script>'
]

{ #category : '*Roassal-web' }
RSCanvas >> svgInteractionScript [

	^ '<script><![CDATA[
function sendShapeEvent(path, event) {
	const element = event.target.closest("[data-shape-id]");
	if (!element) return false;
	fetch(path + "?id=" + encodeURIComponent(element.getAttribute("data-shape-id")));
	return true;
}
document.addEventListener("click", event => sendShapeEvent("/click", event));
document.addEventListener("contextmenu", event => {
	if (sendShapeEvent("/rightClick", event)) event.preventDefault();
});
]]></script>'
]

{ #category : '*Roassal-web' }
RSCanvas >> svgTooltipScript [

	^ '<script><![CDATA[
function placeTooltip(event, id) {
	const tooltip = document.getElementById(id);
	const screenToSVG = tooltip.ownerSVGElement.getScreenCTM().inverse();
	const corner = new DOMPoint(event.clientX + 5, event.clientY + 5).matrixTransform(screenToSVG);
	tooltip.setAttribute("transform", "translate(" + corner.x + " " + corner.y + ") scale(" + screenToSVG.a + ")");
	tooltip.setAttribute("visibility", "visible");
}
function hideTooltip(id) {
	document.getElementById(id).setAttribute("visibility", "hidden");
}
]]></script>'
]

{ #category : '*Roassal-web' }
RSCanvas >> svgTooltips [

	| shapesWithTooltip |
	shapesWithTooltip := self allChildren select: [ :shape | shape popupInteraction isNotNil ].
	shapesWithTooltip ifEmpty: [ ^ '' ].
	^ self svgTooltipScript, ((shapesWithTooltip collect: [ :shape | shape svgTooltip ]) joinUsing: String cr)
]

{ #category : '*Roassal-web' }
RSCanvas >> svgViewScript [

	^ '<script><![CDATA[
const svg = document.documentElement;
const drawing = svg.viewBox.baseVal;
const bounds = { x: drawing.x, y: drawing.y, width: drawing.width, height: drawing.height };
const view = { x: 0, y: 0, scale: 1 };
let viewSaveTimer = null;
let drag = null;

function fitView() {
	view.x = bounds.x + bounds.width / 2;
	view.y = bounds.y + bounds.height / 2;
	view.scale = Math.min(innerWidth / bounds.width, innerHeight / bounds.height) * 0.9;
}
function renderView() {
	const width = innerWidth / view.scale;
	const height = innerHeight / view.scale;
	svg.setAttribute("viewBox", [view.x - width / 2, view.y - height / 2, width, height].join(" "));
	clearTimeout(viewSaveTimer);
	viewSaveTimer = setTimeout(saveViewToURL, 200);
}
function saveViewToURL() {
	history.replaceState(null, "", "#" + [view.x, view.y, view.scale].join(","));
}
function readViewFromURL() {
	const values = location.hash.slice(1).split(",").map(Number);
	if (values.length !== 3 || values.some(isNaN)) return false;
	[view.x, view.y, view.scale] = values;
	return true;
}
function zoomView(factor) {
	view.scale = view.scale * factor;
	renderView();
}
function moveViewByPixels(deltaX, deltaY) {
	view.x = view.x + deltaX / view.scale;
	view.y = view.y + deltaY / view.scale;
	renderView();
}

const arrowDirections = { arrowleft: [-1, 0], arrowright: [1, 0], arrowup: [0, -1], arrowdown: [0, 1] };
document.addEventListener("keydown", event => {
	if (event.ctrlKey || event.metaKey) {
		if (["+", "-", "=", "0"].includes(event.key)) event.preventDefault();
		return;
	}
	const key = event.key.toLowerCase();
	const step = event.shiftKey ? 200 : 50;
	if (key === "i") zoomView(1.5);
	else if (key === "o") zoomView(0.5);
	else if (key === " ") { fitView(); renderView(); }
	else if (key in arrowDirections) moveViewByPixels(arrowDirections[key][0] * step, arrowDirections[key][1] * step);
	else return;
	event.preventDefault();
});
window.addEventListener("wheel", event => {
	event.preventDefault();
	if (event.ctrlKey) return;
	moveViewByPixels(event.deltaX, event.deltaY);
}, { passive: false });
document.addEventListener("gesturestart", event => event.preventDefault());
window.addEventListener("resize", renderView);

document.addEventListener("pointerdown", event => {
	if (event.button !== 0 || event.target.closest("[onclick]")) return;
	drag = { x: event.clientX, y: event.clientY };
});
window.addEventListener("pointermove", event => {
	if (!drag) return;
	moveViewByPixels(drag.x - event.clientX, drag.y - event.clientY);
	drag = { x: event.clientX, y: event.clientY };
});
window.addEventListener("pointerup", () => { drag = null; });

if (!readViewFromURL()) fitView();
renderView();
]]></script>'
]

{ #category : '*Roassal-web' }
RSCanvas >> toSVG [

	| bounds |
	bounds := self encompassingRectangle.
	^ '<svg xmlns="http://www.w3.org/2000/svg" viewBox="{1} {2} {3} {4}" style="background-color:#{5}">{6}{7}{8}{9}{10}</svg>' format: {
		bounds left.
		bounds top.
		bounds width.
		bounds height.
		self color asHexString.
		(self shapes collect: [ :shape | shape toSVG ]) joinUsing: String cr.
		self svgTooltips.
		self svgContextMenus.
		self svgDragScript.
		self svgViewScript }
]
