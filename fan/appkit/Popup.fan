using dom::Elem
using dom::Event
using dom::Win
using dom::Key
using graphics::Point

**
** Popup window which can be closed clicking outside of element.
** Enclose it in an 'appkit-dropdown' div. 
**
**   html:
**   <div class="appkit-dropdown">
**       <button class="appkit-button" type="button"> Click Me </button>
**       <div class="appkit-popup">
**           Hello!
**       </div>
**   </div>
**   
** 
**   slim:
**   div.appkit-dropdown
**       button.appkit-button (type="button") Click Me
**       div.appkit-popup Hello!
** 
** Use 'div.appkit-popup.appkit-fixed' if popups are in sticky headers, so it also sticks to the top
** 
@Js class Popup {

	Elem elem { private set }

	internal new _make(Elem elem) {
		this.elem = elem

		// don't know why a Popup *wouldn't* be a div?
		// actually, sometimes it NEEDs to be span (as div's can NOT be inside <a>)
		if (elem.tagName != "div" && elem.tagName != "span")
			throw ArgErr("Popup elem not div: ${elem.html}")

		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		AppElem.fromSelector(selector, Popup#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, Popup#, checked)
	}
	
	private Void init() {
		elem.style.addClass("appkit-popup")
		this.onEvent("keydown", false) |e| { if (e.key == Key.esc) close }
		elem->tabIndex = 0
	}

	** Where to align Popup relative to open(x,y):
	**	- Align.left: align left edge popup to (x,y)
	**	- Align.center: center popup with (x,y)
	**	- Align.right: align right edge of popup to (x,y)
	Align halign := Align.left

	** Return 'true' if this popup currently open.
	Bool isOpen { private set }

	** Open this popup in the current Window. If popup is already
	** open this method does nothing. This method always invokes
	** `fitBounds` to verify popup does not overflow viewport.
	Void open(Float x, Float y) {
		if (isOpen) return

		this.openPos = Point(x, y)

		elem.style.setAll([
			"left"				: "${x}px",
			"top"				: "${y}px",
			"-webkit-transform"	: "scale(1)",
			"transform"			: "scale(1)",
			"opacity"			: "0.0"
		])

		body := Win.cur.doc.body
		body.add(mask = Elem {
			it.style.addClass("appkit-popup-mask")
			
			/*div.domkit-Popup-mask {
				position: absolute;
				top		: 0;
				left	: 0;
				width	: 100%;
				height	: 100%;
				z-index	: 1000;
			}*/
			
			it.style->position	= "absolute"
			it.style->top		= "0"
			it.style->left		= "0"
			it.style->width		= "100%"
			it.style->height	= "100%"
			it.style->zIndex	= "1000"	// you may want to override this...
			
			// todo - Sigh - need a better positioning lib - maybe use Popper? 
			// in Andy's app world - everything is fixed relative to the mask
			// but this is NOT the case when it comes to real world web pages - sigh
			// to see the effect, scroll down, then popup a drop down, and scroll some more
//			if (this.elem.style.hasClass("appkit-fixed")) {
				it.style.addClass("position-fixed")
				it.style->position	= "fixed"
//			}

			it.onEvent("mousedown", false) |e| {
				if (e.target == elem || elem.containsChild(e.target)) return
				close
			}
			
			// save where we were - Slimer
			oldParent = elem.parent
			elem.parent.remove(elem)
			
			it.add(elem)
		})

		fitBounds
		onBeforeOpen

		elem.transition([
			"opacity": "1"
		], null, 100ms) { elem.focus; fireOpen(null) }
	}

	** Close this popup. If popup is already closed
	** this method does nothing.
	Void close() {
		elem.transition(["transform": "scale(0.75)", "opacity": "0"], null, 100ms) {
			
			// move elem back to whence it came - Slimer
			// todo save the index also
			elem.parent.remove(elem)
			oldParent?.add(elem)
			
			mask?.parent?.remove(mask)
			fireClose(null)
			
			// remove all manual styling so menu may be re-used in mobile
			elem.style.clear
		}
	}

	**
	** Fit popup with current window bounds. This may move the origin of
	** where popup is opened, or modify the width or height, or both.
	**
	** This method is called automatically by `open`.	For content that
	** is asynchronusly loaded after popup is visible, and that may modify
	** the initial size, it is good practice to invoke this method to
	** verify content does not overflow the viewport.
	**
	** If popup is not open, this method does nothing.
	**
	Void fitBounds() {
		// isOpen may not be set yet, so check if mounted.
		if (elem.parent == null) return

		x	:= openPos.x
		y	:= openPos.y
		sz := elem.size

		// shift halign if needed
		switch (halign) {
			case Align.center : x = gutter.max(x - (sz.w.toInt / 2));	elem.style->left = "${x}px"
			case Align.right  : x = gutter.max(x -  sz.w.toInt);		elem.style->left = "${x}px"
		}

		// adjust if outside viewport
		vp := Win.cur.viewport
		if (sz.w + gutter + gutter > vp.w) elem.style->width  = "${vp.w - gutter - gutter}px"
		if (sz.h + gutter + gutter > vp.h) elem.style->height = "${vp.h - gutter - gutter}px"

		// refresh size
		sz = elem.size
		if ((x + sz.w + gutter) > vp.w) elem.style->left	= "${vp.w - sz.w - gutter}px"
		if ((y + sz.h + gutter) > vp.h) elem.style->top		= "${vp.h - sz.h - gutter}px"
	}

	** Protected sub-class callback invoked directly before popup is visible.
	protected virtual Void onBeforeOpen() {}

	** Callback when popup is opened.
	Void onOpen(|This|? f) { cbOpen = AppKitErrHandler.instance.wrapFn(f) }

	** Callback when popup is closed.
	Void onClose(|This|? f) { cbClose = AppKitErrHandler.instance.wrapFn(f) }

	** Wraps up event handling to use err handling
	private Func onEvent(Str type, Bool useCapture, |Event e| handler) {
		AppElem.onEvent(elem, type, useCapture, handler)
	}
	
	** Internal callback when popup is closed.
	internal Void _onClose(|This| f) { _cbClose = f }

	private Void fireOpen(Event? e)	{ cbOpen?.call(this); isOpen=true }
	private Void fireClose(Event? e) {
		_cbClose?.call(this)
		cbClose?.call(this)
		isOpen = false
	}

	private static const Float gutter := 12f
	private Elem?	mask
	private Point?	openPos
	private Func?	cbOpen
	private Func?	cbClose
	private Func?	_cbClose
	private	Elem?	oldParent
}