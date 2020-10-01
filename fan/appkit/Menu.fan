using dom::Elem
using dom::Event
using dom::Key
using graphics::Point

**
** Popup menu
**
**   html:
**   <div class="appkit-dropdown">
**       <button class="appkit-button" type="button"> Click Me </button>
**       <div class="appkit-menu">
**           <a class="appkit-menuItem" href="#">Alpha</a>
**           <a class="appkit-menuItem" href="#">Beta</a>
**           <div class="appkit-menuHr"/>
**           <a class="appkit-menuItem" href="#">Gamma</a>
**       </div>
**   </div>
** 
**   slim:
**    div.appkit-dropdown
**       button.appkit-button (type="button") Click Me
**       div.appkit-menu
**           a.appkit-menuItem (href="#") Alpha  
**           a.appkit-menuItem (href="#") Beta  
**           div.appkit-menuHr  
**           a.appkit-menuItem (href="#") Gamma
** 
@Js class Menu : Popup {

	private new _make(Elem elem) : super(elem) {
		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		AppElem.fromSelector(selector, Menu#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, Menu#, checked)
	}
	
	private Void init() {
		elem->tabIndex = 0
		elem.style.addClass("appkit-menu")
		this.onOpen { this.elem.focus }
		this.onEvent("mouseleave", false) { select(null) }
		this.onEvent("mouseover", false) |e| {
			// keyboard scrolling generates move/over events we need to filter out
			if (lastEvent > 0) { lastEvent=0; return }

			// bubble to MenuItem
			Elem? t := e.target
			// SlimerDude - this "makes" every class a MenuItem - not sure what it is we're doing here
//			while (t != null && MenuItem(t, false) == null) t = t?.parent
			while (t != null && t.style.hasClass("dropdown-item")) t = t?.parent
			if (t == null) { select(null); return }

			// check for selection
			index := elem.children.findIndex |k| { t == k }
			if (index != null) {
				item := MenuItem(elem.children[index])
				select(item.enabled ? index : null)
			}
			lastEvent = 0
		}
		this.onEvent("mousedown", false) |e| { armed = true }
		this.onEvent("mouseup",	 false) |e| { if (armed) fireAction(e) }
		this.onEvent("keydown", false) |e| {
			switch (e.key) {
				case Key.esc	: close
				case Key.up		: e.stop; lastEvent=1; select(selIndex==null ? findFirst : findPrev(selIndex))
				case Key.down	: e.stop; lastEvent=1; select(selIndex==null ? findFirst : findNext(selIndex))
				case Key.space	: // fall-thru
				case Key.enter	: e.stop; fireAction(e)
				default:
					if (onCustomKeyDown != null) {
						e.stop
						lastEvent = 1
						onCustomKeyDown.call(e)
					}
			}
		}
	}

	protected override Void onBeforeOpen() {
		// reselect to force selected item to scroll into view
		if (selIndex != null) select(selIndex)
	}

	@NoDoc Void select(Int? index) {
		kids := elem.children
		if (kids.size == 0) return

		// clear old selection
		if (selIndex != null) kids[selIndex].style.removeClass("appkit-sel")

		// clear all selection
		if (index == null) {
			selIndex = null
			return
		}

		// check bounds
		if (index < 0) index = 0
		if (index > kids.size-1) index = kids.size-1

		// new selection
		item := kids[index]
		item.style.addClass("appkit-sel")
		this.selIndex = index

		// scroll if needed
		sy := elem.scrollPos.y
		mh := elem.size.h
		iy := item.pos.y
		ih := item.size.h

		if (sy > iy) elem.scrollPos = Point(0f, iy)
		else if (sy + mh < iy + ih) elem.scrollPos = Point(0f, (iy + ih - mh))
	}

	private Int? findFirst() {
		i := 0
		kids := elem.children
		while (i++ < kids.size-1) {
			item := MenuItem(kids[i])
			if (item != null && item.enabled) return i
		}
		return null
	}

	private Int? findPrev(Int start) {
		i := start
		kids := elem.children
		while (--i >= 0) {
			item := MenuItem(kids[i])
			if (item != null && item.enabled) return i
		}
		return start
	}

	private Int? findNext(Int start) {
		i := start
		kids := elem.children
		while (++i < kids.size) {
			item := MenuItem(kids[i])
			if (item != null && item.enabled) return i
		}
		return start
	}

	private Void fireAction(Event e) {
		if (selIndex == null) return
		item := MenuItem(elem.children[selIndex])
		item.fireAction(e)
	}

	** Wraps up event handling to use err handling
	private Func onEvent(Str type, Bool useCapture, |Event e| handler) {
		AppElem.onEvent(elem, type, useCapture, handler)
	}

	// internal use only
	internal Func?	onCustomKeyDown := null
	private  Int?	selIndex
	private  Int	lastEvent		:= 0	 	// 0=mouse, 1=key
	private  Bool	armed			:= false	// don't fire mouseUp unless we first detect a mouse down
}

**
** MenuItem for a `Menu`
**
@Js class MenuItem {
	
	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem
		init()
	}

	static new fromSelector(Str selector, Bool checked := true) {
		AppElem.fromSelector(selector, MenuItem#, checked)
	}
	
	static new fromElem(Elem? elem, Bool checked := true) {
		AppElem.fromElem(elem, MenuItem#, checked)
	}
	
	private Void init() {
		elem.style.addClass("appkit-control appkit-menuItem")
	}

	Bool enabled {
		get { !elem.style.hasClass("disabled") }
		set {  elem.style.toggleClass("disabled", !it) }
	}

	** Callback when item is selected.
	Void onAction(|This| f) { this.cbAction = ErrHandler.instance.wrapFn(f) }

	internal Void fireAction(Event e) {
		if (!enabled) return
//		_event = e
		Popup.fromElem(elem.parent)?.close
		cbAction?.call(this)
	}

	// todo: not sure how this works yet
//	@NoDoc Event? _event

	private Func? cbAction := null
}