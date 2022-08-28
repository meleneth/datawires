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

  add_textarea: ->
    uid = uuidv4()
    div = @frame.add_div()
      .set_classes {'sm:col-span-6': true}
    div.add_label 'About'
      .set_id uid
    div.add_label
    div.add_p()
      .set_classes {}
  # div(class='sm:col-span-6')
  #   label.block.text-sm.font-medium.text-gray-700(for='about')
  #     | About
  #   .mt-1
  #     textarea#about.shadow-sm.block.w-full.border-gray-300.rounded-md(name='about', rows='3', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
  #   p.mt-2.text-sm.text-gray-500 Write a few sentences about yourself.

  add_row: ->
  add_input: ->

export default DecoratedFormBuilder
