#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Output standup from Things today tasks
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author ppy
# @raycast.authorURL https://raycast.com/ppy

tell application "Things3"
	set todayTasks to to dos of list "Today" whose (tag names of it contains "Work Task")

	set todayTasks to {}

	-- Get tasks directly in the "Today" list
	set allTodayTasks to to dos of list "Today"
	repeat with aTask in allTodayTasks
		set taskTags to tag names of aTask
		if taskTags contains "Work Task" then
			set end of todayTasks to aTask
		end if
	end repeat

	-- Check each project for tasks dated today
	set today to current date
	set allProjects to projects
	repeat with aProject in allProjects
		set projectTasks to to dos of aProject
		repeat with aTask in projectTasks
			if (status of aTask is open) then
				set dueDate to activation date of aTask
				if dueDate is not missing value and dueDate = today then
					set taskTags to tag names of aTask
					if taskTags contains "Work Task" then
						set end of todayTasks to aTask
					end if
				end if
			end if
		end repeat
	end repeat
	set firstCompletedTask to missing value

	repeat with task in todayTasks
		if status of task is completed then
			set firstCompletedTask to task
			exit repeat
		end if
	end repeat

	if firstCompletedTask is not missing value then
		set taskDate to completion date of firstCompletedTask
	else
		set taskDate to current date
	end if

	set completedTasks to "## " & my formatDate(taskDate) & linefeed & linefeed

	repeat with t in todayTasks
		set taskName to name of t
		set taskNotes to notes of t
		set formattedNotes to ""
		set urlInTitle to "**" & taskName & "**"

		if taskNotes is not "" then
			set noteLines to paragraphs of taskNotes
			set firstLine to item 1 of noteLines

			set linkURL to ""

			if firstLine contains "://" then
				if firstLine starts with "[" and firstLine contains "](" and firstLine ends with ")" then
					set startBracket to offset of "[" in firstLine
					set endBracket to offset of "]" in firstLine
					set startParen to offset of "(" in firstLine
					set endParen to offset of ")" in firstLine
					set linkURL to text (startParen + 1) thru (endParen - 1) of firstLine
				else
					set linkURL to firstLine
				end if
			end if

			if linkURL is not "" then
				if linkURL contains "https" then
					if taskName contains ":" then
						set colonPos to offset of ":" in taskName
						set titlePart to text (colonPos + 1) thru -1 of taskName

						if titlePart starts with " " then
							set titlePart to text 2 thru -1 of titlePart
						end if

						set urlInTitle to text 1 thru colonPos of taskName & " **" & titlePart & "** ([view](<" & linkURL & ">))"
					else
						set urlInTitle to "**" & taskName & "** ([view](<" & linkURL & ">))"
					end if
				end if

				if (count of noteLines) > 1 then
					set noteLines to items 2 thru -1 of noteLines
				else
					set noteLines to {}
				end if
			end if

			set noteLines to my trimEmptyLines(noteLines)
			repeat with l in noteLines
				set formattedLine to my surroundURLsWithBrackets(l)
				set formattedNotes to formattedNotes & "> " & formattedLine & linefeed
			end repeat
		end if

		if status of t is completed then
			set taskIcon to "✅"
		else if status of t is canceled then
			set taskIcon to "⏸️"
		else
			set taskIcon to "🏃‍"
		end if

		set completedTasks to completedTasks & "- " & taskIcon & " " & urlInTitle & linefeed & formattedNotes
	end repeat
end tell

return completedTasks

on formatDate(theDate)
	set {year:y, month:m, day:d} to theDate
	return (y as string) & "-" & my padNumber(m as integer) & "-" & my padNumber(d as integer)
end formatDate

on padNumber(n)
	if n is less than 10 then
		return "0" & n
	else
		return n as string
	end if
end padNumber

on trimEmptyLines(noteLines)
	-- Remove empty lines from the beginning
	repeat while (noteLines is not {} and first item of noteLines is "")
		if (count of noteLines) > 1 then
			set noteLines to items 2 thru -1 of noteLines
		else
			set noteLines to {}
			exit repeat
		end if
	end repeat

	-- Remove empty lines from the end
	repeat while (noteLines is not {} and last item of noteLines is "")
		if (count of noteLines) > 1 then
			set noteLines to items 1 thru -2 of noteLines
		else
			set noteLines to {}
			exit repeat
		end if
	end repeat

	return noteLines
end trimEmptyLines

on surroundURLsWithBrackets(inputText)
	set urlPattern to "([a-z]*)?://[%~a-zA-Z0-9./?=_-]+"
	set modifiedText to do shell script "echo " & quoted form of inputText & " | sed -E 's|(" & urlPattern & ")|<\\1>|g'"
	return modifiedText
end surroundURLsWithBrackets
