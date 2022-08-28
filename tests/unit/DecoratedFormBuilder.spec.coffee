import { expect } from 'chai'

import DecoratedFormBuilder from '@/lib/decorated/form.coffee'

# garbage, can't test until the test suite is runnable

describe 'DataViewBuilder', =>
  it 'works for simple case', =>
    builder = new Builder 'container'
    expect(builder.data).to.eql
      type: 'container'
      style: {}
      children: []

  describe "#add_button", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      action = ->
      builder.add_button 'add', action
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        children: [{
          type: 'button'
          style: {}
          label: 'add'
          target: action
        }]

  describe "#add_card", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_card()
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        children: [{
          type: 'card'
          style: {}
          children: []
        }]

  describe "#add_form", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_form()
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        children: [{
          type: 'form'
          style: {}
          children: []
        }]

    it 'allows adding input tags', =>
      builder = new Builder 'container'
      some_object = {first_name: "Jason"}
      form = builder.add_form()
      form.add_input 'First Name', some_object, 'first_name' #might be a ref?
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        children: [{
          type: 'form'
          style: {}
          children: [{
            type: 'input'
            label: 'First Name'
            target:
              first_name: 'Jason'
            field: 'first_name'
            style: {}
            children: []
          }]
        }]

  describe "#add_p", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_p()
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        children: [{
          type: 'p'
          style: {}
          children: []
        }]

  describe "#add_text", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_text 'some_text'
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        children: [{
          type: 'text'
          style: {}
          text: 'some_text'
        }]

  describe "chainability", =>
    it 'works in a simple case', =>
      builder = new Builder 'container'
      builder.add_p().add_p()
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        children: [ {
          type: 'p'
          style: {}
          children: [ {
            type: 'p'
            style: {}
            children: [ ]
          } ]
        } ]
