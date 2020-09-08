using dom

**
** Checkbox displays a checkbox that can be toggled on and off.
**
** - domkit 1.0.75
@Js class Checkbox {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "input" && elem["type"] != "checkbox")
			throw ArgErr("Elem not an input checkbox: ${elem.html}")

		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		elem := Win.cur.doc.querySelector(selector)
		if (elem == null && checked) throw Err("Could not find Checkbox: ${selector}")
		return fromElem(elem)
	}
	
	static new fromElem(Elem? elem) {
		if (elem == null) return null
		if (elem.prop(Checkbox#.qname) == null)
			elem.setProp(Checkbox#.qname, Checkbox._make(elem))
		return elem.prop(Checkbox#.qname)
	}

	private Void init() {
		elem.onEvent("change", false) |e| {
			fireAction(e)
		}
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

	** Callback when 'enter' key is pressed.
	Void onAction(|This| f) { this.cbAction = f }

	internal Void fireAction(Event? e) { cbAction?.call(this) }
	private Func? cbAction := null
}