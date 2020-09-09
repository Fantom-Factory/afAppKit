using dom::Elem
using dom::Win

@Deprecated	// until I can work out a proper use - and how to worm it into AppInit
@Js class AppElemInit {
	
	Void init() {
		doc := Win.cur.doc
		
		// FIXME not sure about this .appkit-dropdown - would rather use data-attributes
		doc.querySelectorAll(".appkit-dropdown").each |dd| {
			btn := Button(dd.querySelector(".appkit-button"), true)
			pop := Popup (dd.querySelector(".appkit-popup" ), true)
			men := Menu  (dd.querySelector(".appkit-menu"  ), true)
			
			if (btn != null && (pop != null || men != null)) {
				btn.onPopup { men ?: pop }
			}
		}
	}
}
