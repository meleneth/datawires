import { v4 as uuidv4 } from 'uuid'
import { FormBuilder, InputField } from '@/components/DataView/builder'

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
  add_safe_button: (label, target) ->
    button_classes =
      "bg-white": true
      "py-2": true
      "px-4": true
      "border": true
      "border-gray-300": true
      "rounded-md": true
      "shadow-sm": true
      "text-sm": true
      "font-medium": true
      "text-gray-700": true
      "hover:bg-gray-50": true
      "focus:outline-none": true
      "focus:ring-2": true
      "focus:ring-offset-2": true
      "focus:ring-indigo-500": true
    button = @add_button(label, target)
    button.set_classes button_classes

  add_action_button: (label, target) ->
    button_classes =
      "ml-3": true
      "inline-flex": true
      "justify-center": true
      "py-2": true
      "px-4": true
      "border": true
      "border-transparent": true
      "shadow-sm": true
      "text-sm": true
      "font-medium": true
      "rounded-md": true
      "text-white": true
      "bg-indigo-600": true
      "hover:bg-indigo-700": true
      "focus:outline-none": true
      "focus:ring-2": true
      "focus:ring-offset-2": true
      "focus:ring-indigo-500": true
    button = @add_button(label, target)
    button.set_classes button_classes

  add_header_text: (title, description) ->
    div = @frame.add_div().add_div()
    div.set_classes {'mt-1': true}
    div.add_h3 title
      .set_classes @label_classes()
    div.add_p description
      .set_classes @p_classes()
  
  with_some_headroom: () ->
    div = @frame.add_div()
    div.set_classes {'pt-8': true}

  add_input: (builder, label, target, field) ->
    field_classes =
      "shadow-sm": true
      "block": true
      "w-full": true
      "border-gray-300": true
      "rounded-md": true
      "focus:ring-indigo-500": true
      "focus:border-indigo-500": true
      "sm:text-sm": true
    label_classes =
      "block": true
      "text-sm": true
      "font-medium": true
      "text-gray-700": true
    uid = uuidv4()
    label = builder.add_label label
    label.set_for uid
    label.set_classes label_classes

    div = builder.add_div()
    div.set_classes {"mt-1": true}
    
    input = div.add_input target, field
    input.set_id uid
    input.set_classes field_classes
  
  add_line_2: () ->
    uid = uuidv4()
    wrapper_classes =
      "mt-6": true
      "grid": true
      "grid-cols-1": true
      "gap-y-6": true
      "gap-x-4": true
      "sm:grid-cols-6": true
    inner_classes =
      "sm:col-span-3" : true
    div = @add_div().set_classes wrapper_classes
    return [
      div.add_div().set_classes inner_classes
      div.add_div().set_classes inner_classes
    ]

  add_line_3: () ->
    uid = uuidv4()
    wrapper_classes =
      "mt-6": true
      "grid": true
      "grid-cols-1": true
      "gap-y-6": true
      "gap-x-4": true
      "sm:grid-cols-6": true
    inner_classes =
      "sm:col-span-2" : true
    div = @add_div().set_classes wrapper_classes
    return [
      div.add_div().set_classes inner_classes
      div.add_div().set_classes inner_classes
      div.add_div().set_classes inner_classes
    ]

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

export default DecoratedFormBuilder
