import { v4 as uuidv4 } from 'uuid'
import { FormBuilder } from '@/components/DataView/builder'

class DecoratedFormBuilder extends FormBuilder
  constructor: (type) ->
    super type
    @set_classes @outer_classes()
    @frame = @add_div()
    @frame.set_classes @outer_classes()

  outer_classes: -> {
    "space-y-8": true, "divide-y": true, "divide-gray-200": true
  }
  label_classes: -> {
    "text-lg": true, "leading-6": true,
    "font-medium": true, "text-gray-900": true
  }
  p_classes: -> {
    "mt-1": true, "text-sm": true, "text-gray-500": true
  }

  add_header_text: (title, description) ->
    div = @frame.add_div().add_div()
    div.set_classes {'mt-1': true}
    div.add_h3 title
      .set_classes @label_classes()
    div.add_p description
      .set_classes @p_classes()

  add_textarea: (label, details, target, field_name) ->
    uid = uuidv4()
    div = @frame.add_div()
      .set_classes {'sm:col-span-6': true}
    div.add_label label
      .set_for uid
    mt_1 = div.add_div()
      .set_classes {'mt-1': true}
    mt_1.add_textarea target, field_name
      .set_classes {
        'shadow-sm': true,
        'block': true,
        'w-full': true,
        'border-gray-300': true,
        'rounded-md': true
      }
      .set_name uid
      .set_id uid
    div.add_p()
      .set_classes {
        'mt-2': true,
        'text-sm': true,
        'text-gray-500':true,
      }
      .add_text details

  add_row: ->
  add_input: ->

export default DecoratedFormBuilder
