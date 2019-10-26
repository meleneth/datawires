import { expect } from 'chai'
import { shallowMount } from '@vue/test-utils'
import HelloWorld from '@/components/HelloWorld.vue'

describe 'HelloWorld.vue', =>
  it 'renders props.msg when passed', =>
    msg = 'new message'
    wrapper = shallowMount HelloWorld,
      propsData: { msg }
    expect(wrapper.text()).to.include(msg)
  it 'hurting me', =>
    msg = 'new message'
    wrapper = shallowMount HelloWorld,
      propsData: { msg }
    expect(wrapper.text()).to.include(msg)
