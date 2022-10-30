<template lang="pug">
.min-h-full
  Disclosure.bg-gray-800(as='nav' v-slot='{ open }')
    .mx-auto.max-w-7xl.px-4(class='sm:px-6 lg:px-8')
      .flex.h-16.items-center.justify-between
        .flex.items-center
          .flex-shrink-0
            img.h-8.w-8(src='public_datawires_logo_3.svg' alt='datawires')
          .hidden(class='md:block')
            .ml-10.flex.items-baseline.space-x-4
              router-link(v-for="link in navigation" :key="link.name" :to="link.href" :class="[link.current ? 'bg-gray-900 text-white' : 'text-gray-300 hover:bg-gray-700 hover:text-white', 'px-3 py-2 rounded-md text-sm font-medium']" :aria-current="link.current ? 'page' : 'false'") {{ link.name }}
        .hidden(class='md:block')
          .ml-4.flex.items-center(class='md:ml-6')
            button.rounded-full.bg-gray-800.p-1.text-gray-400(type='button' class='hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800')
              span.sr-only View notifications
              BellIcon.h-6.w-6(aria-hidden='true')
            // Profile dropdown
            Menu.relative.ml-3(as='div')
              div
                MenuButton.flex.max-w-xs.items-center.rounded-full.bg-gray-800.text-sm(class='focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800')
                  span.sr-only Open user menu
                  img.h-8.w-8.rounded-full(:src='user.imageUrl' alt='')
              transition(enter-active-class='transition ease-out duration-100' enter-from-class='transform opacity-0 scale-95' enter-to-class='transform opacity-100 scale-100' leave-active-class='transition ease-in duration-75' leave-from-class='transform opacity-100 scale-100' leave-to-class='transform opacity-0 scale-95')
                MenuItems.absolute.right-0.z-10.mt-2.w-48.origin-top-right.rounded-md.bg-white.py-1.shadow-lg.ring-1.ring-black.ring-opacity-5(class='focus:outline-none')
                  MenuItem(v-for='item in userNavigation' :key='item.name' v-slot='{ active }')
                    a(:href='item.href' :class="[active ? 'bg-gray-100' : '', 'block px-4 py-2 text-sm text-gray-700']") {{ item.name }}
        .-mr-2.flex(class='md:hidden')
          // Mobile menu button
          DisclosureButton.inline-flex.items-center.justify-center.rounded-md.bg-gray-800.p-2.text-gray-400(class='hover:bg-gray-700 hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800')
            span.sr-only Open main menu
            Bars3Icon.block.h-6.w-6(v-if='!open' aria-hidden='true')
            XMarkIcon.block.h-6.w-6(v-else='' aria-hidden='true')
    DisclosurePanel(class='md:hidden')
      .space-y-1.px-2.pt-2.pb-3(class='sm:px-3')
        router-link(v-for="link in navigation" :key="link.name" :to="link.href" :class="[link.current ? 'bg-gray-900 text-white' : 'text-gray-300 hover:bg-gray-700 hover:text-white', 'px-3 py-2 rounded-md text-sm font-medium']" :aria-current="link.current ? 'page' : 'false'") {{ link.name }}
      .border-t.border-gray-700.pt-4.pb-3
        .flex.items-center.px-5
          .flex-shrink-0
            img.h-10.w-10.rounded-full(:src='user.imageUrl' alt='')
          .ml-3
            .text-base.font-medium.leading-none.text-white {{ user.name }}
            .text-sm.font-medium.leading-none.text-gray-400 {{ user.email }}
          button.ml-auto.flex-shrink-0.rounded-full.bg-gray-800.p-1.text-gray-400(type='button' class='hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800')
            span.sr-only View notifications
            BellIcon.h-6.w-6(aria-hidden='true')
        .mt-3.space-y-1.px-2
          DisclosureButton.block.rounded-md.px-3.py-2.text-base.font-medium.text-gray-400(v-for='item in userNavigation' :key='item.name' as='a' :href='item.href' class='hover:bg-gray-700 hover:text-white') {{ item.name }}
  header.bg-white.shadow
    .mx-auto.max-w-7xl.py-6.px-4(class='sm:px-6 lg:px-8')
      h1.text-3xl.font-bold.tracking-tight.text-gray-900 Dashboard
  main
    .mx-auto.max-w-7xl.py-6(class='sm:px-6 lg:px-8')
      // Replace with your content
      router-view
      .px-4.py-6(class='sm:px-0')
        .h-96.rounded-lg.border-4.border-dashed.border-gray-200

        // /End replace

</template>

<script lang="coffee">
import { ref } from 'vue'
import { Disclosure, DisclosureButton, DisclosurePanel, Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'
import { Bars3Icon, BellIcon, XMarkIcon } from '@heroicons/vue/24/outline'


export default
  name: 'App',
  components: {
    Bars3Icon,
    BellIcon,
    Disclosure,
    DisclosureButton,
    DisclosurePanel,
    Menu,
    MenuButton,
    MenuItem,
    MenuItems,
    XMarkIcon,
  }
  computed:
    pageTitle: ->
      @$route.meta
      "PageTitle - #{@$route.meta.name}"
  mounted: ->
    person = {
      first_name: ""
      last_name: ""
      middle_names: ["", "", ""]
      hex: 0xffffffff
      pronoun: ""
    }
    colors_to_make = {
      gray: {
        100: "rgb(243, 244, 246)"
        200: "rgb(229, 231, 235)"
        300: "rgb(209, 213, 219)"
        400: "rgb(156, 163, 175)"
        500: "rgb(107, 114, 128)"
        600: "rgb(75, 85, 99)"
        700: "rgb(55, 65, 81)"
        800: "rgb(31, 41, 55)"
        900: "rgb(17, 24, 39)"
      }
    }
    color_prefix_templates = [
      { name: "text", selector: "", style: "color: " }
      { name: "bg", selector: "", style: "background-color: " }
      { name: "border", selector: "", style: "border-color: " }
    ]
    colors = []
    for template in color_prefix_templates
      for color, shades of colors_to_make
        for level, code of shades
          colors.push (["." + template.name, color, level].join "-") + " {"
          colors.push "  " + template.style + code
          colors.push "}"

    @color_css = colors.join "\n"
    #console.log "color_css is"
    #console.log @color_css
    @$store.dispatch 'load_db'
    @$store.dispatch 'set_page_title', "App"
  data: ->
    return
      color_css: ""
      user:
        name: 'Tom Cook',
        email: 'tom@example.com',
        imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80'
      navigation: [
        { name: 'Home', href: '#', current: true },
        { name: 'Domains', href: '/domains', current: false },
        { name: 'DataViewDemo', href: '/dataviewdemo', current: false },
        { name: 'Admin', href: '/admin', current: false },
        { name: 'About', href: '/about', current: false },
      ]
</script>
<style>
input, select, textarea {
  padding: 15px 32px;
  background-color: powderblue;
  margin: 5px;
}
button {
  background-color: darkseagreen;
  margin: 5px;
  border: none;
  color: white;
  padding: 15px 32px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  font-size: 16px;

}
.label {
  padding: 15px 32px;
  margin: 5px;
  background-color: tan;
  display: inline;
}
/*
a {
  background-color: thistle;
}
*/
</style>
