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

set taskOutput to ""

tell application "Things3"
	set todayTasks to {}

	set allTodayTasks to to dos of list "Today"
	repeat with aTask in allTodayTasks
		set taskTags to tag names of aTask
		if taskTags contains "Standup" then
			set end of todayTasks to aTask
		end if
	end repeat

	set currentDate to current date
	if hours of currentDate < 12 then
		set currentDate to currentDate - (1 * days)
	end if

	-- Build lookup table for area order
	set allAreas to areas
	set areaOrderMap to {}
	repeat with i from 1 to count of allAreas
		set areaName to my trimWhitespace(name of item i of allAreas)
		set end of areaOrderMap to {areaName, i}
	end repeat

	-- Build lookup table for projects with their area's order
	set allProjects to projects
	set projectOrderMap to {}
	repeat with i from 1 to count of allProjects
		set proj to item i of allProjects
		set projName to my trimWhitespace(name of proj)
		if area of proj is not missing value then
			set parentAreaName to my trimWhitespace(name of area of proj)
			set areaOrder to my getOrderFromMap(areaOrderMap, parentAreaName)
			-- Use area order * 1000 + project index for sub-ordering within area
			set end of projectOrderMap to {projName, areaOrder * 1000 + i}
		else
			-- Projects without areas get high numbers
			set end of projectOrderMap to {projName, 10000 + i}
		end if
	end repeat

	set taskDataList to {}
	repeat with t in todayTasks
		set taskName to name of t
		set taskNotes to notes of t
		set taskStatus to status of t

		if taskStatus is completed then
			set statusOrder to 0
			set taskIcon to "✅"
		else if taskStatus is canceled then
			set statusOrder to 1
			set taskIcon to "🛑"
		else
			set statusOrder to 1
			set taskIcon to "🚧"
		end if

		set groupOrder to 99999
		if project of t is not missing value then
			set groupName to my trimWhitespace(name of project of t)
			set groupOrder to my getOrderFromMap(projectOrderMap, groupName)
		else if area of t is not missing value then
			set groupName to my trimWhitespace(name of area of t)
			set groupOrder to my getOrderFromMap(areaOrderMap, groupName) * 1000
		else
			set groupName to "Other"
		end if

		set end of taskDataList to {groupOrder, groupName, statusOrder, taskName, taskNotes, taskIcon}
	end repeat
end tell

set taskDataList to my quickSort(taskDataList)

set currentGroup to ""
repeat with taskData in taskDataList
	set groupName to item 2 of taskData
	set taskName to item 4 of taskData
	set taskNotes to item 5 of taskData
	set taskIcon to item 6 of taskData

	if groupName is not currentGroup then
		set currentGroup to groupName
		set taskOutput to taskOutput & "### " & groupName & linefeed
	end if

	set formattedNotes to ""
	set urlInTitle to "**" & taskName & "**"

	if taskNotes is not "" then
		set noteLines to paragraphs of taskNotes
		set firstLine to item 1 of noteLines

		set linkURL to ""

		if firstLine starts with "[" and firstLine contains "](" and firstLine ends with ")" then
			set startBracket to offset of "[" in firstLine
			set endBracket to offset of "]" in firstLine
			set startParen to offset of "(" in firstLine
			set endParen to offset of ")" in firstLine
			set linkURL to text (startParen + 1) thru (endParen - 1) of firstLine
		else if firstLine starts with "http" and firstLine does not contain " " then
			set linkURL to firstLine
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

	set taskOutput to taskOutput & "- " & taskIcon & " " & urlInTitle & linefeed & formattedNotes
end repeat

return "## " & my formatDate(currentDate) & linefeed & taskOutput

on trimWhitespace(txt)
	set trimmedText to do shell script "echo " & quoted form of txt & " | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'"
	return trimmedText
end trimWhitespace

on getOrderFromMap(orderMap, itemName)
	repeat with mapEntry in orderMap
		if first item of mapEntry is itemName then
			return second item of mapEntry
		end if
	end repeat
	return 99999
end getOrderFromMap

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
		set charID to id of thisChar
		if charID is 8232 or charID is 8233 then -- U+2028 or U+2029
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

on quickSort(theList)
	if length of theList ≤ 1 then
		return theList
	end if

	set pivot to first item of theList
	set lessList to {}
	set greaterList to {}

	repeat with i from 2 to length of theList
		set currentItem to item i of theList
		set currentGroupOrder to first item of currentItem
		set currentGroup to second item of currentItem
		set currentStatus to third item of currentItem
		set currentName to fourth item of currentItem
		set pivotGroupOrder to first item of pivot
		set pivotGroup to second item of pivot
		set pivotStatus to third item of pivot
		set pivotName to fourth item of pivot

		-- Sort by group order first, then status, then name
		if currentGroupOrder < pivotGroupOrder then
			set end of lessList to currentItem
		else if currentGroupOrder > pivotGroupOrder then
			set end of greaterList to currentItem
		else if currentStatus < pivotStatus then
			set end of lessList to currentItem
		else if currentStatus > pivotStatus then
			set end of greaterList to currentItem
		else if currentName comes before pivotName then
			set end of lessList to currentItem
		else
			set end of greaterList to currentItem
		end if
	end repeat

	return (my quickSort(lessList)) & {pivot} & (my quickSort(greaterList))
end quickSort
