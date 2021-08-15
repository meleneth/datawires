import { expect } from 'chai'

import Builder from '@/components/DataView/builder'
import { GridBuilder } from '@/components/DataView/builder'

describe 'GridBuilder', =>
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
      type: 'grid'
      style: {'display': 'grid'}
      children: [
        type: 'div'
        style: {}
        children: [
          type: 'text'
          style: {}
          text: 'some_text'
        ]
      ,
        type: 'div'
        style: {}
        children: [
          type: 'text'
          style: {}
          text: 'some_other_text'
        ]
      ]
