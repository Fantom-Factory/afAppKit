using afAppKit::Inject
using afAppKit::Button
using afAppKit::Menu
using afAppKit::Popup
using afAppKit::Align
using dom::Elem
using dom::Win
using dom::CssDim
using graphics::Point
using graphics::GeomUtil

@Js class AppKitInit {
	
	** MiniIoc baulks without an explicit ctor.
	new make(|This|? f := null) { f?.call(this) }
	
	Void init() {
		initDropdowns
	}

	Void initDropdowns() {
		doc := Win.cur.doc

		doc.querySelectorAll("[data-toggle='dropdown']").each |tog| {
			btn := Button(tog)
			dwn := findParent(tog, ".dropdown")
			pop := Popup  (findImmediateChild(dwn, ".dropdown-popup"), true)	// true still allows null to be passed (and returned)
			if (pop == null)
				pop = Menu(findImmediateChild(dwn, ".dropdown-menu"), true)		// true still allows null to be passed (and returned)

			ali := pop.elem.attr("data-halign")
			if (ali != null)
				pop.halign = Align.fromStr(ali)

			offset := pop.elem.attr("data-offset")
			if (offset != null) {
				offs := (Str[]) offset.split.map { toPx(it) }
				btn.popupOffset = Point(offs.join(" "), true)
			}

			btn.onPopup { pop }
		}
	}

	private Str toPx(Str str) {
		if (str == "0") str = "0px"
		css := CssDim(str)
		if (css.unit != "px") throw Err("data-offset MUST have px units: ${str}")
		return css.val.toStr
	}
	
	private Elem? findImmediateChild(Elem elem, Str selector) {
		// https://stackoverflow.com/questions/6481612/queryselector-search-immediate-children#answer-6481787
		elem.querySelectorAll(selector).find { it.parent == elem }
	}
	
	private Elem? findParent(Elem elem, Str cssClass) {
		cssClass = cssClass.replace(".", " ").trim
		return elem.style.hasClass(cssClass) ? elem : (elem.parent == null ? null : findParent(elem.parent, cssClass))
	}
}
