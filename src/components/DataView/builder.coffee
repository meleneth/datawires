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
  add_form: () ->
    form = new FormBuilder
    @add_a_child form.data
    return form

class FormBuilder extends Builder
  get_default_data: (type) ->
    return
      type: 'form'
      style: {}
      children: []
  add_input: (label, target, field) ->
    input = new InputField label, target, field
    @add_a_child input.data
    return input

class InputField extends RootBuilder
  constructor: (@label, @target, @field) ->
    super 'input'
    @data.label = @label
    @data.target = @target
    @data.field = @field
  get_default_data: (type) ->
    return
      type: 'input'
      style: {}
      children: []
      label: false
      target: false
      field: false

class GridCell
  constructor: (@name, @grid, @update_func) ->
    @_cell = new Builder 'div'
    @data = @_cell.data
    @data.style['grid-area'] = @name
  cell: ->
    @_cell
  set_grid: (x, y) ->
    @grid[y][x] = @name
    update_func = @update_func
    update_func()
    @

class GridBuilder extends Builder
  constructor: (@width, @height) ->
    super 'div'
    @data.style['display'] = 'grid'
    @gridcells = new Array @height
    @column_templates = new Array @width
    @row_templates = new Array @height

    for y in [0...@height]
      @row_templates[y] = '1fr'
      line = new Array @width
      for x in [0...@width]
        line[x] = 'unset'
      @gridcells[y] = line
    for x in [0...@width]
      @column_templates[x] = '1fr'
    @_update_style()
  get_default_data: (type) ->
    return
      type: 'div'
      style: {"display": "grid"}
      children: []
  add_cell: (cell_name) ->
    cell = new GridCell cell_name, @gridcells, @_update_style.bind(@)
    @data.children.push cell.data
    return cell
  _update_style: ->
    grid_lines = (_.join cells, " " for cells in @gridcells)
    grid_lines = _.map grid_lines, (g) -> _.join ['', g, ''], '"'
    @data.style['grid-template-areas'] = _.join grid_lines, " "
    @data.style['grid-template-columns'] = _.join @column_templates, " "
    @data.style['grid-template-rows'] = _.join @row_templates, " "
    @

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
export {
  GridBuilder,
  Builder
 }
