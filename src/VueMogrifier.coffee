_meld_value = (doc, name, value) ->
  shortname = name.substring(1)
  if name[0] == "_"
    doc[shortname] = value
    return
  if name[0] == "$"
    if not doc['attributes']
      doc.attributes = {}
    doc.attributes[shortname] = value
    return
  doc.doc[name] = value

export default
  vue2couch: (doc) ->
    doc = JSON.parse(JSON.stringify(doc))

    newdoc = {_id: doc.id, _rev: doc.rev}

    delete doc.id
    delete doc.rev
    
    if doc.attributes
      for name, value of doc.attributes
        newdoc["$#{name}"] = value
      delete doc.attributes
    for name, value of doc.doc
      newdoc[name] = value
    return newdoc
    
  couch2vue: (doc) ->
    newdoc = {doc: {}}

    for name, value of doc
      _meld_value newdoc, name, value
    return newdoc
