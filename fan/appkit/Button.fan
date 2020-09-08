using dom::Elem
using dom::Event
using dom::Key
using dom::Win
using graphics::Point

**
** Button is a widget that invokes an action when pressed.
**
**   html:
**   <button class="appkit-button"/>
** 
**   slim:
**   button.appkit-button
** 
** - domkit 1.0.75
** 
@Js class Button {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "button")
			throw ArgErr("Elem not button: ${elem.html}")
		
		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		elem := Win.cur.doc.querySelector(selector)
		if (elem == null && checked) throw Err("Could not find Button: ${selector}")
		return fromElem(elem)
	}
	
	static new fromElem(Elem? elem) {
		if (elem == null) return null
		if (elem.prop(Button#.qname) == null)
			elem.setProp(Button#.qname, Button._make(elem))
		return elem.prop(Button#.qname)
	}
	
	private Void init() {
		elem.onEvent("mousedown", false) |e| {
			e.stop
			if (!enabled) return
			this._event = e
			mouseDown	= true
			doMouseDown
		}

		elem.onEvent("mouseup", false) |e| {
			if (!enabled) return
			this._event = e
			doMouseUp
			if (mouseDown) {
				fireAction(e)
				openPopup
			}
			mouseDown = false
		}

		elem.onEvent("mouseleave", false) |e| {
			if (!mouseDown) return
			this._event = e
			doMouseUp
			mouseDown = false
		}

		elem.onEvent("keydown", false) |e| {
			if (!enabled) return
			_event = e
			if (e.key == Key.space) {
			// FIXME ListButton
//			if (e.key == Key.space || (this is ListButton && e.key == Key.down)) {
				doMouseDown
				if (cbPopup == null) Win.cur.setTimeout(100ms) |->| { fireAction(e); doMouseUp }
				else {
					if (popup?.isOpen == true) popup.close
					else openPopup
				}
			}
		}
	}

	** Callback when button action is invoked.
	Void onAction(|This| f) { this.cbAction = f }

	** Callback to create Popup to display when button is pressed.
	Void onPopup(|Button->Popup| f) { this.cbPopup = f }

	** Offset to apply to default origin for `onPopup`.
	@NoDoc Point popupOffset := Point.defVal

// TODO: how should this work?
// TODO: something like onLazyPopup work better?
	** Remove existing popup callback.
	@NoDoc Void removeOnPopup() { this.cbPopup = null }

	** Programmatically open popup, or do nothing if no popup defined.
	Void openPopup() {
		if (cbPopup == null) return
		if (popup?.isOpen == true) return

		x := elem.pagePos.x + popupOffset.x
		y := elem.pagePos.y + popupOffset.y + elem.size.h.toInt
		w := elem.size.w.toInt

		if (isCombo) {
			// stretch popup to fit combo
			combo := elem.parent
			x = combo.pagePos.x
			w = combo.size.w.toInt
		}

		showDown
		popup = cbPopup(this)

		// adjust popup origin if haligned
		switch (popup.halign) {
			case Align.center: x += w / 2
			case Align.right:	x += w
		}

		// use internal _onClose to keep onClose available for use
		popup._onClose {
			showUp
			// FIXME Combo
//			if (isCombo) ((Combo)this.parent).field.focus
//			else this.focus
		}

		// limit width to button size if not explicity set
		if (popup.elem.style.effective("min-width") == null)
			popup.elem.style->minWidth = "${w}px"

		popup.open(x, y)
	}

	** The enabled attribute.
	Bool enabled {
		get { elem->disabled->not }
		set {
			elem->disabled = it.not
			if (it) {
				elem.style.removeClass("disabled")
				elem->tabIndex = 0
			} else {
				elem.style.addClass("disabled")
				elem->tabIndex = -1
			}
		}
	}

	// internal use only
	internal Bool isCombo := false

	internal Void showDown() { elem.style.addClass("down") }
	internal Void showUp()	 { elem.style.removeClass("down") }
	internal virtual Void doMouseDown()	{ showDown }
	internal virtual Void doMouseUp()	{ showUp }
	internal Bool mouseDown := false

	private Void fireAction(Event e) {
		cbAction?.call(this)
	}

	// TODO: not sure how this works yet
	@NoDoc Event? _event

	private Popup? popup	:= null
	private Func? cbAction	:= null
	private Func? cbPopup	:= null
}