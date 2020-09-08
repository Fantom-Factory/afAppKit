using dom::Elem
using dom::Win

@Js class AppElemInit {
	
	Void init() {
		doc := Win.cur.doc
		
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
