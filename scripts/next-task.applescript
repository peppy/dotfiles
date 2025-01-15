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
                if project of todo is not missing value
                    set output to name of project of todo & ": " & name of todo
                else
                    set output to name of todo
                end if

				exit repeat
			end if
		end if
	end repeat

	return output
end tell
