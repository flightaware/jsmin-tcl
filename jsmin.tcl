#!/usr/bin/tclsh
namespace eval jsmin {
	variable prev ""
	variable cur ""
	variable next ""
	variable lookAhead ""
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
		variable lookAhead
		
		if {[eof stdin]} {
			return 0
		}

		set prev $cur
		set cur $next
		if {$lookAhead != ""} {
			set next $lookAhead
			set lookAhead ""
		} else {
			set next [read stdin 1]
		}	

		if {$next == "\r"} {
			set next "\n"
		}

		return 1
	}

	#
	# Get the next character from stdin without affecting subsequent calls
	# to get_stdin - prev, cur, and next remain unaffected.
	# NOTE: Cannot be called consecutively.
	#
	proc peek {} {
		variable lookAhead
		set lookAhead [read stdin 1]
		return $lookAhead
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

		# isIgnoring is used to signal if we're inside of a comment, regex,
		# or quoted string. It can take on the values:
		#  blockComment, lineComment, regex, singleQuote, or doubleQuote.
		set isIgnoring ""

		set pendingNewline 0
		set pendingNewlinePrev ""
		
		# A common occurrence inside this while loop is to manually
		# set cur and/or next. This has the effect of skipping a
		# character as the next call of get_stdin will shift cur
		# and next back to prev and cur.
		while {[get_stdin]} {
			if {$cur == "/" && $next == "/" && $isIgnoring == ""} {
				set isIgnoring "lineComment"
			} elseif {$isIgnoring == "lineComment"} {
				if {$next == "\n"} {
					if {$pendingNewline} {
						set cur $pendingNewlinePrev
					}
					set isIgnoring ""
				}

			} elseif {$cur == "/" && $next == "*" && $isIgnoring == ""} {
				set isIgnoring "blockComment"
			} elseif {$isIgnoring == "blockComment"} {
				if {$cur == "*" && $next == "/"} {
					if {$pendingNewline} {
						set next "\n"
						set cur $pendingNewlinePrev
						set pendingNewline 0
					} else {
						get_stdin
					}
					set isIgnoring ""
				}
			} elseif {$cur == "\"" && $isIgnoring == ""} {
				set isIgnoring "doubleQuote"
				puts -nonewline $cur
			} elseif {$isIgnoring == "doubleQuote"} {
				puts -nonewline $cur
				if {$cur == "\"" && $prev != "\\"} {
					set isIgnoring ""
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
				if {$next == " " || $next == "\t" || $next == "\n"} {
					# Discard spaces
					set next $cur
					set cur $prev
				} elseif {$next == "/"} {
					# We need to get rid of the comment and then continue
					# checking if this newline is necessary.
					set nextnext [peek]
					if {$nextnext == "*"} {
						set pendingNewline 1
						set pendingNewlinePrev $prev
						set isIgnoring "blockComment"
					} elseif {$nextnext == "/"} {
						set pendingNewline 1
						set pendingNewlinePrev $prev
						set isIgnoring "lineComment"
					}
				} elseif {$next ni $beforeNewlineChars && \
							  $prev ni $afterNewlineChars && \
							  $prev ni {"\n" "," ";"} && \
							  ($next in $afterNewlineChars || \
								   $prev in $beforeNewlineChars)} {
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
