using dom::Event
using dom::Elem
using dom::Win
using graphics::Size
using graphics::Point

** StickySidebar, for when CSS sticky just isn't enough.
** 
** pre>
** <div class="main-content">
** 
**     <div class="sidebar">
**         <div class="sidebar__inner">
**             <!-- Content goes here -->
**         </div>
**     </div>
** 
**     <div class="content">
**         <!-- Content goes here -->
**     </div>
** 
** </div>
** <pre
**  
** Adapted from `https://abouolia.github.io/sticky-sidebar/` and its Scrollable Sticky Element.
** 
** Updates:
**  - '_reStyle' was never reset back to 'false' resulting in CSS styles being applied ALL the time.
**  - 'calcDimensions()' calcs width and height from 'sidebar', not 'sidebarInner', and width is manually set on 'sidebarInner' when scrolling! 
@Js class StickySidebar {
	
	static const Str:Obj? defOpts := [
		"topSpacing"			: 0f,					// Numeric
		"bottomSpacing"			: 0f,					// Numeric
		"innerWrapperSelector"	: ".sidebar__inner",	// String
		"stickyClass"			: "is-affixed",			// String
		"minWidth"				: 0f,					// Numeric
	].toImmutable
	
	private Str:Obj?	options
	private Elem		sidebar
	private Elem		sidebarInner
	private Elem		container
	private Str			affixedType
	private Str			direction
	private Bool		_reStyle
	private Bool		_breakpoint
	private StickySidebarDims	dimensions
	private Str			scrollDirection	:= ""
	private Bool		_running
	
	new make(Obj sidebar, [Str:Obj?]? opts := null)  {
		this.options		= defOpts.rw.setAll(opts ?: Str:Obj[:])
		this.sidebar		= sidebar is Elem ? sidebar : (Win.cur.doc.querySelector(sidebar.toStr) ?: throw Err("Elem \"${sidebar}\" does not exist"))
		this.container		= this.sidebar.parent
		
		// Current Affix Type of sidebar element.
		this.affixedType	= "STATIC"
		this.direction		= "down"

		this._reStyle		= false
		this._breakpoint	= false
		
		// Dimensions of sidebar, container and screen viewport.
		this.dimensions		= StickySidebarDims()
		
		this.sidebarInner	= this.sidebar.querySelector(this.options["innerWrapperSelector"].toStr)
		
		// Breakdown sticky sidebar if screen width below `options.minWidth`.
		this._widthBreakpoint()
		
		// Calculate dimensions of sidebar, container and viewport.
		this._calcDimensions()
		
		// Affix sidebar in proper position.
		this.stickyPosition(false)
		
		// Bind all events.
		this._bindEvents()
	}

	** Breakdown sticky sidebar when window width is below `options.minWidth` value.
	private Void _widthBreakpoint() {
		if (windowInnerSize.w <= this.options["minWidth"]) {
			this._breakpoint	= true
			this.affixedType	= "STATIC"
			
			this.sidebar.style.clear
			this.sidebar.style.removeClass(this.options["stickyClass"])
			this.sidebarInner.style.clear
		} else {
			this._breakpoint	= false
		}
	}
	
	** Bind all events of sticky sidebar plugin.
	private Void _bindEvents() {
		Win.cur.onEvent("resize", false) { this.updateSticky(it) }
		Win.cur.onEvent("scroll", false) { this.updateSticky(it) }
		
		try	ResizeObserver() |entries| {
				this.updateSticky(null)
			}.observe(this.container).observe(this.sidebarInner)
		catch {
			typeof.pod.log.warn("ResizeObserver not supported")
			resizeSensor(this.container) 	{ this.updateSticky(null) }
			resizeSensor(this.sidebarInner)	{ this.updateSticky(null) }	
		}
	}

	** Calculates dimensions of sidebar, container and screen viewpoint
	private Void _calcDimensions() {
		if (this._breakpoint) return
		dims := this.dimensions
	
		// Container of sticky sidebar dimensions.
		dims.containerTop		= offsetPoint(this.container).y
		dims.containerHeight	= clientSize (this.container).h
		dims.containerBottom	= dims.containerTop + dims.containerHeight
	
		// Sidebar dimensions. Slimer - updated from 'this.sidebarInner.size'
		dims.sidebarHeight		= this.sidebar.size.h
		dims.sidebarWidth		= this.sidebar.size.w
	
		// Screen viewport dimensions.
		dims.viewportHeight		= windowInnerSize.h
	
		// Maximum sidebar translate Y.
		dims.maxTranslateY		= dims.containerHeight - dims.sidebarHeight
	
		this._calcDimensionsWithScroll()
	}
	
	** Some dimensions values need to be up-to-date when scrolling the page.
	private Void _calcDimensionsWithScroll() {
		dims := this.dimensions
		docs := docScrollPoint
	
		dims.sidebarLeft		= offsetPoint(this.sidebar).x
	
		dims.viewportTop		= docs.y
		dims.viewportBottom		= dims.viewportTop + dims.viewportHeight
		dims.viewportLeft		= docs.x
	
		dims.topSpacing			= this.options["topSpacing"]
		dims.bottomSpacing		= this.options["bottomSpacing"]
	
		if ("VIEWPORT-TOP" == this.affixedType) {
			// Adjust translate Y in the case decrease top spacing value.
			if (dims.topSpacing < dims.lastTopSpacing) {
				dims.translateY += dims.lastTopSpacing - dims.topSpacing
				this._reStyle = true
			}

		} else if ("VIEWPORT-BOTTOM" == this.affixedType) {
			// Adjust translate Y in the case decrease bottom spacing value.
			if (dims.bottomSpacing < dims.lastBottomSpacing) {
				dims.translateY += dims.lastBottomSpacing - dims.bottomSpacing
				this._reStyle = true
			}
		}
	
		dims.lastTopSpacing		= dims.topSpacing
		dims.lastBottomSpacing	= dims.bottomSpacing
	}
	
	** Determine whether the sidebar is bigger than viewport.
	private Bool _isSidebarFitsViewport() {
		dims	:= this.dimensions
		offset	:= this.scrollDirection == "down" ? dims.lastBottomSpacing : dims.lastTopSpacing
		return this.dimensions.sidebarHeight + offset < this.dimensions.viewportHeight
	}

	** Cause the sidebar to be sticky according to affix type by adding inline
	** style, adding helper class and trigger events.
	Void stickyPosition(Bool force := false) {
		if (this._breakpoint) return

		force			= this._reStyle || force

		offsetTop		:= this.options["topSpacing"]
		offsetBottom	:= this.options["bottomSpacing"]

		affixType		:= this._getAffixType()
		style			:= this._getStyle(affixType)

		if (this.affixedType != affixType || force) {
	
			if ("STATIC" == affixType)
				this.sidebar.style.removeClass(this.options["stickyClass"])
			else
				this.sidebar.style.addClass(this.options["stickyClass"])

			outer := (Str:Obj?) style["outer"]
			outer.each |obj, key| {
				val := obj is Num ? "${obj}px" : obj.toStr
				this.sidebar.style.trap(key, [val])
			}

			inner := (Str:Obj?) style["inner"]
			inner.each |obj, key| {
				val := obj is Num ? "${obj}px" : obj.toStr
				this.sidebarInner.style.trap(key, [val])
			}

		} else {
			inner	:= (Str:Obj?) style["inner"]
			obj		:= inner["left"]
			val		:= obj is Num ? "${obj}px" : obj.toStr
			this.sidebarInner.style->left = val
		}

		this.affixedType = affixType
		this._reStyle	 = false
	}
	
	** Gets affix type of sidebar according to current scroll top and scrolling direction.
	private Str _getAffixType() {
		this._calcDimensionsWithScroll()
		dims		:= this.dimensions
		colliderTop	:= dims.viewportTop + dims.topSpacing
		affixType	:= this.affixedType

		if (colliderTop <= dims.containerTop || dims.containerHeight <= dims.sidebarHeight) {
			dims.translateY = 0f
			affixType = "STATIC"

		} else {
			affixType = ("up" == this.direction)
				? this._getAffixTypeScrollingUp()
				: this._getAffixTypeScrollingDown()
		}

		// Make sure the translate Y is not bigger than container height.
		dims.translateY = dims.translateY.max(0f)
		dims.translateY = dims.translateY.min(dims.containerHeight)
		dims.translateY = dims.translateY.round

		dims.lastViewportTop = dims.viewportTop
		return affixType
	}
	
	** Get affix type while scrolling down.
	private Str _getAffixTypeScrollingDown() {
		dims			:= this.dimensions
		sidebarBottom	:= dims.sidebarHeight	+ dims.containerTop
		colliderTop		:= dims.viewportTop		+ dims.topSpacing
		colliderBottom	:= dims.viewportBottom	- dims.bottomSpacing
		affixType		:= this.affixedType

		if (this._isSidebarFitsViewport) {
			if (dims.sidebarHeight + colliderTop >= dims.containerBottom) {
				dims.translateY = dims.containerBottom - sidebarBottom
				affixType = "CONTAINER-BOTTOM"

			} else if (colliderTop >= dims.containerTop) {
				dims.translateY = colliderTop - dims.containerTop
				affixType = "VIEWPORT-TOP"
			}

		} else {
			if (dims.containerBottom <= colliderBottom) {
				dims.translateY = dims.containerBottom - sidebarBottom
				affixType = "CONTAINER-BOTTOM"
	
			} else if (sidebarBottom + dims.translateY <= colliderBottom) {
				dims.translateY = colliderBottom - sidebarBottom
				affixType = "VIEWPORT-BOTTOM"
	
			} else if (dims.containerTop + dims.translateY < colliderTop && (dims.translateY > 0f && dims.translateY < dims.maxTranslateY)) {
				affixType = "VIEWPORT-UNBOTTOM"
			}
		}

		return affixType
	}

	** Get affix type while scrolling up.
	private Str _getAffixTypeScrollingUp() {
		dims			:= this.dimensions
		sidebarBottom	:= dims.sidebarHeight	+ dims.containerTop
		colliderTop		:= dims.viewportTop		+ dims.topSpacing
		colliderBottom	:= dims.viewportBottom	- dims.bottomSpacing
		affixType		:= this.affixedType

		if (colliderTop <= dims.translateY + dims.containerTop) {
			dims.translateY = colliderTop - dims.containerTop
			affixType = "VIEWPORT-TOP"

		} else if (dims.containerBottom <= colliderBottom) {
			dims.translateY = dims.containerBottom - sidebarBottom
			affixType = "CONTAINER-BOTTOM"
	
		} else if (!this._isSidebarFitsViewport) {
	
			if (dims.containerTop < colliderTop && (dims.translateY > 0f && dims.translateY < dims.maxTranslateY)) {
				affixType = "VIEWPORT-UNBOTTOM"
			}
		}

		return affixType
	}
	
	** Gets inline style of sticky sidebar wrapper and inner wrapper according to its affix type.
	private Str:Obj? _getStyle(Str affixType) {
		dims	:= this.dimensions
		style	:= [
			"inner" : Str:Obj?[
				"position"	: "relative",
				"top"		: "",
				"left"		: "",
				"bottom"	: "",
				"width"		: "",
				"transform"	: "",
			],
			"outer"	: Str:Obj?[
				"height"	: "",
				"position"	: "",
			]
		]

		switch (affixType) {
			case "VIEWPORT-TOP":
				style["inner"].setAll([
					"position"	: "fixed",
					"top"		: dims.topSpacing,
					"left"		: dims.sidebarLeft - dims.viewportLeft,
					"width"		: dims.sidebarWidth
				])

			case "VIEWPORT-BOTTOM":
				style["inner"].setAll([
					"position"	: "fixed",
					"top"		: "auto",
					"left"		: dims.sidebarLeft,
					"bottom"	: dims.bottomSpacing,
					"width"		: dims.sidebarWidth
				])

			case "CONTAINER-BOTTOM":
			case "VIEWPORT-UNBOTTOM":
				style["inner"].setAll([
					"transform" : "translate3d(0, ${dims.translateY.toInt}px, 0)" 
				])
		}

		switch (affixType) {
			case "VIEWPORT-TOP":
			case "VIEWPORT-BOTTOM":
			case "VIEWPORT-UNBOTTOM":
			case "CONTAINER-BOTTOM":
				style["outer"].setAll([
					"height"	: dims.sidebarHeight,
					"position"	: "relative"
				])
		}

		return style
	}

	** Switches between functions stack for each event type, if there's no
	** event, it will re-initialize sticky sidebar.
	private Void updateSticky(Event? event) {
		if (this._running) return
		this._running = true

		eventType := event?.type ?: "resize"
		
		Win.cur.reqAnimationFrame {
			switch (eventType) {
				// When browser is scrolling and re-calculate just dimensions
				// within scroll.
				case "scroll":
					this._calcDimensionsWithScroll()
					this._observeScrollDir()
					this.stickyPosition(false)
		
				// When browser is resizing or there's no event, observe width
				// breakpoint and re-calculate dimensions.
				case "resize":
				default:
					this._widthBreakpoint()
					this._calcDimensions()
					this.stickyPosition(true)
			}
			this._running = false
		}
	}


	** Observe browser scrolling direction top and down.
	private Void _observeScrollDir() {
		dims := this.dimensions
		if (dims.lastViewportTop == dims.viewportTop) return

		furthest := "down" == this.direction ? dims.viewportTop.min(dims.lastViewportTop) : dims.viewportTop.max(dims.lastViewportTop)

		// If the browser is scrolling not in the same direction.
		if (dims.viewportTop == furthest)
			this.direction = "down" == this.direction ?  "up" : "down"
	}

//	** Destroy sticky sidebar plugin.
//	Void destroy(){
//		window.removeEventListener("resize", this, {capture: false})
//		window.removeEventListener("scroll", this, {capture: false})
//
//		this.sidebar.classList.remove(this.options.stickyClass)
//		this.sidebar.style.minHeight = ""
//
//		this.sidebar.removeEventListener("update" + EVENT_KEY, this)
//
//		styleReset := {inner: {}, outer: {}}
//
//		styleReset.inner = {position: "", top: "", left: "", bottom: "", width: "",  transform: ""}
//		styleReset.outer = {height: "", position: ""}
//
//		for( let key in styleReset.outer )
//			this.sidebar.style[key] = styleReset.outer[key]
//
//		for( let key in styleReset.inner )
//			this.sidebarInner.style[key] = styleReset.inner[key]
//
//		if (this.options.resizeSensor && "undefined" != typeof ResizeSensor) {
//			ResizeSensor.detach(this.sidebarInner, this.handleEvent)
//			ResizeSensor.detach(this.container, this.handleEvent)
//		}
//	}

	private native static Size windowInnerSize()

	private native static Size clientSize(Elem elem)

	private native static Point offsetPoint(Elem elem)

	private native static Point docScrollPoint()

	private native static Void resizeSensor(Elem elem, |This| fn)
}

@Js internal class StickySidebarDims {
	Float	translateY
	Float	maxTranslateY
	Float	topSpacing
	Float	lastTopSpacing
	Float	bottomSpacing
	Float	lastBottomSpacing
	Float	sidebarHeight
	Float	sidebarWidth
	Float	sidebarLeft
	Float	containerTop
	Float	containerHeight
	Float	containerBottom
	Float	viewportHeight
	Float	viewportTop
	Float	viewportBottom
	Float	viewportLeft
	Float	lastViewportTop
}
		