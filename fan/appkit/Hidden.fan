using dom::Elem
using dom::Event
using dom::Key

**
** Hidden input element.
**
@Js class Hidden {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "input")
			throw ArgErr("Hidden elem not an input: ${elem.html}")
	
		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		AppElem.fromSelector(selector, Hidden#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, Hidden#, checked)
	}

	private Void init() {
		elem.style.addClass("appkit-hidden")
	}

	** The enabled attribute.
	Bool enabled {
		get { elem->disabled->not }
		set {
			elem->disabled = it.not
			if (it) {
				elem.style.removeClass("disabled")
			} else {
				elem.style.addClass("disabled")
			}
		}
	}

	** Name of input.
	Str? name {
		get { elem->name }
		set { elem->name = it }
	}

	** Value of hidden field.
	Str value {
		get { elem->value }
		set { elem->value = it }
	}
}