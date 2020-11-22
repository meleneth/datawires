import { expect } from 'chai'

import Builder from '@/components/DataView/builder'

describe 'DataViewBuilder', =>
  it 'works for simple case', =>
    builder = new Builder 'container'
    expect(builder.data).to.eql
      type: 'container'
      children: []
  
  describe "#add_container", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_container()
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'container'
          children: []
        }]

  describe "#add_row", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_row()
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'row'
          children: []
        }]

  describe "#add_col", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_col()
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'col'
          children: []
        }]

  describe "#add_button", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      action = ->
      builder.add_button 'add', action
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'button'
          label: 'add'
          target: action
        }]

  describe "#add_card", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_card()
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'card'
          children: []
        }]

  describe "#add_sheet", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_sheet()
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'sheet'
          children: []
        }]

  describe "#add_p", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_p()
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'p'
          children: []
        }]

  describe "#add_text", =>
    it 'works for simple case', =>
      builder = new Builder 'container'
      builder.add_text('some_text')
      expect(builder.data).to.eql
        type: 'container'
        children: [{
          type: 'text'
          text: 'some_text'
        }]
        type: 'container'

  describe "chainability", =>
    it 'works in a simple case', =>
      builder = new Builder 'container'
      builder.add_row().add_col()
      expect(builder.data).to.eql
        type: 'container'
        children: [ {
          type: 'row'
          children: [ {
            type: 'col'
            children: [ ]
          } ]
        } ]
      
