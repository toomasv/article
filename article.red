Red [
	Title: "Red's Interactive Article"
	Author: "Toomas Vooglaid"
	Acknowledgement: {Code was initially adapted for Red from Carl Sassenrath's 
	easy-VID (http://www.rebol.com/view/reb/easyvid.r)}
	Needs: 'View
]
context [
	Redate: 13-May-2019

	page-x: 600
	page-y: 700
	list-x: 160
	ofs-y: 60
	page-size: as-pair page-x page-y ;600x700;500x480
	page-ofs: as-pair list-x + 30 ofs-y;190x60
	rtbszx: page-x - 40 ;560
	text-listsz: as-pair list-x page-y ;160x700
	links: clear []
	
	detab: function [
		{Converts tabs in a string to spaces. (tab size 4)}
		str [string!] 
		/size sz [integer!]
	][
		sz: max 1 any [sz 2]
		buf: append/dup clear "    " #" " sz
		replace/all str #"^-" copy buf
	]

	content: read system/script/args ;%snakeline.txt

	rt: make face! [type: 'rich-text size: page-size - 20 line-spacing: 15] ;480x460
	text-size: func [text][
		rt/text: text
		size-text rt
	]

	;rt-ops: [#"*" <b> #"/" <i> #"_" <u>] 
	inside-b?: inside-i?: inside-u?: inside-c?: no 
	special: charset "*_/\{[`"
	digit: charset "0123456789"
	int: [some digit]
	alpha: charset [#"a" - #"z" #"A" - #"Z"]
	str: [#"^"" some [alpha | space] #"^""]
	font-rule: [#"[" copy fnt to #"]" skip]
	rt-rule: [(inside?: no)
		collect some [
			#"\" keep copy skip
		|	[
				#"*" keep (either inside-b?: not inside-b? [<b>][</b>]) 
			|	#"/" keep (either inside-i?: not inside-i? [<i>][</i>]) 
			|	#"_" keep (either inside-u?: not inside-u? [<u>][</u>])
			;|	#"[" copy tx to #"]" skip #"(" copy url to #")" skip 
			;	keep ('u/blue) keep (append copy [] tx) (append links load url)
			|	#"`" [if (inside-c?: not inside-c?) keep (<b>) keep (<font>) keep ("Consolas") 
				| keep (</font>) keep (</b>)]
			|	"{#}" keep (</bg>)
			|	"{#" copy bg to "#}" keep (<bg>) keep (to-word bg) 2 skip 
			|	"[]" keep (</font>)
			|	font-rule keep (<font>) keep (either 1 = length? fnt: load/all fnt [first fnt][fnt]) 
			|	#"{" copy clr to #"}" keep (to-word clr) skip
			] 
		|	newline keep (" ")
		|	keep copy _ to [special | newline | end]
		] 
	]
	
	code: text: layo: xview: none
	sections: make block! 50
	layouts: make block! 50
	space: charset " ^-"
	chars: complement charset " ^-^/"

	rules: [title some parts]

	title: [text-line (title-line: text)]

	parts: [
		  newline
		| "===" section
		| "---" subsect
		| "!" note
		| example
		| paragraph
	]

	text-line: [copy text to newline newline]
	indented:  [some space thru newline]
	paragraph: [copy para some [chars thru newline] (emit-para para)]
	note: [copy para some [chars thru newline] (emit-note para)]
	example: [
		copy code some [indented | some newline indented]
		(emit-code code)
	]
	section: [
		text-line (
			append sections text
			append/only layouts layo: copy []
			blk: copy [<font> 16 </font>]
			insert at blk 3 text
			rtb: rtd-layout blk 
			rtb/size/x: rtbszx
			repend layo ['text 10x5 rtb]
			sz: size-text rtb
			pos-y: 5 + sz/y + 10
		) newline
	]
	subsect: [text-line (
		blk: copy [<font> 12 </font>] 
		insert at blk 3 text
		rtb: rtd-layout blk
		rtb/size/x: rtbszx
		repend layo ['text as-pair 10 pos-y rtb]
		sz: size-text rtb
		pos-y: pos-y + sz/y + 10
	)]

	;emit: func ['style data] [repend layo [style data]]

	emit-para: func [data][ 
		remove back tail data
		blk: parse data rt-rule
		if " " = first blk [remove blk]
		rtb: rtd-layout blk
		;unless empty? links [
		;	rtb/extra: copy links
		;	clear links
		;]
		rtb/size/x: rtbszx
		repend layo ['text as-pair 10 pos-y rtb]
		sz: size-text rtb
		pos-y: pos-y + sz/y + 10
	]

	emit-code: func [code] [
		remove back tail code
		blk: reduce [<b> code </b>] 
		rtb: rtd-layout blk
		rtb/size/x: rtbszx + 20
		append rtb/data reduce [as-pair 1 length? rtb/text "Consolas"]
		sz: size-text rtb
		repend layo [
			'fill-pen beige;silver 
			'box pos: as-pair 10 pos-y as-pair rtbszx + 20 pos/y + sz/y + 14 
			'fill-pen black
		]
		repend layo ['text as-pair 15 pos-y + 7 rtb]
		pos-y: pos-y + sz/y + 27
	]

	emit-note: func [code] [
		remove back tail code
		blk: parse code rt-rule
		if " " = first blk [remove blk]
		append insert blk [b][/b]
		rtb: rtd-layout blk
		append rtb/data reduce [as-pair 1 length? rtb/text 150.0.0]
		rtb/size/x: rtbszx
		repend layo ['text as-pair 10 pos-y rtb]
		sz: size-text rtb
		pos-y: pos-y + sz/y + 10

	]

	show-example: func [code][
		if xview [xy: xview/offset - 3x26  unview/only xview]
		xcode: load/all code;face/text
		if not block? xcode [xcode: reduce [xcode]] 
		;either here: select xcode either find [layout compose] what: second xcode [what]['view][
		;	xcode: here
		;][
		;	unless find [title backdrop size] first xcode [insert xcode 'below]
		;]
		;attempt [xview: view/no-wait/options compose xcode [offset: xy]]
		do xcode
	]

	show-edit-box: func [code sz][
		if xview [xy: xview/offset - 8x31  unview/only xview]
		xcode: load/all code;face/text
		if not block? xcode [xcode: reduce [xcode]] 
		;either here: select xcode either find [layout compose] what:  second xcode [what]['view][
		;	xcode: here
		;][
		;	unless find [title backdrop size] first xcode [insert xcode 'below]
		;]
		;view-cmd: copy "view "
		;if find xcode paren! [append view-cmd "compose "]
		;xcode: head insert mold xcode view-cmd
		xview: view/no-wait/flags/options compose [
			title "Play with code"
			on-resizing [
				win: face
				foreach-face face [
					switch face/type [
						area [face/size: win/size - face/offset - 45 ]
						button [face/offset/y: win/size/y - face/size/y - 10]
					]
				]
			]
			below 
			ar: area focus (mold/only xcode) (sz) 
			across 
			button "Show" [do ar/text]
			button "Close" [unview]
		] 'resize [offset: xy]
	]
	draw-pages: does [
		parse detab/size content 3 rules
	]
	draw-pages
	show-page: func [i /local blk][
		i: max 1 min length? sections i
		if blk: pick layouts this-page: i [
			tl/selected: this-page
			tx: find/tail/last blk 'text
			f-box/offset/y: 0
			f-box/size/y: tx/1/y + tx/2/size/y
			f-box/draw: blk ;show f-box
		]
	]

	main: layout compose [
		title "Snakelines"
		on-key [
			switch event/key [
				up left [show-page this-page];[show-page this-page - 1]
				down right [show-page this-page];[show-page this-page + 1]
				home [show-page 1]
				end [show-page length? sections]
			] 
		]
		h4 title-line bold return
		tl: text-list text-listsz bold select 1 white gray data sections on-change [
			show-page face/selected
		]
		pan: panel white page-size [
			origin 0x0
			f-box: rich-text page-size white draw []
			on-down [
				parse face/draw [some [
					bx: 'box pair! pair! if (within? event/offset bx/2 sz: bx/3 - bx/2) (
						code: select first find bx object! 'text
						either event/ctrl? [show-edit-box code sz][show-example code]
					)
				|	skip
				]]
			]
			on-wheel [
				face/offset/y: min 0 
							   max pan/size/y - f-box/size/y
								   face/offset/y + (event/picked * 5)
			]
			at 0x0 page-border: box with [
				size: page-size 
				draw: compose [pen gray box 0x0 (page-size - 1)]
			]
		]
		pad -140x-30
		nav: panel [
			origin 0x0
			pad 0x5
			text with [text: form Redate]
			space 4x10 pad 0x-5
			button 20 "<" [show-page this-page - 1]
			button 20 ">" [show-page this-page + 1]
		]
		do [f-box/draw: compose [pen gray box 0x0 (f-box/size - 1)]]
	] 
	view/no-wait/flags/options main 'resize [
		actors: object [
			on-resize: func [face event][
				page-size: main/size - page-ofs;600x630;500x480
				rtbszx: page-size/x - 40;560
				tl/size/y: main/size/y - ofs-y
				pan/size: page-size
				f-box/size: page-size
				nav/offset/x: main/size/x - nav/size/x - 10
				page-border/size: page-size
				page-border/draw/5: page-size - 1
				clear sections 
				clear layouts
				draw-pages
				show-page tl/selected
			]
		]
	]
	show-page 1
	xy: main/offset + either system/view/screens/1/size/x > 900 [
		main/size * 1x0 + 8x0][300x300]
	do-events
]
