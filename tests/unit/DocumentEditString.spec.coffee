import { mount, createLocalVue } from '@vue/test-utils'
import { expect } from 'chai'
import Vuetify from 'vuetify'

import { shallowMount } from '@vue/test-utils'
import DocumentEditString from '@/components/DocumentEdit/StringEdit.vue'

global.requestAnimationFrame = () -> {}

describe 'DocumentEdit/StringEdit.vue', =>
  beforeEach () =>
  it 'shows title', =>
#    localVue = createLocalVue()
#    vuetify = new Vuetify
#      mocks:
#        $vuetify:
#          lang:
#            t: (val) => val
#    title =  "a name with a value"
#    path = "/name"
#    current = 'foo'
#    property =
#      "enum": ['foo', 'bar', 'baz']
#    wrapper = mount DocumentEditString, {
#      localVue
#      vuetify
#      attachToDocument: true
#      propsData:
#        field: {
#          current
#          title
#          path
#          property
#        }
#    }
#    expect(wrapper.text()).to.include "a name with a value"
