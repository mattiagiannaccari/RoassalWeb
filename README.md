# RoassalWeb

I export [Roassal](https://github.com/pharo-graphics/Roassal) canvases to SVG and serve them from Pharo, so you can explore a visualization in a browser. The browser view is vector based, so it scales without limits, and the Roassal interactions you attached to your shapes keep working. The browser sends each event back to Pharo, Pharo runs **your** handlers, and the page reloads with the updated canvas.

### Installation

RoassalWeb needs Pharo 12 with Roassal. Clone this repository with Iceberg and load the `Roassal-web` package.

### Usage

```smalltalk
| canvas box |
canvas := RSCanvas new.

box := RSBox new
	width: 40;
	height: 40;
	color: Color red;
	model: 'red box';
	yourself.

box
	when: RSMouseLeftClick
	do: [ :event |
		event shape color: Color random ]
	for: box.
	
box
	@ RSPopup;
	@ RSDraggable;
	@ (RSMenuActivable new menuDo: [ :menu :shape |
		menu
			add: 'Inspect'
			target: shape
			selector: #inspect
			iconName: #smallInspectIt  ]).

canvas add: box.
canvas serve.
```

Then open [http://localhost:8080](http://localhost:8080). To get the SVG as a string without a server, send `toSVG` to the canvas.

### What is supported

**Shapes:** `RSBox` (with a uniform corner radius), `RSEllipse`, `RSCircle`, `RSPolygon`, `RSBitmap`, `RSLabel` (bold, italic, underline, struck out), `RSSVGPath`, `RSPieSlice` (full rings, segment spacing and rounded corners included), `RSComposite` (nested too), `RSLine`, `RSPolyline`, `RSBezier`, `RSSVGPathLine`, and line markers such as the heads of `RSArrowedLine`. Fill, opacity, border width, dashes, line caps and joins are exported.

**Interactions:**

- Click and right click: shapes that handle `RSMouseClick` or one of its subclasses receive `RSMouseLeftClick` and `RSMouseRightClick`, as in Pharo. `RSComposite >> bubbleUpClick` forwards the clicks of the children to the composite.
- Tooltips: `RSPopup` and `RSAnimatedPopup` show their popup next to the mouse, built with the same shape builder Roassal uses.
- Context menus: `RSMenuActivable` opens its menu in the browser, with submenus and icons. Choosing an item runs it in Pharo.
- Drag: shapes that handle `RSMouseDragging`, for example through `RSDraggable`, follow the mouse. On release Pharo receives `RSMouseDragStart`, `RSMouseDragging` and `RSMouseDragEnd`.

**Navigation:**
- `I` zooms in.
- `O` zooms out.
- `Space` fits the whole drawing.
- Arrow keys (faster with `Shift`).
- Dragging the background and panning with a trackpad move the view.

Also: Zoom has no limits. The view lives in the URL fragment, so a reload keeps it, and the browser zoom is disabled.

### How it works

`toSVG` converts every shape into one SVG element and embeds what the browser needs: Bitmaps as base64 PNG, hidden tooltips and menus, and the scripts for navigation, menus and drag. The server answers these routes:

| Route                 | Effect in Pharo                                    |
| --------------------- | -------------------------------------------------- |
| `/`                   | Exports the canvas                                 |
| `/click?id=`          | Announces `RSMouseLeftClick` to the shape          |
| `/rightClick?id=`     | Announces `RSMouseRightClick` to the shape         |
| `/menuItem?id=&path=` | Runs the menu item at that path                    |
| `/drag?id=&dx=&dy=`   | Announces the drag events with that displacement   |

The server runs every handler in the Pharo UI process and answers only when the handler has finished, so the reload always shows the result.

### Known limitations (hopefully further development)

- Gradients and fixed shapes are not exported.
- `RSBox` with different corner radii uses the top left radius for all corners.
- Lines connected to a dragged shape follow it only after the release.
- Tooltips and menus are not moved when they overflow the window.
- Text uses the browser fonts, so it can differ slightly from Pharo.
