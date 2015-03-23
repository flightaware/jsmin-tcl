#!/usr/bin/tclsh
namespace eval jsmin {
	set version "1.0"

	variable fp
	variable prev ""
	variable cur ""
	variable next ""
	variable lookAhead ""
	variable plusMinus {"+" "-"}
	variable noSpaceChars {"\{" "\}" "(" ")" "[" "]" ";" "," "=" ":" ">" \
							   "<" "*" "%" "!" "&" "|" "?" "/" "\"" "'"}
	variable afterNewlineChars {"\{" "[" "("}
	variable beforeNewlineChars {"\}" "]" ")"}
	# TODO Figure out all possiblilities for regexes
	variable beforeRegexChars {"=" "+" "(" "&" "|" ":" "\n"}
	# TODO These are not being used for anything
	variable leaveNewlineChars {"\\" "\$" "_" "+" "-"}

	#
	# Get the next character from the input channel. If the
	# character is a carrage return, '\r', then it replaces it
	# with a line feed, '\n'.
	#
	# Namespace variables prev, cur, and next are used to keep
	# track of the surrounding characters.
	#
	proc get_char {} {
		variable fp
		variable prev
		variable cur
		variable next
		variable lookAhead
		
		if {[eof $fp]} {
			return 0
		}

		set prev $cur
		set cur $next
		if {$lookAhead != ""} {
			set next $lookAhead
			set lookAhead ""
		} else {
			set next [read $fp 1]
		}	

		if {$next == "\r"} {
			set next "\n"
		}

		return 1
	}

	#
	# Get the next character from the input channel without
	# affecting subsequent calls to get_char - prev, cur,
	# and next remain unaffected.
	# NOTE: Cannot be called consecutively.
	#
	proc peek {} {
		variable fp
		variable lookAhead
		set lookAhead [read $fp 1]
		return $lookAhead
	}
	
	#
	# Determines by looking at the next character if the
	# current space character can be discarded.
	#
	proc can_discard_space {} {
		variable cur
		variable next
		variable prev
		variable noSpaceChars
		variable plusMinus
		
		if {$cur == " "} {
			if {$next in $plusMinus && $prev in $plusMinus} {
				# We cannot remove spaces in expressions like "c=a- ++b"
				return 0
			} elseif {$next == " " || $next in $noSpaceChars || $prev in $noSpaceChars || \
						  $next in $plusMinus || $prev in $plusMinus} {
				return 1
			}
		}
		
		return 0
	}

	#
	# Remove unnecessary spaces and new lines.
	# Removes comments and ignores quotes.
	#
	proc minify {inputFp ofp} {
		variable fp
		variable prev
		variable cur
		variable next
		variable plusMinus
		variable noSpaceChars
		variable afterNewlineChars
		variable beforeNewlineChars
		variable leaveNewlineChars
		variable beforeRegexChars
		
		# Open a channel for the file or stdin.
		set fp $inputFp

		# isIgnoring is used to signal if we're inside of a comment, regex,
		# or quoted string. It can take on the values:
		#  blockComment, lineComment, regex, singleQuote, or doubleQuote.
		set isIgnoring ""

		set pendingNewline 0
		set pendingNewlinePrev ""
		set unescapedBackslash 0
		
		# A common occurrence inside this while loop is to manually
		# set cur and/or next. This has the effect of skipping a
		# character as the next call of get_char will shift cur
		# and next back to prev and cur.
		while {[get_char]} {
			if {$cur == "/" && $next == "/" && $isIgnoring == ""} {
				set isIgnoring "lineComment"
				set lineCommentPrev $prev
			} elseif {$isIgnoring == "lineComment"} {
				if {$next == "\n"} {
					if {$pendingNewline} {
						set cur $pendingNewlinePrev
						set pendingNewline 0
					} else {
						set cur $lineCommentPrev
					}
					set isIgnoring ""
				}

			} elseif {$cur == "/" && $next == "*" && $isIgnoring == ""} {
				set isIgnoring "blockComment"
				set blockCommentPrev $prev
			} elseif {$isIgnoring == "blockComment"} {
				if {$cur == "*" && $next == "/"} {
					if {$pendingNewline} {
						set next "\n"
						set cur $pendingNewlinePrev
						set pendingNewline 0
					} else {
						get_char
						set cur $blockCommentPrev
					}
					set isIgnoring ""
				}

			} elseif {$cur == "'" && $isIgnoring == ""} {
				set isIgnoring "singleQuote"
				set unescapedBackslash 0
				puts -nonewline $ofp $cur
			} elseif {$isIgnoring == "singleQuote"} {
				puts -nonewline $ofp $cur
				if {$cur == "\\"} {
					if {$unescapedBackslash} {
						set unescapedBackslash 0
					} else {
						set unescapedBackslash 1
					}	
				} elseif {$cur == "'"} {
					if {$unescapedBackslash} {
						# Just an escaped quote
						set unescapedBackslash 0
					} else {
						# Quoted string has ended
						set unescapedBackslash 0
						set isIgnoring ""
					}
				} else {
					# Some other escaped character. ie. "\n"
					set unescapedBackslash 0
				}

			} elseif {$cur == "\"" && $isIgnoring == ""} {
				set isIgnoring "doubleQuote"
				set unescapedBackslash 0
				puts -nonewline $ofp $cur
			} elseif {$isIgnoring == "doubleQuote"} {
				puts -nonewline $ofp $cur
				if {$cur == "\\"} {
					if {$unescapedBackslash} {
						set unescapedBackslash 0
					} else {
						set unescapedBackslash 1
					}	
				} elseif {$cur == "\""} {
					if {$unescapedBackslash} {
						# Just an escaped quote
						set unescapedBackslash 0
					} else {
						# Quoted string has ended
						set unescapedBackslash 0
						set isIgnoring ""
					}
				} else {
					# Some other escaped character. ie. "\n"
					set unescapedBackslash 0
				}
				
			} elseif {$cur == "/" && $next != "/" && \
						  $prev in $beforeRegexChars && $isIgnoring == ""} {
				set isIgnoring "regex"
				puts -nonewline $ofp $cur
			} elseif {$isIgnoring == "regex"} {
				puts -nonewline $ofp $cur
				if {$cur == "/" && $prev != "\\"} {
					set isIgnoring ""
				}

			} elseif {$cur == " "} {
				if {[can_discard_space]} {
					# Discard space but keep $prev as prev in case
					# we need to check it later.
					set cur $prev
				} else {
					puts -nonewline $ofp $cur
				}

			} elseif {$cur in $noSpaceChars} {
				if {$next == " "} {
					# Discard space but don't puts cur yet.
					set next $cur
					set cur $prev
				} else {
					puts -nonewline $ofp $cur
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
							  $prev ni {"\n" "," ";" "&" "|" ""} && \
							  $next ni {"."  "?" ":" "&" "|"} && \
							  ($next in $afterNewlineChars || \
								   $prev in $beforeNewlineChars || \
								   [string is integer $prev])} {
					if {![eof $fp]} {
						# Don't puts a newline at the end of the file
						puts -nonewline $ofp $cur
					}
				} elseif { ([string is alpha $prev] || $prev in $plusMinus) && \
						   ([string is alpha $next] || $next in $plusMinus) } {
					puts -nonewline $ofp $cur
				}

			} elseif {$cur == "\t"} {
				# TODO This should behave similar to spaces.
				continue
			} else {
				puts -nonewline $ofp $cur
			}
		}

	}
}

package provide jsmin $jsmin::version
