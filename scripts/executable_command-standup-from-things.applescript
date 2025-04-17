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
	set todayTasks to {}

	-- Get tasks directly in the "Today" list
	set allTodayTasks to to dos of list "Today"
	repeat with aTask in allTodayTasks
		set taskTags to tag names of aTask
		if taskTags contains "Standup" then
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
					if taskTags contains "Standup" then
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

    set currentDate to current date
    if hours of currentDate < 12 then
        set currentDate to currentDate - (1 * days)
    end if

	set finalOutput to "## " & my formatDate(currentDate) & linefeed & linefeed

	set todayTasks to my sortTasksByName(todayTasks)

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

			set inCodeBlock to false
			repeat with l in noteLines

			    set l to my normaliseLineEndings(l)
				if l starts with "```" then
					set inCodeBlock to not inCodeBlock
					set formattedNotes to formattedNotes & l & linefeed
				else
					set formattedLine to my surroundURLsWithBrackets(l)
					if not inCodeBlock then
						set formattedLine to "> " & formattedLine
					end if
					set formattedNotes to formattedNotes & formattedLine & linefeed
				end if
			end repeat
		end if

		if status of t is completed then
			set taskIcon to "✅"
		else if status of t is canceled then
			set taskIcon to "⏸️"
		else
			set taskIcon to "🏃‍"
		end if

		if project of t is not missing value then
			set projectName to name of project of t & ": "
		else
		  set projectName to ""
		end if

		set finalOutput to finalOutput & "- " & taskIcon & " " & projectName & urlInTitle & linefeed & formattedNotes
	end repeat
end tell

return finalOutput

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

on normaliseLineEndings(theText)
	set tempText to ""
	repeat with i from 1 to (count theText)
		set thisChar to character i of theText
		if thisChar is " " or thisChar is " " then -- U+2028 or U+2029
			set tempText to tempText & return
		else
			set tempText to tempText & thisChar
		end if
	end repeat
	return tempText
end normaliseLineEndings

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

on sortTasksByName(taskList)
	set nameAndRefList to {}
	repeat with aTask in taskList
		set taskName to name of aTask
		set end of nameAndRefList to {taskName, aTask}
	end repeat

	set sortedList to my quickSort(nameAndRefList)

	set sortedTasks to {}
	repeat with i in sortedList
		set end of sortedTasks to i's second item
	end repeat

	return sortedTasks
end sortTasksByName

on quickSort(theList)
	if length of theList ≤ 1 then
		return theList
	end if

	set pivot to first item of theList
	set lessList to {}
	set greaterList to {}

	repeat with i from 2 to length of theList
		set currentItem to item i of theList
		if (first item of currentItem) comes before (first item of pivot) then
			set end of lessList to currentItem
		else
			set end of greaterList to currentItem
		end if
	end repeat

	return (my quickSort(lessList)) & {pivot} & (my quickSort(greaterList))
end quickSort
