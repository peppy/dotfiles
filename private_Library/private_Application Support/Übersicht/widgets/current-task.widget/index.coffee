command: "osascript /Users/dean/scripts/next-task.applescript"
refreshFrequency: 1000

style: """
  bottom: 0
  width: 100%
  color: #fff
  font-family: Jetbrains Mono
  text-shadow: 0px 0px 15px rgba(#000, 0.6)

  .content
    padding: 4px 6px 9px 6px
    text-align: center
    font-size: 24px
    font-weight: 100
    width: 100%
    overflow: hidden

  .info
    padding: 0
    margin: 0
    font-size: 14px
    max-width: 100%
    opacity: 0.9
    text-overflow: ellipsis
"""

render: -> "<div class='content'></div>"

update: (output, domEl) ->
    escape = (text) ->
      text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;')

    output = output.split('\n')

    # uses last output if no output available (happens when making new task)
    return if output.length < 1

    task = output[0]
    return if task.length == 0

    info = if output.length > 1 then output[1] else ''

    $(domEl).find('.content').html """
      <div class='wrapper'>
        <strong>Current Task</strong>: #{escape(task)}
        <div class='info'>#{escape(info)}</div>
      </div>
    """
