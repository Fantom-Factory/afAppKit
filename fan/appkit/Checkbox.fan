using dom::Elem
using dom::Event
using dom::Style

**
** Checkbox displays a checkbox that can be toggled on and off.
**
@Js class Checkbox {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "input" && elem["type"] != "checkbox")
			throw ArgErr("Checkbox elem not an input checkbox: ${elem.html}")

		init()
	}

	static new fromSelector(Str? selector, Bool checked := true) {
		AppElem.fromSelector(selector, Checkbox#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, Checkbox#, checked)
	}

	private Void init() {
		elem.style.addClass("appkit-checkbox")
		
		this.onEvent("change", false) |e| {
			fireAction(e)
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

	** Get or set indeterminate flag.
	Bool indeterminate {
		get { elem->indeterminate }
		set { elem->indeterminate = it }
	}

	** Name of input.
	Str? name {
		get { elem->name }
		set { elem->name = it }
	}

	** Value of checked.
	Bool checked {
		get { elem->checked }
		set { elem->checked = it }
	}

	** Wraps up event handling to use err handling
	private Func onEvent(Str type, Bool useCapture, |Event e| handler) {
		AppElem.onEvent(elem, type, useCapture, handler)
	}
	
	** Callback when 'enter' key is pressed.
	Void onAction(|This|? f) { this.cbAction = AppKitErrHandler.cur.wrapFn(f) }

	internal Void fireAction(Event? e) { cbAction?.call(this) }
	private Func? cbAction := null
}