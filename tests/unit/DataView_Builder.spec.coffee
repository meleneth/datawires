import { expect } from 'chai'

import Builder from '@/components/DataView/builder'

describe 'DataViewBuilder', =>
  it 'works for simple case', =>
    builder = new Builder 'container'
    expect(builder.data).to.eql
      type: 'container'
      style: {}
      classes: {}
      children: []

  describe "#add_button", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      action = ->
      builder.add_button 'add', action
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        classes: {}
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
        classes: {}
        children: [{
          type: 'card'
          style: {}
          classes: {}
          children: []
        }]

  describe "#add_form", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_form()
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        classes: {}
        children: [{
          type: 'form'
          style: {}
          classes: {}
          children: []
        }]

    it 'allows adding input tags', =>
      builder = new Builder 'container'
      some_object = {first_name: "Jason"}
      form = builder.add_form()
      input = form.add_input some_object, 'first_name' #might be a ref?
      input.set_id "an ID of great importance"
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        classes: {}
        children: [{
          type: 'form'
          style: {}
          classes: {}
          children: [{
            type: 'input'
            input_type: 'text'
            target:
              first_name: 'Jason'
            id: "an ID of great importance"
            field: 'first_name'
            style: {}
            classes: {}
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
        classes: {}
        children: [{
          type: 'p'
          style: {}
          classes: {}
          children: []
        }]

  describe "#add_text", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_text 'some_text'
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        classes: {}
        children: [{
          type: 'text'
          style: {}
          classes: {}
          text: 'some_text'
        }]

  describe "chainability", =>
    it 'works in a simple case', =>
      builder = new Builder 'container'
      builder.add_p().add_p()
      expect(builder.data).to.eql
        type: 'container'
        style: {}
        classes: {}
        children: [ {
          type: 'p'
          style: {}
          classes: {}
          children: [ {
            type: 'p'
            style: {}
            classes: {}
            children: [ ]
          } ]
        } ]
      
