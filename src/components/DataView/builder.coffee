class RootBuilder
  constructor: (type) ->
    @data = @get_default_data type
  get_default_data: (type) ->
      type: type
      style: {}
      children: []
  set_style: (name, value) ->
    @data.style[name] = value
    return @
  add_a_child: (child) ->
    @data.children.push child
    return self

class Builder extends RootBuilder
  add_div: ->
    div = new Builder 'div'
    @add_a_child div.data
    return div
  add_grid: ->
    grid = new Builder 'div'
    grid.set_style 'display', 'grid'
    @add_a_child grid.data
    return grid
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
  add_inline_grid: ->
    grid = new InlineGridBuilder
    grid.set_style 'display', 'inline-grid'
    @add_a_child grid.data
    return grid
  add_button: (label, target) ->
    button = new ButtonBuilder label, target
    @add_a_child button.data
    return button


class GridBuilder extends Builder
  get_default_data: (type) ->
    return
      type: 'grid'
      style: {"display": "grid"}
      children: []

class InlineGridBuilder extends GridBuilder
  get_default_data: (type) ->
    return
      type: 'grid'
      style:
        display: "inline-grid"
      children: []

class ButtonBuilder extends RootBuilder
  constructor: (label, target) ->
    super 'button'
    @target target
    @label label
  get_default_data: (type) ->
    return
      target: false
      label: false
      type: 'button'
      style: {}
  target: (target) ->
    @data.target = target
    return @
  label: (label) ->
    @data.label = label
    return @

class TextBuilder extends RootBuilder
  constructor: (text) ->
    super 'text'
    @text text
  get_default_data: (type) ->
    return
      text: false
      style: {}
      type: 'text'
  text: (text) ->
    @data['text'] = text


export default Builder
