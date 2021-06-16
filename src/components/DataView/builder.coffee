class GridBuilder extends Builder
  get_default_data: (type) ->
    return
      type: 'grid'
      children: []
      style: {"display": "grid"}

class InlineGridBuilder extends GridBuilder
  get_default_data: (type) ->
    return
      type: 'grid'
      children: []
      style:
        display: "inline-grid"

class ButtonBuilder
  constructor: (label, target) ->
    @data =
      target: target
      label: label
      type: 'button'
      style: {}
  target: (target) ->
    @data.target = target
    return @
  label: (label) ->
    @data.label = label
    return @

class TextBuilder
  constructor: (text) ->
    @data =
      text: text
      type: 'text'
      style: {}
  text: (text) ->
    @data['text'] = text

class Builder
  constructor: (type) ->
    @data = @get_default_data(type)
  set_style: (name, value) ->
    @data.style[name] = value
    return @
  get_default_data: (type) ->
    @data =
      type: type
      children: []
      style: {}
  add_a_child: (child) ->
    @data.children.push child
    return self
  add_div: ->
    div = new Builder 'div'
    @add_a_child div.data
    return div
  add_grid: ->
    grid = new GridBuilder
    grid.set_style 'display', 'grid'
    @add_a_child grid.data
    return grid
  add_inline_grid: ->
    grid = new InlineGridBuilder
    grid.set_style 'display', 'inline-grid'
    @add_a_child grid.data
    return grid
  add_button: (label, target) ->
    button = new ButtonBuilder label, target
    @add_a_child button.data
    return button
  add_card: () ->
    card = new Builder 'card'
    @add_a_child card.data
    return card
  add_p: () ->
    p = new Builder 'p'
    @add_a_child p.data
    return p
  add_text: (text) ->
    text_builder = new TextBuilder text
    @data.children.push text_builder.data
    return @
export default Builder
