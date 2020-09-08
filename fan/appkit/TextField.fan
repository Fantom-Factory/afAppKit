using dom

**
** Text field input element.
**
** - domkit 1.0.75
@Js class TextField {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "input" && elem.tagName != "textarea")
			// note the "type" attr may be blank, text, email, number, ...  
			throw ArgErr("Elem not an input: ${elem.html}")
	
		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		elem := Win.cur.doc.querySelector(selector)
		if (elem == null && checked) throw Err("Could not find TextField: ${selector}")
		return fromElem(elem)
	}
	
	static new fromElem(Elem? elem) {
		if (elem == null) return null
		if (elem.prop(TextField#.qname) == null)
			elem.setProp(TextField#.qname, TextField._make(elem))
		return elem.prop(TextField#.qname)
	}

	private Void init() {
		elem.onEvent("input", false) |e| {
			checkUpdate
			fireModify(e)
		}
		
		elem.onEvent("keydown", false) |e| {
			if (e.key == Key.enter) fireAction(e)
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
	
	** Preferred width of field in columns, or 'null' for default.
	** (Only applicable for TextAreas)
	Int? cols {
		get { elem->size }
		set { elem->size = it }  
	}

	** Hint that is displayed in the field before a user enters a
	** value that describes the expected input, or 'null' for no
	** placeholder text.
	Str? placeholder {
		get { elem->placeholder }
		set { elem->placeholder = it }
	}

	** Set to 'true' to set field to readonly mode.
	Bool ro {
		get { elem->readOnly }
		set { elem->readOnly = it }
	}

	** Set to 'true' to mask characters inputed into field.
	Bool password {
		get { elem->type == "password" }
		set { elem->type = it ? "password" : "text" }
	}

	** Name of input.
	Str? name {
		get { elem->name }
		set { elem->name = it }
	}

	** Value of text field.
	Str value {
		get { elem->value }
		set { elem->value = it; checkUpdate }
	}

	** Callback when value is modified by user.
	Void onModify(|This| f) { this.cbModify = f }

	** Callback when 'enter' key is pressed.
	Void onAction(|This| f) { this.cbAction = f }

	** Select given range of text
	Void select(Int start, Int end) {
		elem->selectionStart = start
		elem->selectionEnd	 = end
	}

	internal Void fireAction(Event? e) { cbAction?.call(this) }
	private Func? cbAction := null

	internal Void fireModify(Event? e) { cbModify?.call(this) }
	private Func? cbModify := null

	// framework use only
	private Void checkUpdate() {
//		if (parent is Combo) ((Combo) parent).update(val.trim)
	}
}