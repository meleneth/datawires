import { expect } from 'chai'

import Builder from '@/components/DataView/builder'
import { GridBuilder } from '@/components/DataView/builder'

describe 'GridBuilder', =>
  describe "_update_styles", =>
    it "works for simple case", =>
      my_grid = new GridBuilder 3, 3
      my_grid.add_cell 'one'
        .set_grid 0,0
        .set_grid 1,0
        .cell()
        .add_text "some_text"
      my_grid.add_cell 'two'
        .set_grid 2,0
        .set_grid 2,1
        .cell()
        .add_text "some_other_text"

      data = my_grid.data
      expect(data.style['display']).to.eql 'grid'
      expect(data.style['grid-template-columns']).to.eql '1fr 1fr 1fr'
      expect(data.style['grid-template-rows']).to.eql '1fr 1fr 1fr'
      expect(data.style['grid-template-areas']).to.eql '''"one one two" "unset unset two" "unset unset unset"'''

  it 'works for simple case', =>
    my_grid = new GridBuilder 3, 3
    my_grid.add_cell 'one'
      .set_grid 0,0
      .set_grid 1,0
      .cell()
      .add_text "some_text"
    my_grid.add_cell 'two'
      .set_grid 2,0
      .set_grid 2,1
      .cell()
      .add_text "some_other_text"

    expect(my_grid.gridcells[0][0]).to.eql 'one'
    expect(my_grid.gridcells[0][1]).to.eql 'one'
    expect(my_grid.gridcells[0][2]).to.eql 'two'
    expect(my_grid.gridcells[1][2]).to.eql 'two'

    expect(my_grid.data).to.eql
      type: 'div'
      style:
        display: 'grid'
        'grid-template-areas': '"one one two" "unset unset two" "unset unset unset"'
        "grid-template-columns": "1fr 1fr 1fr"
        "grid-template-rows": "1fr 1fr 1fr"
      children: [
        type: 'div'
        style: {'grid-area': 'one'}
        classes: {}
        children: [
          type: 'text'
          style: {}
          classes: {}
          text: 'some_text'
        ]
      ,
        type: 'div'
        style: {'grid-area': 'two'}
        classes: {}
        children: [
          type: 'text'
          style: {}
          classes: {}
          text: 'some_other_text'
        ]
      ]
