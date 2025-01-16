tell application "Things3"
  set selected to selected to dos

  set output to ""
  repeat with todo in selected
    if project of todo is not missing value then
      set output to name of todo & linefeed & name of area of project of todo & " – " & name of project of todo
    else
      set output to name of todo & linefeed & name of area of todo
    end if
  end repeat

  return output
end tell
