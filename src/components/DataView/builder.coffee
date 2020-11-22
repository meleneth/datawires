class ButtonBuilder
  constructor: (label, target) ->
    @data =
      target: target
      label: label
      type: 'button'
  target: (target) ->
    @data['target'] = target
    return @
  label: (label) ->
    @data['label'] = label
    return @

class TextBuilder
  constructor: (text) ->
    @data =
      text: text
      type: 'text'
  text: (text) ->
    @data['text'] = text

class Builder
  constructor: (type) ->
    @data =
      type: type
      children: []
  add_container: ->
    container = new Builder 'container'
    @data.children.push container.data
    return container
  add_row: ->
    row = new Builder 'row'
    @data.children.push row.data
    return row
  add_col: ->
    col = new Builder 'col'
    @data.children.push col.data
    return col
  add_button: (label, target) ->
    button = new ButtonBuilder label, target
    @data.children.push button.data
    return button
  add_card: () ->
    card = new Builder 'card'
    @data.children.push card.data
    return card
  add_sheet: () ->
    sheet = new Builder 'sheet'
    @data.children.push sheet.data
    return sheet
  add_p: () ->
    p = new Builder 'p'
    @data.children.push p.data
    return p
  add_text: (text) ->
    text_builder = new TextBuilder text
    @data.children.push text_builder.data
export default Builder
