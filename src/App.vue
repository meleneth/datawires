<template lang="pug">
component(is="style")
  | {{ color_css }}
div
  Disclosure(as="nav" class="bg-gray-800" v-slot="{ open }")
    div(class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8")
      div(class="flex items-center justify-between h-16")
        div(class="flex items-center")
          div(class="flex-shrink-0")
            img(class="h-8 w-8" src="public_datawires_logo_3.svg" alt="Datawires")
          div(class="hidden md:block")
            div(class="ml-10 flex items-baseline space-x-4")
              router-link(v-for="link in navLinks" :key="link.title" :to="link.to" :class="[link.active ? 'text-white' : 'text-indigo', 'text-sm font-medium rounded-md bg-white bg-opacity-0 px-3 py-2 hover:bg-opacity-10']" :aria-current="link.active ? 'page' : 'false'") {{ link.title }}
        div(class="hidden md:block")
          div(class="ml-4 flex items-center md:ml-6")
            button(class="bg-gray-800 p-1 rounded-full text-gray-400 hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-white")
              span(class="sr-only") View notifications
              BellIcon(class="h-6 w-6" aria-hidden="true")
            Menu(as="div" class="ml-3 relative")
              div
                MenuButton(class="max-w-xs bg-gray-800 rounded-full flex items-center text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-white")
                  span(class="sr-only") Open user menu
                  img(class="h-8 w-8 rounded-full" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="")
                transition(enter-active-class="transition ease-out duration-100" enter-from-class="transform opacity-0 scale-95" enter-to-class="transform opacity-100 scale-100" leave-active-class="transition ease-in duration-75" leave-from-class="transform opacity-100 scale-100" leave-to-class="transform opacity-0 scale-95")
                  MenuItems(class="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none")
                    MenuItem(v-for="item in profile" :key="item" v-slot="{ active }")
                      a(href="#" :class="[active ? 'bg-gray-100' : '', 'block px-4 py-2 text-sm text-gray-700']") {{ item }} 
        div(class="-mr-2 flex md:hidden")
          DisclosureButton(class="bg-gray-800 inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-white")
            span(class="sr-only") Open main menu
            MenuIcon(v-if="!open" class="block h-6 w-6" aria-hidden="true")
            XIcon(v-else class="block h-6 w-6" aria-hidden="true")
    DisclosurePanel(class="md:hidden")
      div(class="px-2 pt-2 pb-3 space-y-1 sm:px-3")
        template(v-for="(item, itemIdx) in navigation" :key="item")
          template(v-if="(itemIdx === 0)")
            a(href="#" class="bg-gray-900 text-white block px-3 py-2 rounded-md text-base font-medium") {{ item }}
          a(v-else href="#" class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium") {{ item }}
      div(class="pt-4 pb-3 border-t border-gray-700")
        div(class="flex items-center px-5")
          div(class="flex-shrink-0")
            img(class="h-10 w-10 rounded-full" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="")
          div(class="ml-3")
            div(class="text-base font-medium leading-none text-white") Tom Cook
            div(class="text-sm font-medium leading-none text-gray-400") tom@example.com
          button(class="ml-auto bg-gray-800 flex-shrink-0 p-1 rounded-full text-gray-400 hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-white")
            span(class="sr-only") View notifications
            BellIcon(class="h-6 w-6" aria-hidden="true")
        div(class="mt-3 px-2 space-y-1")
          a(v-for="item in profile" :key="item" href="#" class="block px-3 py-2 rounded-md text-base font-medium text-gray-400 hover:text-white hover:bg-gray-700") {{ item }}

  header(class="bg-white shadow")
    div(class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8")
      h1(class="text-3xl font-bold text-gray-900")
        | {{ pageTitle }}
  main
    div(class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8")
      div(class="px-4 py-6 sm:px-0")
        router-view

div(class="min-h-screen bg-grey-darkest")
  header(class="pb-24 bg-indigo-light")
    div(class="max-w-3xl mx-auto px-4 sm:px-6 lg:max-w-7xl lg:px-8")
      div(class="relative py-5 flex items-center justify-center lg:justify-between")
        p(class="sr-only") |)atawires
    div
      nav
        router-link(v-for="link in navLinks" :key="link.title" :to="link.to" :class="[link.active ? 'text-white' : 'text-indigo', 'text-sm font-medium rounded-md bg-white bg-opacity-0 px-3 py-2 hover:bg-opacity-10']" :aria-current="link.active ? 'page' : 'false'")
</template>

<script lang="coffee">
import { ref } from 'vue'
import { Disclosure, DisclosureButton, DisclosurePanel, Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'
import { BellIcon, MenuIcon, XIcon } from '@heroicons/vue/outline'

navLinks = [
  { title: 'Home', to: "/", active: true },
  { title: 'Domains', to: "/domains", active: false },
  { title: 'DataViewDemo', to: "/dataviewdemo", active: false },
  { title: 'Import', to: "/import", active: false },
  { title: 'Admin', to: "/admin", active: false },
  { title: 'About', to: "/about", active: false },
]

export default
  name: 'App',
  components: {
    Disclosure,
    DisclosureButton,
    DisclosurePanel,
    Menu,
    MenuButton,
    MenuItem,
    MenuItems,
    BellIcon,
    MenuIcon,
    XIcon,
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
    console.log "color_css is"
    console.log @color_css
    @$store.dispatch 'load_db'
  data: ->
    return
      navLinks: navLinks
      color_css: ""
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
</style>
