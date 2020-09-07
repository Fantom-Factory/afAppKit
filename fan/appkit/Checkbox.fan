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
		
		elem.onEvent("change", false) |e| {
			fireAction(e)
		}
	}

	static new fromSelector(Str selector) {
		elem := Win.cur.doc.querySelector(selector)
		if (elem == null) throw Err("Could not find Checkbox: ${selector}")
		return fromElem(elem)
	}
	
	static new fromElem(Elem elem) {
		if (elem.prop(Checkbox#.qname) == null)
			elem.setProp(Checkbox#.qname, Checkbox._make(elem))
		return elem.prop(Checkbox#.qname)
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