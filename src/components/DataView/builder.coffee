class RootBuilder
  constructor: (type) ->
    @data = @get_default_data type
  get_default_data: (type) ->
    type: type
    style: {}
    classes: {}
    children: []
  _set: (field, value) ->
    @data[field] = value
    @
  set_style: (name, value) ->
    @data.style[name] = value
    @
  set_name: (name) ->
    @_set 'name', name
  set_id: (id) ->
    @_set 'id', id
  add_a_child: (child) ->
    @data.children.push child.data
    child
  set_classes: (classes) ->
    @_set 'classes', classes

class Builder extends RootBuilder
  add_div: ->
    div = new Builder 'div'
    @add_a_child div
  add_grid: ->
    grid = new Builder 'div'
    grid.set_style 'display', 'grid'
    @add_a_child grid
  add_card: () ->
    card = new Builder 'card'
    @add_a_child card
  add_h3: (text=false) ->
    h3 = new Builder 'h3'
    h3.add_text text if text
    @add_a_child h3
  add_p: (text=false) ->
    p = new Builder 'p'
    p.add_text text if text
    @add_a_child p
  add_label: (text=false) ->
    label = new LabelBuilder 'label'
    label.add_text text if text
    @add_a_child label
  add_text: (text) ->
    text_builder = new TextBuilder text
    @add_a_child(text_builder)
  add_textarea: (target, field) ->
    textarea_builder = new TextArea target, field
    @add_a_child textarea_builder
  add_inline_grid: ->
    grid = new InlineGridBuilder
    grid.set_style 'display', 'inline-grid'
    @add_a_child grid
  add_button: (label, target) ->
    button = new ButtonBuilder label, target
    @add_a_child button
  add_form: () ->
    form = new FormBuilder 'form'
    @add_a_child form

class LabelBuilder extends Builder
  get_default_data: (type) ->
    return
      type: 'form'
      style: {}
      classes: {}
      children: []
      for: false
      text: ''
  set_for: (what_for) ->
    @data.for = what_for
    @
  set_text: (text) ->
    @data.text = text

class FormBuilder extends Builder
  get_default_data: (type) ->
    return
      type: 'form'
      style: {}
      classes: {}
      children: []
  add_input: (label, target, field) ->
    input = new InputField label, target, field
    @add_a_child input
    return input

class TextArea extends RootBuilder
  constructor: (@target, @field) ->
    super 'textarea'
    @data.target = @target
    @data.field = @field

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
      classes: {}
      children: []
      label: false
      target: false
      field: false

class GridCell extends RootBuilder
  constructor: (@name, @grid, @update_func) ->
    super('div')
    @_cell = new Builder 'div'
    @_cell.set_style 'grid-area', @name
    @data = @_cell.data
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
    @set_style 'display', 'grid'
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
      style:
        display: "grid"
        "grid-template-areas": ""
        "grid-template-columns": ""
        "grid-template-rows": ""
      children: []
  add_cell: (cell_name) ->
    cell = new GridCell cell_name, @gridcells, @_update_style.bind(@)
    @add_a_child cell
  _update_style: ->
    grid_lines = (_.join cells, " " for cells in @gridcells)
    grid_lines = _.map grid_lines, (g) -> _.join ['', g, ''], '"'
    @set_style 'grid-template-areas', _.join grid_lines, " "
    @set_style 'grid-template-columns',  _.join @column_templates, " "
    @set_style 'grid-template-rows', _.join @row_templates, " "
    @

class InlineGridBuilder extends GridBuilder
  get_default_data: (type) ->
    return
      type: 'grid'
      style:
        display: "inline-grid"
      classes: {}
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
    @

class TextBuilder extends RootBuilder
  constructor: (text) ->
    super 'text'
    @text text
  get_default_data: (type) ->
    return
      text: false
      style: {}
      classes: {}
      type: 'text'
  text: (text) ->
    @data['text'] = text


export default Builder
export {
  GridBuilder,
  Builder,
  FormBuilder
 }
