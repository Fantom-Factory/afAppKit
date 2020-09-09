using dom::Doc
using dom::Key
using dom::Win
using dom::Elem
using dom::Event
using dom::CssDim

@Js class Modal {
	Duration	transistionDur	:= 200ms
	Str:Str		transitionFrom	:= Str:Str[
		"transform"	: "scale(0.875)",
		"opacity"	: "0"
	]
	Str:Str		transitionTo	:= Str:Str[
		"transform"	: "scale(1)",
		"opacity"	: "1"
	]
	
	private Elem? 	mask
	private Func?	cbOpened
	private Func?	cbClosed
	private Func?	cbKeyDown
			Bool	isOpen { private set }
	
	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem
		
		this.onEvent("keydown", false) |e| {
			// Enter for closing "Wrong - Try Again!" Mini-Modals
			if (e.key == Key.esc || (elem.querySelector("form") == null && e.key == Key.enter))
				close
			else
				cbKeyDown?.call(e)
		}
		
		this.onEvent("click", false) |e| {
			if (e.target == elem) {
				// ignore background clicks on modals with Forms
				// Emma has a habit (on Chrome) of *over-selecting* text which closes the dialog!
				if (elem.querySelector("form") == null)
					close
			}
		}
		
		elem.querySelectorAll("[data-dismiss=modal]").each {
			AppElem.onEvent(it, "click", false) { close }
		}
	}

	static new fromSelector(Str selector) {
		elem := doc.querySelector(selector)
		if (elem == null) throw Err("Could not find Modal: ${selector}")
		return fromElem(elem)
	}

	static new fromElem(Elem elem) {
		if (elem.prop(Modal#.qname) == null)
			elem.setProp(Modal#.qname, Modal._make(elem))
		return elem.prop(Modal#.qname)
	}
	
	static Modal createInfoDialog(Str title, Obj body) {
		// todo style info dialogs more
		createDialog(title, body)
	}
	
	static Modal createErrDialog(Str title, Obj body) {
		// todo style err dialogs more
		createDialog(title, body)
	}

	static Modal createMiniModal(Obj body, Bool spinIn) {
		modal := div("modal") {
			it["tabindex"]	= "-1"
			it["role"]		= "dialog"
			div("modalDialog modalDialog-centered") {
				div("modalContent") {
					it["data-dismiss"]				= "modal" // let any click close these
					it.style->cursor				= "pointer"
					div("modalBody") {
						it.add(Elem("button") {
							it.style.addClass("close")
							it["type"]				= "button"
							it["data-dismiss"]		= "modal"
							it["aria-label"]		= "Close"
							Elem("span") {
								it["aria-hidden"]	= "true"
								it.html				= "&times;"
							},
						})
						if (body is Elem)
							it.add(body)
						if (body is Str)
							it.add(Elem("span") { it.html = body.toStr.replace("\n", "<br/>") })
					},
				},
			},
		}
		doc.body.add(modal)
		return fromElem(modal) {
			if (spinIn) {
				degTo   := (-15..15).random
				degFrom := degTo + (spinIn ? 270 : 0)
				it.transistionDur = spinIn ? 350ms : 200ms
				it.transitionTo  ["transform"] = "scale(1.0) rotate(${degTo}deg)"
				it.transitionFrom["transform"] = "scale(0.5) rotate(${degFrom}deg)"
			}
			it.onClosed {
				// it's a one-time-shot baby!
				doc.body.remove(modal)
			}
		}
	}

	static Modal createDialog(Str title, Obj body) {
		modal := div("modal") {
			it["tabindex"]	= "-1"
			it["role"]		= "dialog"
			div("modalDialog modalDialog-centered") {
				div("modalContent") {
					div("modalHeader") {
						div("modalTitle") {
							it.text = title
							Elem("button") {
								it.style.addClass("close")
								it["type"]				= "button"
								it["data-dismiss"]		= "modal"
								it["aria-label"]		= "Close"
								Elem("span") {
									it["aria-hidden"]	= "true"
									it.html				= "&times;"
								},
							},
						},
					},
					div("modalBody") {
						if (body is Elem)
							it.add(body)
						if (body is Str)
							it.add(Elem("span") { it.html = body.toStr.replace("\n", "<br/>") })
						div("modalButtons") {
							Elem("button") {
								it.style.addClass("btn link")
								it["type"]				= "button"
								it["data-dismiss"]		= "modal"
								it["aria-label"]		= "Close"
								it.text					= "Close"
							},
						},
					},
				},
			},
		}
		doc.body.add(modal)
		return fromElem(modal) {
			it.onClosed {
				// it's a one-time-shot baby!
				doc.body.remove(modal)
			}
		}
	}
	
	private static Elem div(Str css) {
		Elem("div") { it.style.addClass(css) }
	}

	This open() {
		// we remove the body's scrollbar so the body can't be scrolled behind the modal
		// but that makes the body wider and re-flows the content, so we add extra body padding to keep everything in place 
		JsUtil.addScrollbarWidth(doc.body, "padding-right")

		// the mask is just for show - it's the modal that's active and receives all the events
		mask = Elem("div") { it.style.addClass("modalBackdrop fade show") }
		doc.body.style.addClass("modal-open")
		doc.body.add(mask)
		mask.style->opacity	= "0"
		mask.transition([
			"opacity"	: "0.5"
		], ["transition-timing-function":"ease-out"], transistionDur)

		elem.style->display	= "block"
		elem.removeAttr		("aria-hidden")
		elem.setAttr		("aria-modal", "true")
		elem.style.addClass	("show")
		
		transitionFrom.each |val, prop| { elem.style[prop] = val }
		elem.transition(transitionTo, ["transition-timing-function":"ease-out"], transistionDur) {
			fireOpened	// this could return true to prevent the modal from showing...? meh.
			elem.focus
		}

		isOpen = true
		return this
	}

	Void close() {
		// don't allow double closes - it results in an NPE
		if (isOpen == false) return

		elem.transition(transitionFrom, ["transition-timing-function":"ease-in"], transistionDur) {
			elem.style->display	= "none"
			elem.setAttr			("aria-hidden", "true")
			elem.removeAttr			("aria-modal")
			elem.style.removeClass	("show")
		}

		mask.transition([
			"opacity"	:"0"
		], ["transition-timing-function":"ease-in"], transistionDur) {
			doc.body.style.removeClass("modal-open")
			JsUtil.removeScrollbarWidth(doc.body, "padding-right")
			doc.body.remove(mask)
			mask = null
			
			// make sure the Modal closes before we fire the next handler
			win.setTimeout(10ms) { fireClosed }
		}

		isOpen = false
	}
	
	** Callback when a key is pressed while Dialog is open, including
	** events that where dispatched outside the dialog.
	Void onKeyDown(|Event e|? newFn) {
		cbKeyDown = ErrHandler.instance.wrapFn(newFn)
	}
	
	** Callback when dialog is opened.
	Void onOpened(|This|? newFn) {
		cbOpened = ErrHandler.instance.wrapFn(newFn)
	}

	** Callback when popup is closed.
	Void onClosed(|This|? newFn) {
		cbClosed = ErrHandler.instance.wrapFn(newFn)
		// this is actually unhelpful - but if ever needed, should be called addOnClosed()  
//		oldFn := cbClosed
//		cbClosed = oldFn == null ? newFn : |Modal th| { oldFn(th); newFn(th) }
	}
	
	** Wraps up event handling to use err handling
	private Func onEvent(Str type, Bool useCapture, |Event e| handler) {
		AppElem.onEvent(elem, type, useCapture, handler)
	}

	private Void fireOpened()	{ cbOpened?.call(this)	}
	private Void fireClosed()	{ cbClosed?.call(this)	}
	
	private static Win win() { Win.cur }
	private static Doc doc() { win.doc }
}
