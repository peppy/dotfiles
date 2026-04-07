#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Output standup from Things logbook
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Days to output", "optional": true }

# Documentation:
# @raycast.author ppy
# @raycast.authorURL https://raycast.com/ppy

on run argv
    if (count of argv) > 0 and item 1 of argv is not "" then
        set daysBack to item 1 of argv as integer
    else
        set daysBack to 0
    end if

    set dbPath to my findThingsDB()

    set sep to "␞"
    set nlPlaceholder to "␤"

    set sqlQuery to "
WITH tasks AS (
    SELECT
        date(t.stopDate, 'unixepoch', '-8 hours', 'localtime') AS day,
        COALESCE(a2.title, a.title, 'Other') AS groupName,
        CASE t.status WHEN 3 THEN '✅' ELSE '⏸️' END AS icon,
        t.title,
        REPLACE(REPLACE(COALESCE(t.notes, ''), char(10), '" & nlPlaceholder & "'), char(13), '" & nlPlaceholder & "') AS notes,
        COALESCE(
            CASE WHEN p.uuid IS NOT NULL THEN
                CASE WHEN a2.uuid IS NOT NULL THEN a2.\"index\" * 1000 + p.\"index\"
                ELSE 10000 + p.\"index\" END
            WHEN a.uuid IS NOT NULL THEN a.\"index\" * 1000
            ELSE 99999 END,
        99999) AS groupOrd,
        CASE t.status WHEN 3 THEN 0 WHEN 2 THEN 1 ELSE 2 END AS statusOrd
    FROM TMTask t
    LEFT JOIN TMTask p ON t.project = p.uuid
    LEFT JOIN TMArea a ON t.area = a.uuid
    LEFT JOIN TMArea a2 ON p.area = a2.uuid
    WHERE (
            (day >= date('now', 'localtime', '-" & daysBack & " days') AND t.stopDate IS NOT NULL)
            OR (t.status = 0 AND date(t.startDate, 'unixepoch', '-8 hours', 'localtime') = date('now', 'localtime'))
        )
        AND t.type = 0
        AND t.trashed = 0
        AND EXISTS (
            SELECT 1 FROM TMTaskTag tt
            JOIN TMTag tg ON tt.tags = tg.uuid
            WHERE tt.tasks = t.uuid AND tg.title = 'Standup'
        )

    UNION

    SELECT
        date('now', 'localtime') AS day,
        COALESCE(a2.title, a.title, 'Other') AS groupName,
        '🚧' AS icon,
        t.title,
        REPLACE(REPLACE(COALESCE(t.notes, ''), char(10), '" & nlPlaceholder & "'), char(13), '" & nlPlaceholder & "') AS notes,
        COALESCE(
            CASE WHEN p.uuid IS NOT NULL THEN
                CASE WHEN a2.uuid IS NOT NULL THEN a2.\"index\" * 1000 + p.\"index\"
                ELSE 10000 + p.\"index\" END
            WHEN a.uuid IS NOT NULL THEN a.\"index\" * 1000
            ELSE 99999 END,
        99999) AS groupOrd,
        2 AS statusOrd
    FROM TMTask t
    LEFT JOIN TMTask p ON t.project = p.uuid
    LEFT JOIN TMArea a ON t.area = a.uuid
    LEFT JOIN TMArea a2 ON p.area = a2.uuid
    WHERE t.status = 0
        AND t.type = 0
        AND t.trashed = 0
        AND t.start = 1
        AND t.startDate IS NOT NULL
        AND t.stopDate IS NULL
        AND EXISTS (
            SELECT 1 FROM TMTaskTag tt
            JOIN TMTag tg ON tt.tags = tg.uuid
            WHERE tt.tasks = t.uuid AND tg.title = 'Standup'
        )
)
SELECT day || '" & sep & "' || groupName || '" & sep & "' || icon || '" & sep & "' || title || '" & sep & "' || notes
FROM tasks
ORDER BY day, groupOrd, statusOrd, title"


    set rawResults to do shell script "sqlite3 " & quoted form of dbPath & " " & quoted form of sqlQuery

    if rawResults is "" then return "No standup tasks found in the last " & daysBack & " days."

    set output to ""
    set curDate to ""
    set curGroup to ""

    repeat with aLine in paragraphs of rawResults
        set {dayStr, groupName, statusIcon, taskTitle, taskNotes} to my splitByDelim(aLine, sep)
        set taskNotes to my replaceText(taskNotes, nlPlaceholder, linefeed)

        if dayStr is not curDate then
            set curDate to dayStr
            set curGroup to ""
            set output to output & "## " & dayStr & linefeed
        end if

        if groupName is not curGroup then
            set curGroup to groupName
            set output to output & "### " & groupName & linefeed
        end if

        set titleMd to "**" & taskTitle & "**"
        set notesMd to ""

        if taskNotes is not "" then
            set noteLines to paragraphs of taskNotes
            set linkURL to my extractURL(item 1 of noteLines)

            if linkURL is not "" then
                set titleMd to my formatLinkedTitle(taskTitle, linkURL)
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
                    set notesMd to notesMd & l & linefeed
                else
                    set formatted to my surroundURLsWithBrackets(l)
                    if not inCodeBlock then set formatted to "> " & formatted
                    set notesMd to notesMd & formatted & linefeed
                end if
            end repeat
        end if

        set output to output & "- " & statusIcon & " " & titleMd & linefeed & notesMd
    end repeat

    return output
end run

# https://culturedcode.com/things/support/articles/2982272/
on findThingsDB()
    set baseDir to POSIX path of (path to home folder) & "Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/"
    set dataDir to do shell script "ls " & quoted form of baseDir & " | grep '^ThingsData' | head -1"
    if dataDir is "" then error "Could not find Things database directory."
    return baseDir & dataDir & "/Things Database.thingsdatabase/main.sqlite"
end findThingsDB

on extractURL(firstLine)
    if firstLine starts with "[" and firstLine contains "](" and firstLine ends with ")" then
        set s to offset of "(" in firstLine
        return text (s + 1) thru -2 of firstLine
    else if firstLine starts with "http" and firstLine does not contain " " then
        return firstLine
    end if
    return ""
end extractURL

on formatLinkedTitle(taskTitle, linkURL)
    if linkURL does not contain "https" then return "**" & taskTitle & "**"
    set viewLink to " ([view](<" & linkURL & ">))"
    if taskTitle contains ":" then
        set p to offset of ":" in taskTitle
        set suffix to text (p + 1) thru -1 of taskTitle
        if suffix starts with " " then set suffix to text 2 thru -1 of suffix
        return text 1 thru p of taskTitle & " **" & suffix & "**" & viewLink
    end if
    return "**" & taskTitle & "**" & viewLink
end formatLinkedTitle

on splitByDelim(theText, theDelim)
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelim
    set theParts to text items of theText
    set AppleScript's text item delimiters to oldDelims
    return theParts
end splitByDelim

on replaceText(theText, searchStr, replaceStr)
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to searchStr
    set theParts to text items of theText
    set AppleScript's text item delimiters to replaceStr
    set theText to theParts as string
    set AppleScript's text item delimiters to oldDelims
    return theText
end replaceText

on normaliseLineEndings(theText)
    set t to ""
    repeat with i from 1 to (count theText)
        set c to id of character i of theText
        if c is 8232 or c is 8233 then
            set t to t & return
        else
            set t to t & character i of theText
        end if
    end repeat
    return t
end normaliseLineEndings

on trimEmptyLines(noteLines)
    repeat while noteLines is not {} and first item of noteLines is ""
        if (count of noteLines) > 1 then
            set noteLines to items 2 thru -1 of noteLines
        else
            return {}
        end if
    end repeat
    repeat while noteLines is not {} and last item of noteLines is ""
        if (count of noteLines) > 1 then
            set noteLines to items 1 thru -2 of noteLines
        else
            return {}
        end if
    end repeat
    return noteLines
end trimEmptyLines

on surroundURLsWithBrackets(inputText)
    return do shell script "echo " & quoted form of inputText & " | sed -E 's|([a-z]+)?://[%~a-zA-Z0-9./?=_-]+|<&>|g'"
end surroundURLsWithBrackets

