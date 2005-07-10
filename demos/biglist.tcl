proc DemoBigList {} {

	global BigList

	set T .f2.f1.t

	#
	# Configure the treectrl widget
	#

	$T configure -selectmode extended \
		-showroot no -showbuttons yes -showlines no \
		-showrootlines no

	# Hide the borders because child windows appear on top of them
	$T configure -borderwidth 0 -highlightthickness 0

	#
	# Create columns
	#

	$T column create -expand yes -text Item -itembackground {#F7F7F7} -tag colItem
	$T column create -text "Item ID" -justify center -itembackground {} -tag colID
	$T column create -text "Parent ID" -justify center -itembackground {} -tag colParent

	# Specify the column that will display the heirarchy buttons and lines
	$T configure -treecolumn colItem

	#
	# Create elements
	#

	set BigList(bg) $::SystemButtonFace
	set outline gray70

	$T element create eRectTop.e rect -outline $outline -fill $BigList(bg) \
		-draw {yes open no {}} -outlinewidth 1 -open es
	$T element create eRectTop.we rect -outline $outline -fill $BigList(bg) \
		-draw {yes open no {}} -outlinewidth 1 -open wes
	$T element create eRectTop.w rect -outline $outline -fill $BigList(bg) \
		-draw {yes open no {}} -outlinewidth 1 -open ws
	$T element create eRectBottom rect -outline $outline -fill $BigList(bg) \
		-outlinewidth 1 -open n

	# Title
	$T element create elemBorderTitle border -relief {sunken open raised {}} -thickness 1 \
		-filled yes -background $::SystemButtonFace
	$T element create elemTxtTitle text \
		-font [list "[$T cget -font] bold"]

	# Citizen
	$T element create elemRectSel rect -showfocus no \
		-fill [list $::SystemHighlight {selected focus} gray {selected !focus}]
	$T element create elemTxtItem text \
		-fill [list $::SystemHighlightText {selected focus}]
	$T element create elemTxtName text \
		-fill [list $::SystemHighlightText {selected focus} blue {}]

	# Citizen info
	$T element create elemWindow window

	#
	# Create styles using the elements
	#

	set S [$T style create styTitle]
	$T style elements $S {elemBorderTitle elemTxtTitle}
	$T style layout $S elemTxtTitle -expand news
	$T style layout $S elemBorderTitle -detach yes -indent no -iexpand xy

	set S [$T style create styItem]
	$T style elements $S {eRectTop.e elemRectSel elemTxtItem elemTxtName}
	$T style layout $S eRectTop.e -detach yes -indent no -iexpand xy
	$T style layout $S elemTxtItem -expand ns
	$T style layout $S elemTxtName -expand ns -padx {20}
	$T style layout $S elemRectSel -detach yes -indent no -iexpand xy

	set S [$T style create styID]
	$T style elements $S {eRectTop.we elemRectSel elemTxtItem}
	$T style layout $S eRectTop.we -detach yes -indent yes -iexpand xy
	$T style layout $S elemTxtItem -padx 6 -expand ns
	$T style layout $S elemRectSel -detach yes -indent no -iexpand xy

	set S [$T style create styParent]
	$T style elements $S {eRectTop.w elemRectSel elemTxtItem}
	$T style layout $S eRectTop.w -detach yes -indent yes -iexpand xy
	$T style layout $S elemTxtItem -padx 6 -expand ns
	$T style layout $S elemRectSel -detach yes -indent no -iexpand xy

	set S [$T style create styCitizen]
	$T style elements $S {eRectBottom elemWindow}
	$T style layout $S eRectBottom -detach yes -indent no -iexpand xy
	$T style layout $S elemWindow -pady {0 1}

	#
	# Create 10000 items. Each of these items will hold 10 child items.
	#

	set index 1
	foreach I [$T item create -count 10000 -parent root -button yes -open no \
		-height 20] {
		set ::BigList(titleIndex,$I) $index
		incr index 10
	}

	# This binding will add child items to an item just before it is expanded.
	$T notify bind $T <Expand-before> {
		BigListExpandBefore %T %I
	}

	# This binding will assign styles to items when they are displayed and
	# clear the styles when they are no longer displayed.
	$T notify bind $T <ItemVisibility> {
		BigListItemVisibility %T %v %h
	}

	set ::BigList(freeWindows) {}
	set ::BigList(nextWindowId) 0

	# Create a new window just to get the requested size. This will be the
	# value of the item -height option for some items.
	set w [BigListNewWindow $T root]
	update idletasks
	set height [winfo reqheight $w]
	incr height
	set ::BigList(windowHeight) $height

	bind DemoBigList <Double-ButtonPress-1> {
		if {[lindex [%W identify %x %y] 0] eq "header"} {
			TreeCtrl::DoubleButton1 %W %x %y
		} else {
			BigListButton1 %W %x %y
		}
		break
	}
	bind DemoBigList <ButtonPress-1> {
		BigListButton1 %W %x %y
		break
	}

	bindtags $T [list $T DemoBigList TreeCtrl [winfo toplevel $T] all]

	return
}

proc BigListExpandBefore {T I} {

	global BigList

	set parent [$T item parent $I]
	if {[$T item numchildren $I]} return

	# Title
	if {[$T depth $I] == 1} {
		set index $BigList(titleIndex,$I)
		set threats {Severe High Elevated Guarded Low}
		set names1 {Bill John Jack Bob Tim Sam Mary Susan Lilian Jeff Gary
			Neil Margaret}
		set names2 {Smith Hobbs Baker Furst Newel Gates Marshal McNoodle
			Marley}

		# Add 10 child items to this item. Each item represents 1 citizen.
		# The styles will be assigned in BigListItemVisibility.
		foreach I [$T item create -count 10 -parent $I -open no -button yes \
				-height 20] {
			set name1 [lindex $names1 [expr {int(rand() * [llength $names1])}]]
			set name2 [lindex $names2 [expr {int(rand() * [llength $names2])}]]
			set BigList(itemIndex,$I) $index
			set BigList(name,$I) "$name1 $name2"
			set BigList(threat,$I) [lindex $threats [expr {int(rand() * 5)}]]
			incr index
		}
		return
	}

	# Citizen
	if {[$T depth $I] == 2} {

		# Add 1 child item to this item.
		# The styles will be assigned in BigListItemVisibility.
		$T item create -parent $I -height $BigList(windowHeight)
	}

	return
}

proc BigListItemVisibility {T visible hidden} {

	global BigList

	# Assign styles and configure elements in each item that is now
	# visible on screen.
	foreach I $visible {
		set parent [$T item parent $I]

		# Title
		if {[$T depth $I] == 1} {
			set first $BigList(titleIndex,$I)
			set last [expr {$first + 10 - 1}]
			set first [format %06d $first]
			set last [format %06d $last]
			$T item span $I colItem 3
			$T item style set $I colItem styTitle
			$T item element configure $I \
				colItem elemTxtTitle -text "Citizens $first-$last"
			continue
		}

		# Citizen
		if {[$T depth $I] == 2} {
			set index $BigList(itemIndex,$I)
			$T item style set $I colItem styItem  colID styID colParent styParent
			$T item element configure $I \
				colItem elemTxtItem -text "Citizen $index" + elemTxtName -textvariable ::BigList(name,$I) , \
				colParent elemTxtItem -text $parent , \
				colID elemTxtItem -text $I
			continue
		}

		# Citizen info
		if {[$T depth $I] == 3} {
			set w [BigListNewWindow $T $parent]
			$T item style set $I colItem styCitizen
			$T item span $I colItem 3
			$T item element configure $I colItem \
				elemWindow -window $w
		}
	}

	# Clear the styles of each item that is no longer visible on screen.
	foreach I $hidden {
		set parent [$T item parent $I]

		# Citizen info
		if {[$T depth $I] == 3} {
			# Add this window to the list of unused windows
			set w [$T item element cget $I colItem elemWindow -window]
			BigListFreeWindow $T $w
		}
		$T item style set $I colItem "" colParent "" colID ""
	}
	return
}

proc BigListNewWindow {T I} {
	global BigList

	# Check the list of unused windows
	if {[llength $BigList(freeWindows)]} {
		set w [lindex $BigList(freeWindows) 0]
		set BigList(freeWindows) [lrange $BigList(freeWindows) 1 end]
puts "reuse window $w"

	# No unused windows exist. Create a new one.
	} else {
		set id [incr BigList(nextWindowId)]
		set w [frame $T.frame$id -background $BigList(bg)]

		# Name: label + entry
		label $w.label1 -text "Name:" -anchor w -background $BigList(bg)
		entry $w.entry1 -width 24

		# Threat Level: label + menubutton
		label $w.label2 -text "Threat Level:" -anchor w -background $BigList(bg)
		menubutton $w.mb2 -indicatoron yes -menu $w.mb2.m \
			-width [string length Elevated] -relief raised
		menu $w.mb2.m -tearoff no
		foreach label {Severe High Elevated Guarded Low} {
			$w.mb2.m add radiobutton -label $label \
				-value $label \
				-command [list $w.mb2 configure -text $label]
		}

		button $w.b3 -text "Anal Probe Wizard..." -command [list tk_messageBox \
			-parent . -message "After abducting and probing these people for\
			50 years,\nthe only thing we've learned for certain is that\none in\
			ten just doesn't seem to mind." -title "Anal Probe 2.0"]

		grid $w.label1 -row 0 -column 0 -sticky w -padx {0 8}
		grid $w.entry1 -row 0 -column 1 -sticky w -pady 4
		grid $w.label2 -row 1 -column 0 -sticky w -padx {0 8}
		grid $w.mb2 -row 1 -column 1 -sticky w -pady 4
		grid $w.b3 -row 3 -column 0 -columnspan 2 -sticky we -pady {0 4}
puts "create window $w"
	}

	# Tie the widgets to the global variables for this citizen
	$w.entry1 configure -textvariable BigList(name,$I)
	$w.mb2 configure -textvariable BigList(threat,$I)
	foreach label {Severe High Elevated Guarded Low} {
		$w.mb2.m entryconfigure $label -variable BigList(threat,$I)
	}
	return $w
}

proc BigListFreeWindow {T w} {
	global BigList

	# Add the window to our list of free windows. DemoClear will actually
	# delete the window when the demo changes.
	lappend BigList(freeWindows) $w
puts "free window $w"
	return
}

proc BigListButton1 {w x y} {
	variable TreeCtrl::Priv
	focus $w
	set id [$w identify $x $y]
	set Priv(buttonMode) ""
	if {[lindex $id 0] eq "header"} {
		TreeCtrl::ButtonPress1 $w $x $y
	} elseif {[lindex $id 0] eq "item"} {
		set item [lindex $id 1]
		# click a button
		if {[llength $id] != 6} {
			TreeCtrl::ButtonPress1 $w $x $y
			return
		}
		if {[$w depth $item] < 3} {
			$w toggle $item
		}
	}
	return
}
