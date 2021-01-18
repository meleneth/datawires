map_task = (items, make_req, map_promise, complete_promise) =>
  process_it = (item, result) =>
    map_promise item, result
    process_next()
  process_next = () =>
    item = items.pop()
    if item
      req = make_req item
      success = process_it.bind @, item
      fail = process_next
      req.then success, fail
    else
      complete_promise()
  process_next()

export default map_task

