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
							   "<" "*" "%" "!" "&" "|" "?" "/" "\"" "'" "^"}
	variable afterNewlineChars {"\{" "[" "("}
	variable beforeNewlineChars {"\}" "]" ")" "'" "\""}
	variable beforeRegexChars {"=" "+" "(" "&" "|" ":" "\n" "!"}

	#
	# Get the next character from the input channel. If the
	# character is a carrage return, '\r', then it replaces it
	# with a line feed, '\n'. If the character is a tab, replace
	# it with a space.
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
		if {$lookAhead ne ""} {
			set next $lookAhead
			set lookAhead ""
		} else {
			set next [read $fp 1]
		}

		if {$next eq "\r"} {
			set next "\n"
		} elseif {$next eq "\t"} {
			set next " "
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
	# Determines by looking at the next and previous
	# character if the current space character can be
	# discarded.
	#
	proc can_discard_space {} {
		variable cur
		variable next
		variable prev
		variable noSpaceChars
		variable plusMinus

		if {$cur eq " "} {
			if {$next in $plusMinus && $prev in $plusMinus} {
				# We cannot remove spaces in expressions like "c=a- ++b"
				return 0
			} elseif {$next eq " " || $next in $noSpaceChars || $prev in $noSpaceChars || \
						  $next in $plusMinus || $prev in $plusMinus} {
				return 1
			}
		}

		return 0
	}

	#
	# Removes unnecessary spaces, tabs, and new lines.
	# Removes comments, ignores quotes and regular
	# expressions.
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
		variable beforeRegexChars

		# Set the input channel namespace variable since it's used
		# by other procs in this namespace.
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
			if {$cur eq "/" && $next eq "/" && $isIgnoring eq ""} {
				set isIgnoring "lineComment"
				set lineCommentPrev $prev
			} elseif {$isIgnoring eq "lineComment"} {
				if {$next eq "\n"} {
					# pendingNewline is set whenever a newline is followed by
					# a comment. This is needed because we don't know if the
					# newline is necessary until we remove the comment.
					if {$pendingNewline} {
						set cur $pendingNewlinePrev
						set pendingNewline 0
					} else {
						set cur $lineCommentPrev
					}
					set isIgnoring ""
				}

			} elseif {$cur eq "/" && $next eq "*" && $isIgnoring eq ""} {
				set isIgnoring "blockComment"
				set blockCommentPrev $prev
			} elseif {$isIgnoring eq "blockComment"} {
				if {$cur eq "*" && $next eq "/"} {
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

			} elseif {$cur eq "'" && $isIgnoring eq ""} {
				set isIgnoring "singleQuote"
				set unescapedBackslash 0
				puts -nonewline $ofp $cur
			} elseif {$isIgnoring eq "singleQuote"} {
				puts -nonewline $ofp $cur

				# Check if we should clear isIgnoring
				if {$cur eq "\\"} {
					if {$unescapedBackslash} {
						set unescapedBackslash 0
					} else {
						set unescapedBackslash 1
					}
				} elseif {$cur eq "'"} {
					# unescapedBackslash is used to tell if
					# the next quote is escaped or not. It
					# is used for double quotes as well.
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

			} elseif {$cur eq "\"" && $isIgnoring eq ""} {
				set isIgnoring "doubleQuote"
				set unescapedBackslash 0
				puts -nonewline $ofp $cur
			} elseif {$isIgnoring eq "doubleQuote"} {
				puts -nonewline $ofp $cur
				if {$cur eq "\\"} {
					if {$unescapedBackslash} {
						set unescapedBackslash 0
					} else {
						set unescapedBackslash 1
					}
				} elseif {$cur eq "\""} {
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

			} elseif {$cur eq "/" && $next ne "/" && \
						  $prev in $beforeRegexChars && $isIgnoring eq ""} {
				# Inside a regex
				set isIgnoring "regex"
				set unescapedBackslash 0
				puts -nonewline $ofp $cur
			} elseif {$isIgnoring eq "regex"} {
				puts -nonewline $ofp $cur
				if {$cur eq "\\"} {
					if {$unescapedBackslash} {
						set unescapedBackslash 0
					} else {
						set unescapedBackslash 1
					}
				} elseif {$cur eq "/"} {
					if {$unescapedBackslash} {
						# Just an escaped slash
						set unescapedBackslash 0
					} else {
						# Just exited a regex
						set unescapedBackslash 0
						set isIgnoring ""
					}
				} else {
					# Maybe some other escaped character. ie. "\n"
					set unescapedBackslash 0
				}

			} elseif {$cur eq " "} {
				if {[can_discard_space]} {
					# Discard space but keep $prev as prev in case
					# we need to check it later.
					set cur $prev
				} else {
					puts -nonewline $ofp $cur
				}

			} elseif {$cur in $noSpaceChars} {
				if {$next eq " "} {
					# Discard space but don't puts $cur yet
					# in case there are more spaces.
					set next $cur
					set cur $prev
				} else {
					puts -nonewline $ofp $cur
				}

			} elseif {$cur eq "\n"} {
				if {$next eq " " || $next eq "\n"} {
					# Discard spaces
					set next $cur
					set cur $prev
				} elseif {$next eq "/"} {
					# Check if there's a comment ahead. If so,
					# we need to remove it and then continue
					# checking if this newline is necessary.
					set nextnext [peek]
					if {$nextnext eq "*"} {
						set pendingNewline 1
						set pendingNewlinePrev $prev
						set isIgnoring "blockComment"
					} elseif {$nextnext eq "/"} {
						set pendingNewline 1
						set pendingNewlinePrev $prev
						set isIgnoring "lineComment"
					}
				} elseif {$next ni $beforeNewlineChars && \
							  $prev ni $afterNewlineChars && \
							  $prev ni {"\n" "?" ":" "=" "," ";" "&" "|" ""} && \
							  $next ni {"."  "?" ":" "=" "&" "|"} && \
							  ($next in $afterNewlineChars || \
								   $prev in $beforeNewlineChars || \
								   [string is integer $prev])} {
					# Because semicolons are optional and newlines are sometimes
					# used for automatic semicolon insertion, we need to check
					# the above, complicated rules.

					if {![eof $fp]} {
						# Don't puts a newline at the end of the file
						puts -nonewline $ofp $cur
					}
				} elseif { ([string is alpha $prev] || $prev in $plusMinus || \
								$prev in {"_" "$"}) && \
						   ([string is alpha $next] || $next in $plusMinus || \
								$next in {"_" "$"}) } {
					# We have to make sure we don't remove semicolon-less
					# newlines preceding ++ or --.
					puts -nonewline $ofp $cur
				}

			} else {
				puts -nonewline $ofp $cur
			}
		}

	}
}

package provide jsmin $jsmin::version
