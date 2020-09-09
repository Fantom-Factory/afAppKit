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
@Js class Button {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

//		if (elem.tagName != "button")
//			throw ArgErr("Elem not button: ${elem.html}")
		
		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		AppElem.fromSelector(selector, Button#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, Button#, checked)
	}
	
	private Void init() {
		elem.style.addClass("appkit-control appkit-control-button appkit-button")
		
		// FIXME use ErrHandler - get from actor locals
		
		this.onEvent("mousedown", false) |e| {
			e.stop
			if (!enabled) return
			this._event = e
			mouseDown	= true
			doMouseDown
		}

		this.onEvent("mouseup", false) |e| {
			if (!enabled) return
			this._event = e
			doMouseUp
			if (mouseDown) {
				fireAction(e)
				openPopup
			}
			mouseDown = false
		}

		this.onEvent("mouseleave", false) |e| {
			if (!mouseDown) return
			this._event = e
			doMouseUp
			mouseDown = false
		}

		this.onEvent("keydown", false) |e| {
			if (!enabled) return
			_event = e
			if (e.key == Key.space) {
			// TODO ListButton
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
	Void onAction(|This| f) { this.cbAction = ErrHandler.instance.wrapFn(f) }

	** Callback to create Popup to display when button is pressed.
	Void onPopup(|Button->Popup| f) { this.cbPopup = ErrHandler.instance.wrapObjFn(f) }

	** Offset to apply to default origin for `onPopup`.
	@NoDoc Point popupOffset := Point.defVal

// todo: how should this work?
// todo: something like onLazyPopup work better?
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
		// popup is null if cbPopup err'ed - Slimer
		if (popup == null) return

		// adjust popup origin if haligned
		switch (popup.halign) {
			case Align.center	: x += w / 2
			case Align.right	: x += w
		}

		// use internal _onClose to keep onClose available for use
		popup._onClose {
			showUp
			// TODO Combo
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
		get { (elem->disabled as Bool)?.not ?: true  }
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

	** Wraps up event handling to use err handling
	private Func onEvent(Str type, Bool useCapture, |Event e| handler) {
		AppElem.onEvent(elem, type, useCapture, handler)
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