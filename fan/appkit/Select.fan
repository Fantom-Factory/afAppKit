using dom::Elem
using dom::Event
using dom::Key
using dom::Style
using afAppKit::AppElem

**
** Select input element.
**
@Js class Select {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "select")
			throw ArgErr("Select elem not select: ${elem.html}")

		init()
	}

	static new fromSelector(Str? selector, Bool checked := true) {
		AppElem.fromSelector(selector, Select#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, Select#, checked)
	}

	private Void init() {
		elem.style.addClass("appkit-control appkit-select")

		this.onEvent("change", false) |e| {
			fireModify(e)
		}
	}

	** Get the Style instance for this element.
	Style style() { elem.style }

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

	** Set to 'true' to set field to readonly mode.
	Bool ro {
		get { elem->readOnly }
		set { elem->readOnly = it }
	}

	** Name of input.
	Str? name {
		get { elem->name }
		set { elem->name = it }
	}

	** Value of text field.
	Str value {
		get { elem->value }
		set { elem->value = it }
	}

	** Callback when value is modified by user.
	Void onModify(|This|? f) { this.cbModify = AppKitErrHandler.cur.wrapFn(f) }

	** Select given range of text
	Void select(Int start, Int end) {
		elem->selectionStart = start
		elem->selectionEnd	 = end
	}

	** Wraps up event handling to use err handling
	private Func onEvent(Str type, Bool useCapture, |Event e| handler) {
		AppElem.onEvent(elem, type, useCapture, handler)
	}
	
	internal Void fireModify(Event? e) { cbModify?.call(this) }
	private Func? cbModify := null
}