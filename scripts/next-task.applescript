tell application "Things3"
	set todayList to to dos of list "Today"

	set output to ""
	repeat with todo in todayList
		if status of todo is open then
			set todoTags to ""
			try
				set todoTags to name of every tag of todo
			end try

			if todoTags contains "Streamable" then
				set output to name of todo
				exit repeat
			end if
		end if
	end repeat

	return output
end tell
