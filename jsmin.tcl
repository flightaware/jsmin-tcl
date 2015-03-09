#!/usr/bin/tclsh
namespace eval jsmin {
	variable prev ""
	variable cur ""
	variable next ""
	variable noSpaceChars {"\{" "\}" "(" ")" ";" "," "=" ":" ">" "<" "+" "*" "-" "%" "!" "&" "|" "?"}
	variable afterNewlineChars {"\\" "\$" "_" "\{" "[" "(" "+" "-"}
	variable beforeNewlineChars {"\\" "\$" "_" "\}" "]" ")" "+" "-"}

	#
	# Get the next character from stdin. If the character is a
	# carrage return, '\r', then it replaces it with a line feed,
	# '\n'.
	#
	# Namespace variables prev, cur, and next are used to keep
	# track of the surrounding characters.
	#
	proc get_stdin {} {
		variable prev
		variable cur
		variable next
		
		if {[eof stdin]} {
			return 0
		}

		set prev $cur
		set cur $next
		set next [read stdin 1]

		if {$next == "\r"} {
			set next "\n"
		}

		return 1
	}
	
	#
	# Determines by looking at the next character if the
	# current space character can be discarded.
	#
	proc can_discard_space {} {
		variable cur
		variable next
		variable noSpaceChars
		
		if {$cur == " "} {
			if {$next == " " || $next in $noSpaceChars} {
				return 1
			}
		}
		
		return 0
	}

	#
	# Remove unnecessary spaces and new lines.
	# Removes comments and ignores quotes.
	#
	proc minify {} {
		variable prev
		variable cur
		variable next
		variable noSpaceChars
		variable afterNewlineChars
		variable beforeNewlineChars
		# // Style comments.
		set inLineComment 0
		
		# /* Style comments.
		set inBlockComment 0

		set inRegex 0
		set inSingleQuote 0
		set inDoubleQuote 0
		
		# A common occurrence inside this while loop is to manually
		# set cur and/or next. This has the effect of skipping a
		# character as the next call of get_stdin will shift cur
		# and next back to prev and cur.
		while {[get_stdin]} {
			if {$cur == "/" && $next == "/" && !$inBlockComment} {
				set inLineComment 1
			} elseif {$inLineComment} {
				if {$next == "\n"} {
					set inLineComment 0
				}

			} elseif {$cur == "/" && $next == "*" && !$inLineComment} {
				set inBlockComment 1
			} elseif {$inBlockComment} {
				if {$cur == "*" && $next == "/"} {
					get_stdin
					set inBlockComment 0
				}

			} elseif {$cur == " "} {
				if {$prev == "\n"} {
					# Discard space but keep newline as prev to remove
					# any more spaces.
					set cur $prev
				} elseif {![can_discard_space]} {
					puts -nonewline $cur
				}

			} elseif {$cur in $noSpaceChars} {
				if {$next == " "} {
					# Discard space but don't puts cur yet.
					set next $cur
					set cur $prev
				} else {
					puts -nonewline $cur
				}

			} elseif {$cur == "\n"} {
				if {$next in $afterNewlineChars || $prev in $beforeNewlineChars} {
					puts -nonewline $cur
				}

			} elseif {$cur == "\t"} {
				# TODO This should behave similar to spaces.
				continue
			} else {
				puts -nonewline $cur
			}
		}
	}
}

jsmin::minify
