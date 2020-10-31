using dom::Elem
using dom::Style

**
** Hyperlink anchor element
**
@Js class Link {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "a")
			throw ArgErr("Link elem not an anchor: ${elem.html}")
	}

	static new fromSelector(Str selector, Bool checked := true) {
		AppElem.fromSelector(selector, Link#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, Link#, checked)
	}

	** Get the Style instance for this element.
	Style style() { elem.style }

	** The target attribute specifies where to open the linked document.
	Str target {
		get { this->target }
		set { this->target = it }
	}

	** URI to hyperlink to.
	Uri url {
		get { Uri.decode(elem->href ?: "") }
		set { elem->href = it.encode }
	}
}