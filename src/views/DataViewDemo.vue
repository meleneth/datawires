<template lang="pug">
pre
  | 112
  | 402
  | 433

div.mt-8(v-for="view in views")
  data-view(:field="view")
p And that's all she wrote!
p
p
p Builder and DataView Demo
p.mt-6
p And that's all she wrote! ... again
p
p
p.mt-6
form.space-y-8.divide-y.divide-gray-200
  .space-y-8.divide-y.divide-gray-200
    div
      div
        h3.text-lg.leading-6.font-medium.text-gray-900
          | Profile
        p.mt-1.text-sm.text-gray-500
          | This information will be displayed publicly so be careful what you share.
      .mt-6.grid.grid-cols-1.gap-y-6.gap-x-4(class='sm:grid-cols-6')
        div(class='sm:col-span-4')
          label.block.text-sm.font-medium.text-gray-700(for='username')
            | Username
          .mt-1.flex.rounded-md.shadow-sm
            span.inline-flex.items-center.px-3.rounded-l-md.border.border-r-0.border-gray-300.bg-gray-50.text-gray-500(class='sm:text-sm')
              | workcation.com/
            input#username.flex-1.block.w-full.min-w-0.rounded-none.rounded-r-md.border-gray-300(type='text', name='username', autocomplete='username', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
        div(class='sm:col-span-6')
          label.block.text-sm.font-medium.text-gray-700(for='about')
            | About
          .mt-1
            textarea#about.shadow-sm.block.w-full.border-gray-300.rounded-md(name='about', rows='3', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
          p.mt-2.text-sm.text-gray-500 Write a few sentences about yourself.
        div(class='sm:col-span-6')
          label.block.text-sm.font-medium.text-gray-700(for='photo')
            | Photo
          .mt-1.flex.items-center
            span.h-12.w-12.rounded-full.overflow-hidden.bg-gray-100
              svg.h-full.w-full.text-gray-300(fill='currentColor', viewbox='0 0 24 24')
                path(d='M24 20.993V24H0v-2.996A14.977 14.977 0 0112.004 15c4.904 0 9.26 2.354 11.996 5.993zM16.002 8.999a4 4 0 11-8 0 4 4 0 018 0z')
            button.ml-5.bg-white.py-2.px-3.border.border-gray-300.rounded-md.shadow-sm.text-sm.leading-4.font-medium.text-gray-700(type='button', class='hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500')
              | Change
        div(class='sm:col-span-6')
          label.block.text-sm.font-medium.text-gray-700(for='cover_photo')
            | Cover photo
          .mt-1.flex.justify-center.px-6.pt-5.pb-6.border-2.border-gray-300.border-dashed.rounded-md
            .space-y-1.text-center
              svg.mx-auto.h-12.w-12.text-gray-400(stroke='currentColor', fill='none', viewbox='0 0 48 48', aria-hidden='true')
                path(d='M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02', stroke-width='2', stroke-linecap='round', stroke-linejoin='round')
              .flex.text-sm.text-gray-600
                label.relative.cursor-pointer.bg-white.rounded-md.font-medium.text-indigo-600(for='file-upload', class='hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500')
                  span Upload a file
                  input#file-upload.sr-only(name='file-upload', type='file')
                p.pl-1 or drag and drop
              p.text-xs.text-gray-500
                | PNG, JPG, GIF up to 10MB
    .pt-8
      div
        h3.text-lg.leading-6.font-medium.text-gray-900
          | Personal Information
        p.mt-1.text-sm.text-gray-500
          | Use a permanent address where you can receive mail.
      .mt-6.grid.grid-cols-1.gap-y-6.gap-x-4(class='sm:grid-cols-6')
        div(class='sm:col-span-3')
          label.block.text-sm.font-medium.text-gray-700(for='first_name')
            | First name
          .mt-1
            input#first_name.shadow-sm.block.w-full.border-gray-300.rounded-md(type='text', name='first_name', autocomplete='given-name', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
        div(class='sm:col-span-3')
          label.block.text-sm.font-medium.text-gray-700(for='last_name')
            | Last name
          .mt-1
            input#last_name.shadow-sm.block.w-full.border-gray-300.rounded-md(type='text', name='last_name', autocomplete='family-name', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
        div(class='sm:col-span-4')
          label.block.text-sm.font-medium.text-gray-700(for='email')
            | Email address
          .mt-1
            input#email.shadow-sm.block.w-full.border-gray-300.rounded-md(name='email', type='email', autocomplete='email', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
        div(class='sm:col-span-3')
          label.block.text-sm.font-medium.text-gray-700(for='country')
            | Country / Region
          .mt-1
            select#country.shadow-sm.block.w-full.border-gray-300.rounded-md(name='country', autocomplete='country', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
              option United States
              option Canada
              option Mexico
        div(class='sm:col-span-6')
          label.block.text-sm.font-medium.text-gray-700(for='street_address')
            | Street address
          .mt-1
            input#street_address.shadow-sm.block.w-full.border-gray-300.rounded-md(type='text', name='street_address', autocomplete='street-address', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
        div(class='sm:col-span-2')
          label.block.text-sm.font-medium.text-gray-700(for='city')
            | City
          .mt-1
            input#city.shadow-sm.block.w-full.border-gray-300.rounded-md(type='text', name='city', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
        div(class='sm:col-span-2')
          label.block.text-sm.font-medium.text-gray-700(for='state')
            | State / Province
          .mt-1
            input#state.shadow-sm.block.w-full.border-gray-300.rounded-md(type='text', name='state', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
        div(class='sm:col-span-2')
          label.block.text-sm.font-medium.text-gray-700(for='zip')
            | ZIP / Postal
          .mt-1
            input#zip.shadow-sm.block.w-full.border-gray-300.rounded-md(type='text', name='zip', autocomplete='postal-code', class='focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm')
    .pt-8
      div
        h3.text-lg.leading-6.font-medium.text-gray-900
          | Notifications
        p.mt-1.text-sm.text-gray-500
          | We&apos;ll always let you know about important changes, but you pick what else you want to hear about.
      .mt-6
        fieldset
          legend.text-base.font-medium.text-gray-900
            | By Email
          .mt-4.space-y-4
            .relative.flex.items-start
              .flex.items-center.h-5
                input#comments.h-4.w-4.text-indigo-600.border-gray-300.rounded(name='comments', type='checkbox', class='focus:ring-indigo-500')
              .ml-3.text-sm
                label.font-medium.text-gray-700(for='comments') Comments
                p.text-gray-500 Get notified when someones posts a comment on a posting.
            .relative.flex.items-start
              .flex.items-center.h-5
                input#candidates.h-4.w-4.text-indigo-600.border-gray-300.rounded(name='candidates', type='checkbox', class='focus:ring-indigo-500')
              .ml-3.text-sm
                label.font-medium.text-gray-700(for='candidates') Candidates
                p.text-gray-500 Get notified when a candidate applies for a job.
            .relative.flex.items-start
              .flex.items-center.h-5
                input#offers.h-4.w-4.text-indigo-600.border-gray-300.rounded(name='offers', type='checkbox', class='focus:ring-indigo-500')
              .ml-3.text-sm
                label.font-medium.text-gray-700(for='offers') Offers
                p.text-gray-500 Get notified when a candidate accepts or rejects an offer.
        fieldset.mt-6
          div
            legend.text-base.font-medium.text-gray-900
              | Push Notifications
            p.text-sm.text-gray-500 These are delivered via SMS to your mobile phone.
          .mt-4.space-y-4
            .flex.items-center
              input#push_everything.h-4.w-4.text-indigo-600.border-gray-300(name='push_notifications', type='radio', class='focus:ring-indigo-500')
              label.ml-3.block.text-sm.font-medium.text-gray-700(for='push_everything')
                | Everything
            .flex.items-center
              input#push_email.h-4.w-4.text-indigo-600.border-gray-300(name='push_notifications', type='radio', class='focus:ring-indigo-500')
              label.ml-3.block.text-sm.font-medium.text-gray-700(for='push_email')
                | Same as email
            .flex.items-center
              input#push_nothing.h-4.w-4.text-indigo-600.border-gray-300(name='push_notifications', type='radio', class='focus:ring-indigo-500')
              label.ml-3.block.text-sm.font-medium.text-gray-700(for='push_nothing')
                | No push notifications
  .pt-5
    .flex.justify-end
      button.bg-white.py-2.px-4.border.border-gray-300.rounded-md.shadow-sm.text-sm.font-medium.text-gray-700(type='button', class='hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500')
        | Cancel
      button.ml-3.inline-flex.justify-center.py-2.px-4.border.border-transparent.shadow-sm.text-sm.font-medium.rounded-md.text-white.bg-indigo-600(type='submit', class='hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500')
        | Save

</template><script lang="coffee">
import Builder from '@/components/DataView/builder.coffee'
import DecoratedFormBuilder from '@/lib/decorated/form.coffee'
import { GridBuilder } from '@/components/DataView/builder'
import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataViewDemo'
  data: ->
    views: []
    info:
      first_name: "Some First Name"
      last_name: "Some Last Name"
    some_object: {
      some_field: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis quam neque, consequat eu metus eget, sodales maximus diam. Sed efficitur ipsum sit amet nisl aliquam tincidunt. Nunc nec ultrices magna. Ut dapibus augue sed nunc bibendum, eu interdum velit euismod. Donec fermentum, dui ac rhoncus cursus, nunc nibh lacinia arcu, id molestie risus quam quis odio. Proin hendrerit, turpis non aliquam elementum, eros ipsum varius felis, consequat pretium magna ligula ac metus. Maecenas pellentesque in leo vitae ultricies. Etiam justo ex, porttitor nec lorem eget, consectetur elementum diam."
    }
  components:
    'data-view': DataView
  mounted: ->
    @$store.dispatch 'set_page_title', "DataViewDemo"
    lorem_paragraph = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis quam neque, consequat eu metus eget, sodales maximus diam. Sed efficitur ipsum sit amet nisl aliquam tincidunt. Nunc nec ultrices magna. Ut dapibus augue sed nunc bibendum, eu interdum velit euismod. Donec fermentum, dui ac rhoncus cursus, nunc nibh lacinia arcu, id molestie risus quam quis odio. Proin hendrerit, turpis non aliquam elementum, eros ipsum varius felis, consequat pretium magna ligula ac metus. Maecenas pellentesque in leo vitae ultricies. Etiam justo ex, porttitor nec lorem eget, consectetur elementum diam."
    pinwheel = new Builder('div')
    pinwheel_grid = new GridBuilder 3, 3
    pinwheel_grid.add_cell "center"
      .set_grid 1, 1
      .cell()
      .add_text lorem_paragraph

    pinwheel_grid.add_cell "wheel1"
      .set_grid 0, 0
      .set_grid 1, 0
      .cell()
      .set_style "background-color", "red"
      .add_text lorem_paragraph

    pinwheel_grid.add_cell "wheel2"
      .set_grid 2, 0
      .set_grid 2, 1
      .cell()
      .set_style "background-color", "green"
      .add_text lorem_paragraph

    pinwheel_grid.add_cell "wheel3"
      .set_grid 2, 2
      .set_grid 1, 2
      .cell()
      .set_style "background-color", "blue"
      .add_text lorem_paragraph

    pinwheel_grid.add_cell "wheel4"
      .set_grid 0, 2
      .set_grid 0, 1
      .cell()
      .set_style "background-color", "yellow"
      .add_text lorem_paragraph

    my_display_grid = new DecoratedFormBuilder
    my_display_grid.add_header_text "Profile", "This information will be displayed publicly so be careful what you share."
    my_display_grid.add_textarea "About", "Write a few sentances about yourself", @some_object, 'some_field'
    my_display_grid.add_header_text "Personal Information", "Use a permanent address where you can receive mail."
    target = my_display_grid.add_div()
    my_display_grid.add_input target, "again First name", @info, 'first_name'
    
    line = my_display_grid.add_line_2()
    my_display_grid.add_input line[0], "First name", @info, 'first_name'
    my_display_grid.add_input line[1], "Last name", @info, 'last_name'

    @views[2] = pinwheel_grid.data
    @views[1] = my_display_grid.data
    #@views[3] = pinwheel_grid.data
    #@views[4] = pinwheel_grid.data

    builder = new Builder('container')
    builder.add_card().add_text lorem_paragraph
    @views[0] = builder.data
    #builder = new Builder('container')
    #row = builder.add_row()
    #row.add_col()
    #row.add_col().add_card().add_p().add_text lorem_paragraph
    #row.add_col()
    ##@views[1] = builder.data
    #builder = new Builder('container')
    #row = builder.add_row()
    #row.add_col().add_p().add_text lorem_paragraph
    #row.add_col().add_p().add_text lorem_paragraph
    ##@views[2] = builder.data
    #builder = new Builder('container')
    #row = builder.add_row()
    #row.add_col().add_sheet().add_p().add_text lorem_paragraph
    #row.add_col()
    #row.add_col().add_button 'Some Text', 'nothing'
    #row.add_col()
    #row.add_col().add_card().add_p().add_text lorem_paragraph
    ##@views[3] = builder.data
</script>
